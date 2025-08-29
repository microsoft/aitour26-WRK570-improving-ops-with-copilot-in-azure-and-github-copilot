#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Identify availability zones for VM SKUs in a given Azure region
    
.DESCRIPTION
    This script identifies availability zones for VM SKUs in a given Azure region.
    Can be used standalone or with pipeline input from find-compatible-vm-sizes.ps1.
    
.PARAMETER Quiet
    Quiet mode - output JSON with SKU name and zone arrays
    
.PARAMETER Region
    Azure region name (e.g., eastus, westus2, centralus)
    
.PARAMETER Subscription
    Azure subscription ID (optional, uses current if not specified)
    
.PARAMETER VmSku
    Azure VM SKU name (e.g., Standard_D2s_v5, Standard_B2ms)
    Can be provided as parameter or via pipeline input
    
.EXAMPLE
    .\get-availability-zones.ps1 -Region eastus -VmSku Standard_D2s_v5
    Get availability zones for a single SKU with verbose output
    
.EXAMPLE
    .\get-availability-zones.ps1 -Quiet -Region eastus -VmSku Standard_D2s_v5
    Get availability zones for a single SKU with JSON output
    
.EXAMPLE
    'Standard_D2s_v5' | .\get-availability-zones.ps1 -Quiet -Region eastus
    Pipeline input with JSON output
    
.EXAMPLE
    .\find-compatible-vm-sizes.ps1 -Region eastus2 -Quiet | .\get-availability-zones.ps1 -Quiet -Region eastus2
    Pipeline from find-compatible-vm-sizes script
    
.NOTES
    Requires Azure CLI to be installed and authenticated (run 'az login' first)
#>

param(
    [switch]$Quiet,
    
    [Parameter(Mandatory=$true)]
    [string]$Region,
    
    [string]$Subscription = "",
    
    [Parameter(ValueFromPipeline=$true)]
    [string]$VmSku = ""
)

begin {
    # Function to check if Azure CLI is installed and user is logged in
    function Test-Prerequisites {
        # Check if az CLI is installed
        if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
            if (-not $Quiet) {
                Write-Host "Error: Azure CLI is not installed or not in PATH." -ForegroundColor Red
                Write-Host "Please install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
            }
            exit 1
        }

        # Check if user is logged in
        try {
            $null = az account show 2>$null
        } catch {
            if (-not $Quiet) {
                Write-Host "Error: You are not logged in to Azure CLI." -ForegroundColor Red
                Write-Host "Please run 'az login' to authenticate."
            }
            exit 1
        }
    }

    # Function to validate VM SKU
    function Test-VmSku {
        param([string]$VmSkuName, [string]$RegionName)
        
        if (-not $Quiet) {
            Write-Host "Validating VM SKU: $VmSkuName in region: $RegionName"
        }
        
        try {
            $result = az vm list-skus --location $RegionName --query "[?name=='$VmSkuName']" -o tsv 2>$null
            if ([string]::IsNullOrEmpty($result)) {
                if (-not $Quiet) {
                    Write-Host "Error: VM SKU '$VmSkuName' is not available in region '$RegionName'." -ForegroundColor Red
                    Write-Host ""
                    Write-Host "Available VM SKUs in $RegionName (showing first 10):"
                    $availableSkus = az vm list-skus --location $RegionName --query "[?resourceType=='virtualMachines'].name" -o tsv 2>$null | Sort-Object | Select-Object -First 10
                    foreach ($sku in $availableSkus) {
                        Write-Host "  $sku"
                    }
                    Write-Host "..."
                    Write-Host "(Use 'az vm list-skus --location $RegionName --query ""[?resourceType=='virtualMachines'].name"" -o table' to see all)"
                }
                return $false
            }
            return $true
        } catch {
            if (-not $Quiet) {
                Write-Host "Error validating VM SKU: $_" -ForegroundColor Red
            }
            return $false
        }
    }

    # Function to validate region
    function Test-Region {
        param([string]$RegionName)
        
        if (-not $Quiet) {
            Write-Host "Validating region: $RegionName"
        }
        
        try {
            $result = az account list-locations --query "[?name=='$RegionName'].name" -o tsv 2>$null
            if ([string]::IsNullOrEmpty($result)) {
                if (-not $Quiet) {
                    Write-Host "Error: Region '$RegionName' is not valid or not available in your subscription." -ForegroundColor Red
                    Write-Host ""
                    Write-Host "Available regions:"
                    $availableRegions = az account list-locations --query "[].name" -o tsv 2>$null | Sort-Object
                    foreach ($regionName in $availableRegions) {
                        Write-Host "  $regionName"
                    }
                }
                return $false
            }
            return $true
        } catch {
            if (-not $Quiet) {
                Write-Host "Error validating region: $_" -ForegroundColor Red
            }
            return $false
        }
    }

    # Function to get availability zones for a specific VM SKU
    function Get-AvailabilityZones {
        param([string]$VmSkuName, [string]$RegionName, [string]$SubscriptionId)
        
        # Set subscription if provided
        if (-not [string]::IsNullOrEmpty($SubscriptionId)) {
            try {
                az account set --subscription $SubscriptionId 2>$null
            } catch {
                # Ignore errors in subscription setting for quiet mode
            }
        }
        
        # Get zones for the specific VM SKU
        try {
            $zonesJson = az vm list-skus --location $RegionName --query "[?name == '$VmSkuName'].locationInfo[0].zones[]" -o json 2>$null
            
            if ($Quiet) {
                # Output JSON format for quiet mode - compact format
                $jsonOutput = @{
                    sku = $VmSkuName
                    zones = ($zonesJson | ConvertFrom-Json)
                } | ConvertTo-Json -Compress
                Write-Output $jsonOutput
            } else {
                # Verbose output
                if (-not [string]::IsNullOrEmpty($SubscriptionId)) {
                    Write-Host "Using subscription: $SubscriptionId"
                } else {
                    $currentSub = az account show --query "id" -o tsv 2>$null
                    Write-Host "Using current subscription: $currentSub"
                }
                Write-Host ""
                
                Write-Host "=== VM SKU Zone Information ==="
                Write-Host "SKU: $VmSkuName"
                Write-Host "Region: $RegionName"
                
                # Parse zones
                $zones = $zonesJson | ConvertFrom-Json
                
                if ($null -eq $zones -or $zones.Count -eq 0) {
                    Write-Host "Availability Zones: Not available"
                } else {
                    $zonesList = ($zones | Sort-Object) -join ' '
                    Write-Host "Availability Zones: $zonesList"
                }
                Write-Host ""
                Write-Host "Timestamp: $(Get-Date)"
            }
        } catch {
            if (-not $Quiet) {
                Write-Host "Error getting availability zones: $_" -ForegroundColor Red
            }
        }
    }

    # Function to process a single VM SKU
    function Invoke-ProcessVmSku {
        param([string]$VmSkuName, [string]$RegionName, [string]$SubscriptionId)
        
        # Validate VM SKU (only in verbose mode to avoid breaking pipeline)
        if (-not $Quiet) {
            if (-not (Test-VmSku $VmSkuName $RegionName)) {
                return
            }
        }
        
        # Get availability zones
        Get-AvailabilityZones $VmSkuName $RegionName $SubscriptionId
    }

    # Function to test if input is VM SKU format
    function Test-VmSkuFormat {
        param([string]$InputString)
        return $InputString -match '^Standard_[A-Za-z][A-Za-z0-9_]*$'
    }
    
    # Initialize pipeline data collection
    $script:pipelineData = @()
    $script:hasParameter = -not [string]::IsNullOrEmpty($VmSku)
    
    # Run initial checks
    Test-Prerequisites
    
    if (-not (Test-Region $Region)) {
        exit 1
    }
}

process {
    # Collect pipeline input
    if ($null -ne $_) {
        $script:pipelineData += $_
    }
}

end {
    # Process based on input type
    if ($script:hasParameter) {
        # Single VM SKU provided as parameter
        Invoke-ProcessVmSku $VmSku $Region $Subscription
    } elseif ($script:pipelineData.Count -gt 0) {
        # Process pipeline input
        foreach ($inputLine in $script:pipelineData) {
            # Skip empty lines and lines that don't look like VM SKUs
            if (-not [string]::IsNullOrWhiteSpace($inputLine) -and (Test-VmSkuFormat $inputLine.Trim())) {
                Invoke-ProcessVmSku $inputLine.Trim() $Region $Subscription
            }
        }
    } else {
        # No pipeline input, no parameter - show error
        if (-not $Quiet) {
            Write-Host "Error: VM SKU must be provided either as parameter or via pipeline input." -ForegroundColor Red
            Write-Host "Use 'Get-Help .\get-availability-zones.ps1' for usage information."
        }
        exit 1
    }
}
