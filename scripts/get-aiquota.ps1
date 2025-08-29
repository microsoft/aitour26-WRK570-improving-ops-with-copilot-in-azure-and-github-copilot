$AiRegions = @(
'canadacentral',
'centralindia',
'eastasia',
'eastus',
'eastus2',
'francecentral',
'germanywestcentral',
'japaneast',
'koreacentral',
'northeurope',
'southafricanorth',
'southeastasia',
'swedencentral',
'westus2'
)

function Get-TenantAiQuota {
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [string]$SubscriptionId = "$(az account show --query 'id' -o tsv)",
        [string[]]$Region = $AiRegions,
        [string]$ModelName
    )

    $BaseUrl = "https://management.azure.com/subscriptions/$SubscriptionId/providers/Microsoft.CognitiveServices/locations/"
    foreach ($r in $Region) {
        $QuotaUrl = $BaseUrl + $r + "/usages?api-version=2023-05-01"
        Write-Verbose "Checking Region: $r"
        Write-Verbose "Using $QuotaUrl"
        $Response = (az rest --method get --url $QuotaUrl) | ConvertFrom-JSON
       
        if (-not [string]::IsNullOrEmpty($Response)) {
            $Content = $Response
            if ($Content.value) {
                $Content.value | 
                    Where-Object { $_.name.value -notlike 'AccountCount'} |
                    Where-Object { $_.name.value -like 'OpenAI.*'} |
                    Foreach-Object {
                        $PercentUsed = if ($null -eq $_.limit) {
                            Write-Verbose "No Quota available for $($_.name.localizedValue) in $r"
                            Write-Verbose "$($_ | convertto-json)"
                            $null
                        }
                        elseif ($_.limit -eq 0) {
                            Write-Verbose "No Quota available for $($_.name.localizedValue) in $r" 
                            $null
                        }
                        else {
                            Write-Verbose "Quota available for $($_.name.localizedValue) in ${r}: $($_.limit)"
                            Write-Verbose "Percentage used: $(($_.currentValue/$_.limit) * 100)%"
                            ($_.currentValue/$_.limit) * 100
                        }
                        $RateType, $BaseName, $SkuType, $Refinement = $_.name.localizedValue -split(' - ')
                            [pscustomobject]@{
                                Name = $BaseName
                                RateType = $RateType
                                SkuType = $SkuType
                                Refinement = $Refinement
                                PercentageUsed = $PercentUsed
                                Limit = $_.limit
                                CurrentValue = $_.currentValue
                                Region = $r
                                SubscriptionId = $Context.SubscriptionId
                                SubscriptionName = $Context.SubscriptionName
                            }
                    } |
                    Foreach-Object {
                        if ($PSBoundParameters.ContainsKey('ModelName')) {
                            if ($ModelName -notlike "*$($_.name)*") {
                                Write-Verbose "Quota for $($_.name.localizedValue) does not match $ModelName"
                            }
                            else {
                                $_
                            }
                        }
                        else {
                            $_
                        }
                    }  
            }
            elseif ($Content.error ) {
                Write-Debug "$($Content.error.message)"
            }
            else {
                Write-Verbose "No value property: $r"
                Write-Verbose "$content"
            }
        }
    } 
}
