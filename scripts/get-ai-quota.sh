#!/bin/bash

# get-tenant-ai-quota.sh
# Bash equivalent of Get-TenantAiQuota PowerShell function using Azure CLI
# Retrieves AI quota information for Cognitive Services across Azure regions

# Default AI regions array
AI_REGIONS=(
    "eastus" "southcentralus" "westus2" "westus3" "australiaeast" "southeastasia"
    "northeurope" "swedencentral" "uksouth" "westeurope" "centralus" "southafricanorth"
    "centralindia" "eastasia" "japaneast" "koreacentral" "newzealandnorth" "canadacentral"
    "francecentral" "germanywestcentral" "italynorth" "norwayeast" "polandcentral"
    "spaincentral" "switzerlandnorth" "mexicocentral" "uaenorth" "brazilsouth"
    "israelcentral" "qatarcentral" "centralusstage" "eastusstage" "eastus2stage"
    "northcentralusstage" "southcentralusstage" "westusstage" "westus2stage"
    "asia" "asiapacific" "australia" "brazil" "canada" "europe" "france" "germany"
    "global" "india" "israel" "italy" "japan" "korea" "newzealand" "norway"
    "poland" "qatar" "singapore" "southafrica" "sweden" "switzerland" "uae" "uk"
    "unitedstates" "unitedstateseuap" "eastasiastage" "southeastasiastage"
    "brazilus" "eastus2" "eastusstg" "northcentralus" "westus" "japanwest"
    "jioindiawest" "centraluseuap" "eastus2euap" "southcentralusstg" "westcentralus"
    "southafricawest" "australiacentral" "australiacentral2" "australiasoutheast"
    "jioindiacentral" "koreasouth" "southindia" "westindia" "canadaeast"
    "francesouth" "germanynorth" "norwaywest" "switzerlandwest" "ukwest"
    "uaecentral" "brazilsoutheast"
)

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -s, --subscription-id ID    Azure subscription ID (uses current if not specified)"
    echo "  -r, --regions LIST          Comma-separated list of regions (default: all AI regions)"
    echo "  -m, --model-name NAME       Filter results by model name"
    echo "  -v, --verbose               Enable verbose output"
    echo "  -o, --output FORMAT         Output format: json, table, csv (default: table)"
    echo "  -h, --help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                                          # Get quota for all regions"
    echo "  $0 -r eastus,westus2                      # Get quota for specific regions"
    echo "  $0 -m gpt-4                               # Filter by model name"
    echo "  $0 -s 12345678-1234-1234-1234-123456789012 # Use specific subscription"
    echo "  $0 -o json                                # Output as JSON"
}

# Function to log verbose messages
log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "[VERBOSE] $1" >&2
    fi
}

# Function to calculate percentage used
calculate_percentage() {
    local current=$1
    local limit=$2
    
    if [[ -z "$limit" || "$limit" == "null" || "$limit" -eq 0 ]]; then
        echo "null"
    else
        echo "scale=2; ($current / $limit) * 100" | bc -l 2>/dev/null || echo "0"
    fi
}

# Function to split localized value into components
split_localized_value() {
    local localized_value="$1"
    
    # Split by " - " delimiter
    IFS=' - ' read -ra PARTS <<< "$localized_value"
    
    local rate_type="${PARTS[0]:-}"
    local base_name="${PARTS[1]:-}"
    local sku_type="${PARTS[2]:-}"
    local refinement="${PARTS[3]:-}"
    
    echo "$rate_type|$base_name|$sku_type|$refinement"
}

# Function to process quota data for a region
process_region_quota() {
    local region="$1"
    local subscription_id="$2"
    
    log_verbose "Checking Region: $region"
    
    # Construct the REST API URL
    local quota_url="https://management.azure.com/subscriptions/${subscription_id}/providers/Microsoft.CognitiveServices/locations/${region}/usages?api-version=2023-05-01"
    
    # Make the REST API call with retry logic
    local response
    response=$(az rest --method get --url "$quota_url" 2>/dev/null)
    
    if [[ $? -ne 0 ]]; then
        log_verbose "Failed to get quota for $region, trying again"
        sleep 1
        response=$(az rest --method get --url "$quota_url" 2>/dev/null)
        
        if [[ $? -ne 0 ]]; then
            log_verbose "Failed to get quota for $region after retry"
            return
        fi
    fi
    
    if [[ -n "$response" ]]; then
        # Check if response has value property
        local has_value
        has_value=$(echo "$response" | jq -r '.value // empty' 2>/dev/null)
        
        if [[ -n "$has_value" ]]; then
            # Process each quota item
            echo "$response" | jq -r '.value[] | select(.name.value | test("^OpenAI\\..*") and (test("AccountCount") | not)) | 
                [
                    .name.localizedValue,
                    (.limit // "null"),
                    (.currentValue // 0),
                    "'"$region"'"
                ] | @csv' 2>/dev/null | while IFS=',' read -r localized_value limit current_value region_name; do
                
                # Remove quotes from CSV output
                localized_value=$(echo "$localized_value" | tr -d '"')
                limit=$(echo "$limit" | tr -d '"')
                current_value=$(echo "$current_value" | tr -d '"')
                region_name=$(echo "$region_name" | tr -d '"')
                
                # Skip if model name filter is specified and doesn't match
                if [[ -n "$MODEL_NAME" ]]; then
                    if [[ "$localized_value" != *"$MODEL_NAME"* ]]; then
                        log_verbose "Quota for $localized_value does not match $MODEL_NAME"
                        continue
                    fi
                fi
                
                # Calculate percentage used
                local percentage_used
                if [[ "$limit" == "null" || "$limit" -eq 0 ]]; then
                    log_verbose "No Quota available for $localized_value in $region"
                    percentage_used="null"
                else
                    log_verbose "Quota available for $localized_value in ${region}: $limit"
                    percentage_used=$(calculate_percentage "$current_value" "$limit")
                    log_verbose "Percentage used: ${percentage_used}%"
                fi
                
                # Split localized value into components
                local components
                components=$(split_localized_value "$localized_value")
                IFS='|' read -r rate_type base_name sku_type refinement <<< "$components"
                
                # Get subscription name
                local subscription_name
                subscription_name=$(az account show --query name -o tsv 2>/dev/null || echo "Unknown")
                
                # Output based on format
                case "$OUTPUT_FORMAT" in
                    "json")
                        jq -n \
                            --arg name "$base_name" \
                            --arg rate_type "$rate_type" \
                            --arg sku_type "$sku_type" \
                            --arg refinement "$refinement" \
                            --arg percentage_used "$percentage_used" \
                            --arg limit "$limit" \
                            --arg current_value "$current_value" \
                            --arg region "$region_name" \
                            --arg subscription_id "$subscription_id" \
                            --arg subscription_name "$subscription_name" \
                            '{
                                Name: $name,
                                RateType: $rate_type,
                                SkuType: $sku_type,
                                Refinement: $refinement,
                                PercentageUsed: (if $percentage_used == "null" then null else ($percentage_used | tonumber) end),
                                Limit: (if $limit == "null" then null else ($limit | tonumber) end),
                                CurrentValue: ($current_value | tonumber),
                                Region: $region,
                                SubscriptionId: $subscription_id,
                                SubscriptionName: $subscription_name
                            }'
                        ;;
                    "csv")
                        echo "\"$base_name\",\"$rate_type\",\"$sku_type\",\"$refinement\",\"$percentage_used\",\"$limit\",\"$current_value\",\"$region_name\",\"$subscription_id\",\"$subscription_name\""
                        ;;
                    "table"|*)
                        printf "%-20s %-15s %-15s %-15s %-12s %-10s %-12s %-15s\n" \
                            "${base_name:0:19}" \
                            "${rate_type:0:14}" \
                            "${sku_type:0:14}" \
                            "${refinement:0:14}" \
                            "${percentage_used:0:11}" \
                            "${limit:0:9}" \
                            "${current_value:0:11}" \
                            "${region_name:0:14}"
                        ;;
                esac
            done
        else
            # Check for error in response
            local error_message
            error_message=$(echo "$response" | jq -r '.error.message // empty' 2>/dev/null)
            
            if [[ -n "$error_message" ]]; then
                log_verbose "Error for region $region: $error_message"
            else
                log_verbose "No value property for region: $region"
            fi
        fi
    fi
}

# Parse command line arguments
SUBSCRIPTION_ID=""
REGIONS=()
MODEL_NAME=""
VERBOSE=false
OUTPUT_FORMAT="table"

while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--subscription-id)
            SUBSCRIPTION_ID="$2"
            shift 2
            ;;
        -r|--regions)
            IFS=',' read -ra REGIONS <<< "$2"
            shift 2
            ;;
        -m|--model-name)
            MODEL_NAME="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -o|--output)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            show_usage
            exit 1
            ;;
    esac
done

# Validate dependencies
if ! command -v az &> /dev/null; then
    echo "Error: Azure CLI (az) is not installed or not in PATH" >&2
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed or not in PATH" >&2
    exit 1
fi

if [[ "$OUTPUT_FORMAT" != "json" && "$OUTPUT_FORMAT" != "table" && "$OUTPUT_FORMAT" != "csv" ]]; then
    echo "Error: Invalid output format. Must be json, table, or csv" >&2
    exit 1
fi

# Check if user is logged in to Azure
if ! az account show &> /dev/null; then
    echo "Error: Not logged in to Azure. Please run 'az login' first." >&2
    exit 1
fi

# Get subscription ID if not provided
if [[ -z "$SUBSCRIPTION_ID" ]]; then
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    if [[ -z "$SUBSCRIPTION_ID" ]]; then
        echo "Error: Could not determine subscription ID" >&2
        exit 1
    fi
fi

log_verbose "Using subscription ID: $SUBSCRIPTION_ID"

# Use all AI regions if none specified
if [[ ${#REGIONS[@]} -eq 0 ]]; then
    REGIONS=("${AI_REGIONS[@]}")
fi

log_verbose "Checking ${#REGIONS[@]} regions"

# Output header for table format
if [[ "$OUTPUT_FORMAT" == "table" ]]; then
    printf "%-20s %-15s %-15s %-15s %-12s %-10s %-12s %-15s\n" \
        "Name" "RateType" "SkuType" "Refinement" "Percent Used" "Limit" "CurrentValue" "Region"
    printf "%-20s %-15s %-15s %-15s %-12s %-10s %-12s %-15s\n" \
        "--------------------" "---------------" "---------------" "---------------" "------------" "----------" "------------" "---------------"
elif [[ "$OUTPUT_FORMAT" == "csv" ]]; then
    echo "Name,RateType,SkuType,Refinement,PercentageUsed,Limit,CurrentValue,Region,SubscriptionId,SubscriptionName"
fi

# Process each region
for region in "${REGIONS[@]}"; do
    process_region_quota "$region" "$SUBSCRIPTION_ID"
done

log_verbose "AI quota check completed"
