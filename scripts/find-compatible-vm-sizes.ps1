#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Find compatible VM sizes for Azure regions
    
.DESCRIPTION
    This script finds compatible VM sizes for Azure AKS clusters, focusing on Standard_D2, Standard_D4 variants and similar options.
    It checks both regional availability and quota limits to recommend suitable VM SKUs.
    
.PARAMETER Region
    Azure region name (e.g., eastus, westus2, swedencentral)
    
.PARAMETER Subscription
    Azure subscription ID (optional, uses current if not specified)
    
.PARAMETER NodeCount
    Number of nodes to deploy in AKS cluster (default: 3)
    
.PARAMETER MinTotalVCpus
    Minimum total vCPUs needed for cluster (optional, calculated from NodeCount if not specified)
    
.PARAMETER Limit
    Maximum number of results to show (default: 5)
    
.PARAMETER Quiet
    Quiet mode - only output SKU names of matches
    
.EXAMPLE
    .\find-compatible-vm-sizes.ps1 -Region eastus2
    Find compatible VM sizes for eastus2 region with 3 nodes
    
.EXAMPLE
    .\find-compatible-vm-sizes.ps1 -Region swedencentral -NodeCount 5
    Find compatible VM sizes for swedencentral region with 5 nodes
    
.EXAMPLE
    .\find-compatible-vm-sizes.ps1 -Region eastus2 -NodeCount 3 -MinTotalVCpus 12 -Limit 3
    Find compatible VM sizes with specific requirements
    
.EXAMPLE
    .\find-compatible-vm-sizes.ps1 -Region eastus2 -Quiet
    Output only SKU names in quiet mode
    
.NOTES
    Requires Azure CLI to be installed and authenticated (run 'az login' first)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Region,
    
    [string]$Subscription = "",
    
    [int]$NodeCount = 3,
    
    [int]$MinTotalVCpus = 0,
    
    [int]$Limit = 5,
    
    [switch]$Quiet
)

# Function to print only if not in quiet mode
function Write-IfNotQuiet {
    param([string]$Message)
    if (-not $Quiet) {
        Write-Host $Message
    }
}

# Show help if requested
if ($Help) {
    Show-Usage
    exit 0
}

# Validate required parameters
if ([string]::IsNullOrEmpty($Region)) {
    Write-Host "Error: Region is required" -ForegroundColor Red
    Show-Usage
    exit 1
}

# Set subscription if provided
if (-not [string]::IsNullOrEmpty($Subscription)) {
    Write-IfNotQuiet "Setting subscription to: $Subscription"
    az account set --subscription $Subscription
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error: Failed to set subscription" -ForegroundColor Red
        exit 1
    }
}

# Get current subscription info
try {
    $currentSub = az account show --query "id" -o tsv 2>$null
    $subName = az account show --query "name" -o tsv 2>$null
    
    if ([string]::IsNullOrEmpty($currentSub)) {
        if (-not $Quiet) {
            Write-Host "Error: Not logged in to Azure CLI. Please run 'az login' first." -ForegroundColor Red
        }
        exit 1
    }
} catch {
    if (-not $Quiet) {
        Write-Host "Error: Not logged in to Azure CLI. Please run 'az login' first." -ForegroundColor Red
    }
    exit 1
}

Write-IfNotQuiet "Current subscription: $subName ($currentSub)"
Write-IfNotQuiet "Checking VM sizes for region: $Region"
Write-IfNotQuiet "Planned AKS cluster: $NodeCount nodes"

# Calculate minimum total vCPUs if not specified
if ($MinTotalVCpus -eq 0) {
    $MinTotalVCpus = $NodeCount * 2  # Default to 2 vCPUs per node minimum as baseline
    Write-IfNotQuiet "Minimum total vCPUs for cluster: $MinTotalVCpus (baseline: $NodeCount nodes × 2 vCPUs minimum)"
    Write-IfNotQuiet "Note: Actual vCPU requirements will be calculated based on each VM SKU"
} else {
    Write-IfNotQuiet "Minimum total vCPUs for cluster: $MinTotalVCpus (user-specified)"
}
Write-IfNotQuiet ""

# Preferred VM sizes in order of preference
$PreferredSizes = @(
    "Standard_D2s_v5",
    "Standard_D2_v5",
    "Standard_D2s_v4",
    "Standard_D2_v4",
    "Standard_D2s_v3",
    "Standard_D2_v3",
    "Standard_D4s_v5",
    "Standard_D4_v5",
    "Standard_D4s_v4",
    "Standard_D4_v4",
    "Standard_D4s_v3",
    "Standard_D4_v3",
    "Standard_B2s",
    "Standard_B2ms",
    "Standard_B4ms",
    "Standard_DS2_v2",
    "Standard_DS3_v2",
    "Standard_DS4_v2"
)

# Function to check if a VM size is available in the region
function Test-VmSize {
    param([string]$VmSize)
    try {
        $result = az vm list-sizes --location $Region --query "[?name=='$VmSize']" -o tsv 2>$null
        return -not [string]::IsNullOrEmpty($result)
    } catch {
        return $false
    }
}

# Function to get VM size details
function Get-VmDetails {
    param([string]$VmSize)
    try {
        az vm list-sizes --location $Region --query "[?name=='$VmSize'].{Name:name,Cores:numberOfCores,RAM:memoryInMB,MaxDataDisks:maxDataDiskCount}" -o table 2>$null
    } catch {
        Write-Host "Error getting VM details for $VmSize" -ForegroundColor Red
    }
}

# Function to map VM SKU to the correct quota family name
function Get-VmQuotaFamily {
    param([string]$VmSize)
    
    switch -Regex ($VmSize) {
        "^Standard_D.*s_v5$" { return "standardDSv5Family" }
        "^Standard_D.*_v5$" { return "standardDv5Family" }
        "^Standard_D.*s_v4$" { return "standardDSv4Family" }
        "^Standard_D.*_v4$" { return "standardDv4Family" }
        "^Standard_D.*s_v3$" { return "standardDSv3Family" }
        "^Standard_D.*_v3$" { return "standardDv3Family" }
        "^Standard_D.*s_v2$" { return "standardDSv2Family" }
        "^Standard_D.*_v2$" { return "standardDv2Family" }
        "^Standard_B.*s$" { return "standardBSv2Family" }
        "^Standard_B.*$" { return "standardBsFamily" }
        default { return "" }
    }
}

# Function to check quota for a VM size
function Test-QuotaForVm {
    param([string]$VmSize)
    
    try {
        $vmCores = [int](az vm list-sizes --location $Region --query "[?name=='$VmSize'].numberOfCores" -o tsv 2>$null)
        if ($vmCores -eq 0) { return $false }
        
        $totalCoresNeeded = $vmCores * $NodeCount
        
        # Only check if cluster meets minimum if MinTotalVCpus was user-specified
        if ($MinTotalVCpus -ne ($NodeCount * 2) -and $totalCoresNeeded -lt $MinTotalVCpus) {
            if (-not $Quiet) {
                Write-Host "  ⚠ Cluster would have only $totalCoresNeeded vCPUs ($NodeCount×$vmCores), need at least $MinTotalVCpus" -ForegroundColor Yellow
            }
            return $false
        }
        
        # Get current core usage and limits
        $coreUsage = az vm list-usage --location $Region --query "[?contains(name.value, 'cores')].{current:currentValue,limit:limit}" -o tsv 2>$null
        
        if (-not [string]::IsNullOrEmpty($coreUsage)) {
            $usage = $coreUsage.Split("`t")
            $currentCores = [int]$usage[0]
            $maxCores = [int]$usage[1]
            $availableCores = $maxCores - $currentCores
            
            if ($totalCoresNeeded -le $availableCores) {
                if (-not $Quiet) {
                    Write-Host "  ✓ Quota OK: $totalCoresNeeded vCPUs needed ($NodeCount×$vmCores), $availableCores available" -ForegroundColor Green
                }
                return $true
            } else {
                if (-not $Quiet) {
                    Write-Host "  ✗ Quota insufficient: $totalCoresNeeded vCPUs needed ($NodeCount×$vmCores), only $availableCores available" -ForegroundColor Red
                }
                return $false
            }
        } else {
            if (-not $Quiet) {
                Write-Host "  ? Unable to determine quota status" -ForegroundColor Yellow
            }
            return $false
        }
    } catch {
        return $false
    }
}

# Function to check VM family specific quota
function Test-VmFamilyQuota {
    param([string]$VmSize)
    
    try {
        $vmCores = [int](az vm list-sizes --location $Region --query "[?name=='$VmSize'].numberOfCores" -o tsv 2>$null)
        $totalCoresNeeded = $vmCores * $NodeCount
        
        # Only check if cluster meets minimum if MinTotalVCpus was user-specified
        if ($MinTotalVCpus -ne ($NodeCount * 2) -and $totalCoresNeeded -lt $MinTotalVCpus) {
            return $false
        }
        
        # Get the correct quota family name
        $familyName = Get-VmQuotaFamily $VmSize
        
        if (-not [string]::IsNullOrEmpty($familyName)) {
            $familyQuota = az vm list-usage --location $Region --query "[?name.value=='$familyName'].{current:currentValue,limit:limit}" -o tsv 2>$null | Select-Object -First 1
            
            if (-not [string]::IsNullOrEmpty($familyQuota)) {
                $quota = $familyQuota.Split("`t")
                $currentFamily = [int]$quota[0]
                $maxFamily = [int]$quota[1]
                $availableFamily = $maxFamily - $currentFamily
                
                if ($totalCoresNeeded -le $availableFamily) {
                    if (-not $Quiet) {
                        Write-Host "  ✓ Family quota OK: $totalCoresNeeded vCPUs needed ($NodeCount×$vmCores) in $familyName" -ForegroundColor Green
                    }
                    return $true
                } else {
                    if (-not $Quiet) {
                        Write-Host "  ✗ Family quota insufficient: $totalCoresNeeded vCPUs needed ($NodeCount×$vmCores), only $availableFamily available in $familyName" -ForegroundColor Red
                    }
                    return $false
                }
            } else {
                if (-not $Quiet) {
                    Write-Host "  ? Unable to find quota for family: $familyName" -ForegroundColor Yellow
                }
                return $false
            }
        } else {
            if (-not $Quiet) {
                Write-Host "  ? Unknown VM family for quota lookup: $VmSize" -ForegroundColor Yellow
            }
            return $false
        }
    } catch {
        return $false
    }
}

Write-IfNotQuiet "Checking preferred VM sizes..."
Write-IfNotQuiet ""

$AvailableSizes = @()
$UnavailableSizes = @()
$QuotaOkSizes = @()
$QuotaInsufficientSizes = @()
$InsufficientTotalVcpuSizes = @()

# Check each preferred size
foreach ($size in $PreferredSizes) {
    Write-IfNotQuiet "Checking $size..."
    
    if (Test-VmSize $size) {
        # Get VM cores to calculate cluster total
        $vmCores = [int](az vm list-sizes --location $Region --query "[?name=='$size'].numberOfCores" -o tsv 2>$null)
        $totalClusterVcpus = $vmCores * $NodeCount
        
        # Only check minimum requirement if user specified a custom minimum
        $meetsMinimum = $true
        if ($MinTotalVCpus -ne ($NodeCount * 2) -and $totalClusterVcpus -lt $MinTotalVCpus) {
            $meetsMinimum = $false
        }
        
        if ($meetsMinimum) {
            $AvailableSizes += $size
            Write-IfNotQuiet "  ✓ Available in region ($vmCores vCPUs × $NodeCount nodes = $totalClusterVcpus total vCPUs)"
            
            # Check quota (suppress output in quiet mode)
            $quotaOk = $false
            if ($Quiet) {
                $quotaOk = (Test-QuotaForVm $size) -and (Test-VmFamilyQuota $size)
            } else {
                $quotaOk = (Test-QuotaForVm $size) -and (Test-VmFamilyQuota $size)
            }
            
            if ($quotaOk) {
                $QuotaOkSizes += $size
            } else {
                $QuotaInsufficientSizes += $size
            }
        } else {
            $InsufficientTotalVcpuSizes += $size
            Write-IfNotQuiet "  ⚠ Available but insufficient total vCPUs ($totalClusterVcpus < $MinTotalVCpus required)"
        }
    } else {
        $UnavailableSizes += $size
        Write-IfNotQuiet "  ✗ Not available in region"
    }
    Write-IfNotQuiet ""
}

Write-IfNotQuiet ""

if ($QuotaOkSizes.Count -eq 0) {
    Write-IfNotQuiet "❌ No preferred VM sizes can provide sufficient quota for $NodeCount-node cluster in region $Region"
    
    if ($AvailableSizes.Count -gt 0) {
        Write-IfNotQuiet "VM sizes available in region but with insufficient quota for $NodeCount nodes:"
        if (-not $Quiet) {
            foreach ($size in $AvailableSizes) {
                $vmCores = [int](az vm list-sizes --location $Region --query "[?name=='$size'].numberOfCores" -o tsv 2>$null)
                $totalCores = $vmCores * $NodeCount
                Write-Host "  - $size ($vmCores vCPUs × $NodeCount = $totalCores total vCPUs)" -ForegroundColor Yellow
            }
            Write-Host ""
            Write-Host "💡 You may need to request quota increase" -ForegroundColor Blue
        }
    }
} else {
    # Sort the available VMs by vCPU count (lowest first)
    $SortedQuotaOkSizes = @()
    foreach ($size in $QuotaOkSizes) {
        $vmCores = [int](az vm list-sizes --location $Region --query "[?name=='$size'].numberOfCores" -o tsv 2>$null)
        $SortedQuotaOkSizes += [PSCustomObject]@{
            Name = $size
            Cores = $vmCores
        }
    }
    $SortedQuotaOkSizes = $SortedQuotaOkSizes | Sort-Object Cores | Select-Object -ExpandProperty Name
    
    if ($Quiet) {
        # Quiet mode: only output SKU names, limited by Limit
        $count = 0
        foreach ($size in $SortedQuotaOkSizes) {
            if ($count -lt $Limit) {
                Write-Output $size
                $count++
            }
        }
    } else {
        # Normal mode: full output
        Write-Host "✅ VM sizes with sufficient quota for $NodeCount-node cluster (ordered by lowest resources):" -ForegroundColor Green
        Write-Host ""
        
        # Show details for limited number of results
        $count = 0
        foreach ($size in $SortedQuotaOkSizes) {
            if ($count -lt $Limit) {
                $vmCores = [int](az vm list-sizes --location $Region --query "[?name=='$size'].numberOfCores" -o tsv 2>$null)
                $totalCores = $vmCores * $NodeCount
                Write-Host "$($count + 1). $size" -ForegroundColor Green
                Write-Host "   Per VM: $vmCores vCPUs"
                Write-Host "   Total cluster: $totalCores vCPUs ($NodeCount nodes)"
                Get-VmDetails $size
                Write-Host ""
                $count++
            }
        }
        
        # Show the top recommendation
        $topChoice = $SortedQuotaOkSizes[0]
        $vmCores = [int](az vm list-sizes --location $Region --query "[?name=='$topChoice'].numberOfCores" -o tsv 2>$null)
        $totalCores = $vmCores * $NodeCount
        Write-Host "🎯 TOP RECOMMENDATION (Most Cost-Effective): $topChoice" -ForegroundColor Green
        Write-Host "   Cluster configuration: $NodeCount nodes × $vmCores vCPUs = $totalCores total vCPUs" -ForegroundColor Blue
        
        # Show if there are more results than displayed
        if ($SortedQuotaOkSizes.Count -gt $Limit) {
            $additional = $SortedQuotaOkSizes.Count - $Limit
            Write-Host "   Note: $additional additional VM sizes available. Use -Limit to show more results." -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Host "To use this VM size in your deployment, set:"
        Write-Host "azd env set AKS_NODE_POOL_VM_SIZE $topChoice" -ForegroundColor Blue
    }
}

Write-IfNotQuiet ""
Write-IfNotQuiet "Region and quota check complete for: $Region"

# Show summary of all checks
Write-IfNotQuiet ""
if ($MinTotalVCpus -ne ($NodeCount * 2)) {
    Write-IfNotQuiet "📋 Summary for $NodeCount-node AKS cluster (≥$MinTotalVCpus total vCPUs required):"
    Write-IfNotQuiet "✓ Available with quota (≥$MinTotalVCpus total vCPUs): $($QuotaOkSizes.Count)"
    Write-IfNotQuiet "- Available but insufficient quota: $($QuotaInsufficientSizes.Count)"
    Write-IfNotQuiet "⚠ Available but insufficient total vCPUs: $($InsufficientTotalVcpuSizes.Count)"
    Write-IfNotQuiet "✗ Not available in region: $($UnavailableSizes.Count)"
} else {
    Write-IfNotQuiet "📋 Summary for $NodeCount-node AKS cluster (evaluating all VM SKUs):"
    Write-IfNotQuiet "✓ Available with quota: $($QuotaOkSizes.Count)"
    Write-IfNotQuiet "- Available but insufficient quota: $($QuotaInsufficientSizes.Count)"
    Write-IfNotQuiet "✗ Not available in region: $($UnavailableSizes.Count)"
}

# Optional: Show quota increase guidance
if ($QuotaInsufficientSizes.Count -gt 0 -or $QuotaOkSizes.Count -eq 0) {
    Write-IfNotQuiet ""
    Write-IfNotQuiet "💡 To request quota increase:"
    Write-IfNotQuiet "1. Go to Azure Portal > Subscriptions > Usage + quotas"
    Write-IfNotQuiet "2. Filter by region: $Region"
    Write-IfNotQuiet "3. Search for 'vCPUs' quotas"
    Write-IfNotQuiet "4. Request increase for needed VM families"
}
