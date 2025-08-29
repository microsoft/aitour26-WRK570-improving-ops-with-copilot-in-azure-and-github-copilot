#!/bin/bash

# Script to identify availability zones for VM SKUs in a given region
# Can be used standalone or with pipeline input from find-compatible-vm-sizes.sh
# Usage: ./get-availability-zones.sh [-q] [-r region] [-s subscription-id] [vm-sku]
# Pipeline: ./find-compatible-vm-sizes.sh -q -r eastus2 | ./get-availability-zones.sh -q -r eastus2

set -e

# Default values
QUIET_MODE=false
REGION=""
SUBSCRIPTION_ID=""
VM_SKU=""

# Function to display usage
show_usage() {
    echo "Usage: $0 [-q] [-r region] [-s subscription-id] [vm-sku]"
    echo "   or: command | $0 [-q] [-r region] [-s subscription-id]"
    echo ""
    echo "Options:"
    echo "  -q                  Quiet mode - output JSON with SKU name and zone arrays"
    echo "  -r region           Azure region name (e.g., eastus, westus2, centralus)"
    echo "  -s subscription-id  Azure subscription ID (optional, uses current if not specified)"
    echo "  -h                  Show this help message"
    echo ""
    echo "Parameters:"
    echo "  vm-sku              Azure VM SKU name (e.g., Standard_D2s_v5, Standard_B2ms)"
    echo "                      Can be provided as argument or via pipeline input"
    echo ""
    echo "Examples:"
    echo "  $0 -r eastus Standard_D2s_v5                          # Single SKU, verbose output"
    echo "  $0 -q -r eastus Standard_D2s_v5                       # Single SKU, JSON output"
    echo "  echo 'Standard_D2s_v5' | $0 -q -r eastus              # Pipeline input, JSON output"
    echo "  ./find-compatible-vm-sizes.sh -q -r eastus2 | $0 -q -r eastus2   # Pipeline from find-compatible-vm-sizes"
    echo ""
    echo "Note: You must be logged in to Azure CLI before running this script."
}

# Function to check if Azure CLI is installed and user is logged in
check_prerequisites() {
    # Check if az CLI is installed
    if ! command -v az &> /dev/null; then
        if [ "$QUIET_MODE" = false ]; then
            echo "Error: Azure CLI is not installed or not in PATH."
            echo "Please install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        fi
        exit 1
    fi

    # Check if user is logged in
    if ! az account show &> /dev/null; then
        if [ "$QUIET_MODE" = false ]; then
            echo "Error: You are not logged in to Azure CLI."
            echo "Please run 'az login' to authenticate."
        fi
        exit 1
    fi
}

# Function to validate VM SKU
validate_vm_sku() {
    local vm_sku=$1
    local region=$2
    
    if [ "$QUIET_MODE" = false ]; then
        echo "Validating VM SKU: $vm_sku in region: $region"
    fi
    
    # Check if VM SKU exists in the region
    if ! az vm list-skus --location "$region" --query "[?name=='$vm_sku']" -o tsv | grep -q "$vm_sku"; then
        if [ "$QUIET_MODE" = false ]; then
            echo "Error: VM SKU '$vm_sku' is not available in region '$region'."
            echo ""
            echo "Available VM SKUs in $region (showing first 10):"
            az vm list-skus --location "$region" --query "[?resourceType=='virtualMachines'].name" -o tsv | sort | head -10
            echo "..."
            echo "(Use 'az vm list-skus --location $region --query \"[?resourceType=='virtualMachines'].name\" -o table' to see all)"
        fi
        exit 1
    fi
}

# Function to validate region
validate_region() {
    local region=$1
    if [ "$QUIET_MODE" = false ]; then
        echo "Validating region: $region"
    fi
    
    # Get list of available regions
    if ! az account list-locations --query "[?name=='$region'].name" -o tsv | grep -q "$region"; then
        if [ "$QUIET_MODE" = false ]; then
            echo "Error: Region '$region' is not valid or not available in your subscription."
            echo ""
            echo "Available regions:"
            az account list-locations --query "[].name" -o tsv | sort
        fi
        exit 1
    fi
}

# Function to get availability zones for a specific VM SKU
get_availability_zones() {
    local vm_sku=$1
    local region=$2
    local subscription_id=$3
    
    # Set subscription if provided
    if [ -n "$subscription_id" ]; then
        az account set --subscription "$subscription_id" 2>/dev/null
    fi
    
    # Get zones for the specific VM SKU
    local zones_json=$(az vm list-skus --location "$region" --query "[?name == '$vm_sku'].locationInfo[0].zones[]" -o json 2>/dev/null)
    
    if [ "$QUIET_MODE" = true ]; then
        # Output JSON format for quiet mode - compact format
        if command -v jq &> /dev/null; then
            zones_compact=$(echo "$zones_json" | jq -c '.')
        else
            # Compact JSON without jq - remove extra whitespace and newlines
            zones_compact=$(echo "$zones_json" | tr -d '\n\t' | sed 's/  */ /g' | sed 's/ *\[ */ [/g' | sed 's/ *\] */]/g' | sed 's/ *, */,/g')
        fi
        echo "{\"sku\":\"$vm_sku\",\"zones\":$zones_compact}"
    else
        # Verbose output
        if [ -n "$subscription_id" ]; then
            echo "Using subscription: $subscription_id"
        else
            current_sub=$(az account show --query "id" -o tsv 2>/dev/null)
            echo "Using current subscription: $current_sub"
        fi
        echo ""
        
        echo "=== VM SKU Zone Information ==="
        echo "SKU: $vm_sku"
        echo "Region: $region"
        
        # Normalize the zones_json for comparison
        zones_normalized=$(echo "$zones_json" | tr -d ' \n\t')
        
        if [ "$zones_normalized" = "[]" ] || [ -z "$zones_normalized" ] || [ "$zones_normalized" = "null" ]; then
            echo "Availability Zones: Not available"
        else
            # Check if jq is available for parsing, otherwise use basic parsing
            if command -v jq &> /dev/null; then
                zones_list=$(echo "$zones_json" | jq -r '.[]' | sort -n | tr '\n' ' ')
            else
                # Basic parsing without jq
                zones_list=$(echo "$zones_json" | sed 's/\[//g;s/\]//g;s/"//g;s/,/ /g' | tr -s ' ' | xargs)
            fi
            echo "Availability Zones: $zones_list"
        fi
        echo ""
        echo "Timestamp: $(date)"
    fi
}

# Function to process a single VM SKU
process_vm_sku() {
    local vm_sku=$1
    local region=$2
    local subscription_id=$3
    
    # Validate VM SKU (only in verbose mode to avoid breaking pipeline)
    if [ "$QUIET_MODE" = false ]; then
        validate_vm_sku "$vm_sku" "$region"
    fi
    
    # Get availability zones
    get_availability_zones "$vm_sku" "$region" "$subscription_id"
}

# Main script logic
main() {
    # Parse command line options
    while getopts "qr:s:h" opt; do
        case ${opt} in
            q )
                QUIET_MODE=true
                ;;
            r )
                REGION=$OPTARG
                ;;
            s )
                SUBSCRIPTION_ID=$OPTARG
                ;;
            h )
                show_usage
                exit 0
                ;;
            \? )
                echo "Invalid option: $OPTARG" 1>&2
                show_usage
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))
    
    # Check if region is provided
    if [ -z "$REGION" ]; then
        if [ "$QUIET_MODE" = false ]; then
            echo "Error: Region parameter (-r) is required."
            echo ""
            show_usage
        fi
        exit 1
    fi
    
    # Check prerequisites
    check_prerequisites
    
    # Validate region
    validate_region "$REGION"
    
    # Check if VM SKU is provided as argument
    if [ -n "$1" ]; then
        # Single VM SKU provided as argument
        VM_SKU="$1"
        process_vm_sku "$VM_SKU" "$REGION" "$SUBSCRIPTION_ID"
    else
        # Check if there's input from pipeline
        if [ -t 0 ]; then
            # No pipeline input, no argument - show usage
            if [ "$QUIET_MODE" = false ]; then
                echo "Error: VM SKU must be provided either as argument or via pipeline input."
                echo ""
                show_usage
            fi
            exit 1
        else
            # Read from pipeline
            while IFS= read -r vm_sku; do
                # Skip empty lines and lines that don't look like VM SKUs
                if [ -n "$vm_sku" ] && [[ "$vm_sku" =~ ^Standard_[A-Za-z][A-Za-z0-9_]*$ ]]; then
                    process_vm_sku "$vm_sku" "$REGION" "$SUBSCRIPTION_ID"
                fi
            done
        fi
    fi
}

# Run main function with all arguments
main "$@"
