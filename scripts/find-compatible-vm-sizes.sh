#!/bin/bash

# Script to find compatible VM sizes for Azure regions
# Focuses on Standard_D2, Standard_D4 variants and similar options

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print only if not in quiet mode
print_if_not_quiet() {
    if [ "$QUIET_MODE" = false ]; then
        echo -e "$@"
    fi
}

# Function to display usage
usage() {
    echo "Usage: $0 [-r region] [-s subscription_id] [-n node_count] [-c min_total_vcpus] [-l limit] [-q] [-h]"
    echo ""
    echo "Options:"
    echo "  -r region           Azure region (e.g., eastus, westus2, swedencentral)"
    echo "  -s subscription     Azure subscription ID (optional, uses current if not specified)"
    echo "  -n node_count       Number of nodes to deploy in AKS cluster (default: 3)"
    echo "  -c min_total_vcpus  Minimum total vCPUs needed for cluster (optional, calculated from node_count if not specified)"
    echo "  -l limit            Maximum number of results to show (default: 5)"
    echo "  -q                  Quiet mode - only output SKU names of matches"
    echo "  -h                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -r eastus2                                    # 3 nodes, auto-calculate total vCPUs"
    echo "  $0 -r swedencentral -n 5                         # 5 nodes, auto-calculate total vCPUs"
    echo "  $0 -r eastus2 -n 3 -c 12 -l 3                    # 3 nodes, minimum 12 total vCPUs, show top 3 results"
    echo "  $0 -r eastus2 -q                                 # Quiet mode - only output SKU names"
}

# Parse command line arguments
NODE_COUNT=3
MIN_TOTAL_VCPUS=""
RESULT_LIMIT=5
QUIET_MODE=false
while getopts "r:s:n:c:l:qh" opt; do
    case ${opt} in
        r )
            REGION=$OPTARG
            ;;
        s )
            SUBSCRIPTION=$OPTARG
            ;;
        n )
            NODE_COUNT=$OPTARG
            # Validate that NODE_COUNT is a number
            if ! [[ "$NODE_COUNT" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}Error: Node count must be a number${NC}"
                exit 1
            fi
            ;;
        c )
            MIN_TOTAL_VCPUS=$OPTARG
            # Validate that MIN_TOTAL_VCPUS is a number
            if ! [[ "$MIN_TOTAL_VCPUS" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}Error: Minimum total vCPUs must be a number${NC}"
                exit 1
            fi
            ;;
        l )
            RESULT_LIMIT=$OPTARG
            # Validate that RESULT_LIMIT is a number
            if ! [[ "$RESULT_LIMIT" =~ ^[0-9]+$ ]]; then
                echo -e "${RED}Error: Result limit must be a number${NC}"
                exit 1
            fi
            ;;
        q )
            QUIET_MODE=true
            ;;
        h )
            usage
            exit 0
            ;;
        \? )
            echo "Invalid option: $OPTARG" 1>&2
            usage
            exit 1
            ;;
    esac
done

# Check if region is provided
if [ -z "$REGION" ]; then
    echo -e "${RED}Error: Region is required${NC}"
    usage
    exit 1
fi

# Set subscription if provided
if [ -n "$SUBSCRIPTION" ]; then
    print_if_not_quiet "${BLUE}Setting subscription to: ${SUBSCRIPTION}${NC}"
    az account set --subscription "$SUBSCRIPTION"
fi

# Get current subscription info
CURRENT_SUB=$(az account show --query "id" -o tsv 2>/dev/null)
SUB_NAME=$(az account show --query "name" -o tsv 2>/dev/null)

if [ -z "$CURRENT_SUB" ]; then
    if [ "$QUIET_MODE" = false ]; then
        echo -e "${RED}Error: Not logged in to Azure CLI. Please run 'az login' first.${NC}"
    fi
    exit 1
fi

print_if_not_quiet "${BLUE}Current subscription: ${SUB_NAME} (${CURRENT_SUB})${NC}"
print_if_not_quiet "${BLUE}Checking VM sizes for region: ${REGION}${NC}"
print_if_not_quiet "${BLUE}Planned AKS cluster: ${NODE_COUNT} nodes${NC}"

# Calculate minimum total vCPUs if not specified
if [ -z "$MIN_TOTAL_VCPUS" ]; then
    MIN_TOTAL_VCPUS=$((NODE_COUNT * 2))  # Default to 2 vCPUs per node minimum as baseline
    print_if_not_quiet "${BLUE}Minimum total vCPUs for cluster: ${MIN_TOTAL_VCPUS} (baseline: ${NODE_COUNT} nodes × 2 vCPUs minimum)${NC}"
    print_if_not_quiet "${YELLOW}Note: Actual vCPU requirements will be calculated based on each VM SKU${NC}"
else
    print_if_not_quiet "${BLUE}Minimum total vCPUs for cluster: ${MIN_TOTAL_VCPUS} (user-specified)${NC}"
fi
print_if_not_quiet ""

# Preferred VM sizes in order of preference
PREFERRED_SIZES=(
    "Standard_D2s_v5"
    "Standard_D2_v5"
    "Standard_D2s_v4"
    "Standard_D2_v4"
    "Standard_D2s_v3"
    "Standard_D2_v3"
    "Standard_D4s_v5"
    "Standard_D4_v5"
    "Standard_D4s_v4"
    "Standard_D4_v4"
    "Standard_D4s_v3"
    "Standard_D4_v3"
    "Standard_B2s"
    "Standard_B2ms"
    "Standard_B4ms"
    "Standard_DS2_v2"
    "Standard_DS3_v2"
    "Standard_DS4_v2"
)

# Function to check if a VM size is available in the region
check_vm_size() {
    local vm_size=$1
    az vm list-sizes --location "$REGION" --query "[?name=='$vm_size']" -o tsv 2>/dev/null | grep -q "$vm_size"
}

# Function to get VM size details
get_vm_details() {
    local vm_size=$1
    az vm list-sizes --location "$REGION" --query "[?name=='$vm_size'].{Name:name,Cores:numberOfCores,RAM:memoryInMB,MaxDataDisks:maxDataDiskCount}" -o table 2>/dev/null
}

# Function to sort VM sizes by vCPU count (lowest first)
sort_vms_by_vcpu() {
    local vm_array=("$@")
    local temp_file=$(mktemp)
    
    # Create a temp file with VM_NAME:VCPU_COUNT format
    for vm in "${vm_array[@]}"; do
        local vcpus=$(az vm list-sizes --location "$REGION" --query "[?name=='$vm'].numberOfCores" -o tsv 2>/dev/null)
        if [ -n "$vcpus" ]; then
            echo "$vm:$vcpus" >> "$temp_file"
        fi
    done
    
    # Sort by vCPU count (second field) and extract VM names
    sort -t: -k2 -n "$temp_file" | cut -d: -f1
    rm -f "$temp_file"
}

# Function to get quota information
get_quota_info() {
    echo -e "${BLUE}Checking quota limits...${NC}"
    az vm list-usage --location "$REGION" --query "[?contains(name.value, 'cores') || contains(name.value, 'Core') || contains(localName.value, 'vCPUs')].{Name:name.value,LocalName:localName.value,Current:currentValue,Limit:limit}" -o table 2>/dev/null
}

# Function to map VM SKU to the correct quota family name
get_vm_quota_family() {
    local vm_size=$1
    


    # Map VM SKU to the correct quota family name that Azure uses
    case "$vm_size" in
        Standard_D*s_v5) echo "standardDSv5Family" ;;
        Standard_D*_v5) echo "standardDv5Family" ;;
        Standard_D*s_v4) echo "standardDSv4Family" ;;
        Standard_D*_v4) echo "standardDv4Family" ;;
        Standard_D*s_v3) echo "standardDSv3Family" ;;
        Standard_D*_v3) echo "standardDv3Family" ;;
        Standard_D*s_v2) echo "standardDSv2Family" ;;
        Standard_D*_v2) echo "standardDv2Family" ;;
        Standard_B*s) echo "standardBSv2Family" ;;
        Standard_B*) echo "standardBsFamily" ;;
        *)
            # For unknown patterns, try to extract a reasonable family name
            echo ""
            ;;
    esac
}

# Function to check if there's enough quota for a VM size
check_quota_for_vm() {
    local vm_size=$1
    local vm_cores=$(az vm list-sizes --location "$REGION" --query "[?name=='$vm_size'].numberOfCores" -o tsv 2>/dev/null)
    
    if [ -z "$vm_cores" ]; then
        return 1
    fi
    
    # Calculate total vCPUs needed for the cluster based on this specific VM SKU
    local total_cores_needed=$((vm_cores * NODE_COUNT))
    
    # Only check if cluster meets minimum if MIN_TOTAL_VCPUS was user-specified
    # If it was auto-calculated (baseline), skip this check since we're evaluating different SKUs
    if [ -n "$MIN_TOTAL_VCPUS" ] && [ "$MIN_TOTAL_VCPUS" -ne $((NODE_COUNT * 2)) ]; then
        # User specified a custom minimum, so enforce it
        if [ "$total_cores_needed" -lt "$MIN_TOTAL_VCPUS" ]; then
            echo -e "${YELLOW}  ⚠ Cluster would have only $total_cores_needed vCPUs (${NODE_COUNT}×${vm_cores}), need at least $MIN_TOTAL_VCPUS${NC}"
            return 1
        fi
    fi
    
    # Get current core usage and limits
    local core_usage=$(az vm list-usage --location "$REGION" --query "[?contains(name.value, 'cores')].{current:currentValue,limit:limit}" -o tsv 2>/dev/null)
    
    if [ -n "$core_usage" ]; then
        local current_cores=$(echo "$core_usage" | cut -f1)
        local max_cores=$(echo "$core_usage" | cut -f2)
        local available_cores=$((max_cores - current_cores))
        
        if [ "$total_cores_needed" -le "$available_cores" ]; then
            echo -e "${GREEN}  ✓ Quota OK: $total_cores_needed vCPUs needed (${NODE_COUNT}×${vm_cores}), $available_cores available${NC}"
            return 0
        else
            echo -e "${RED}  ✗ Quota insufficient: $total_cores_needed vCPUs needed (${NODE_COUNT}×${vm_cores}), only $available_cores available${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}  ? Unable to determine quota status${NC}"
        return 2
    fi
}

# Function to get VM family specific quota
check_vm_family_quota() {
    local vm_size=$1
    local vm_cores=$(az vm list-sizes --location "$REGION" --query "[?name=='$vm_size'].numberOfCores" -o tsv 2>/dev/null)
    local total_cores_needed=$((vm_cores * NODE_COUNT))
    
    # Only check if cluster meets minimum if MIN_TOTAL_VCPUS was user-specified
    # If it was auto-calculated (baseline), skip this check since we're evaluating different SKUs
    if [ -n "$MIN_TOTAL_VCPUS" ] && [ "$MIN_TOTAL_VCPUS" -ne $((NODE_COUNT * 2)) ]; then
        # User specified a custom minimum, so enforce it
        if [ "$total_cores_needed" -lt "$MIN_TOTAL_VCPUS" ]; then
            return 1
        fi
    fi
    
    # Get the correct quota family name
    local family_name=$(get_vm_quota_family "$vm_size")
    
    if [ -n "$family_name" ]; then
        # Try both localName.value and name.value as different Azure CLI versions may use different properties
        local family_quota=$(az vm list-usage --location "$REGION" --query "[?name.value=='$family_name'].{current:currentValue,limit:limit}" -o tsv 2>/dev/null | head -1)
        
        if [ -n "$family_quota" ]; then
            local current_family=$(echo "$family_quota" | cut -f1)
            local max_family=$(echo "$family_quota" | cut -f2)
            local available_family=$((max_family - current_family))
            
            if [ "$total_cores_needed" -le "$available_family" ]; then
                echo -e "${GREEN}  ✓ Family quota OK: $total_cores_needed vCPUs needed (${NODE_COUNT}×${vm_cores}) in $family_name${NC}"
                return 0
            else
                echo -e "${RED}  ✗ Family quota insufficient: $total_cores_needed vCPUs needed (${NODE_COUNT}×${vm_cores}), only $available_family available in $family_name${NC}"
                return 1
            fi
        else
            echo -e "${YELLOW}  ? Unable to find quota for family: $family_name${NC}"
            return 2
        fi
    else
        echo -e "${YELLOW}  ? Unknown VM family for quota lookup: $vm_size${NC}"
        return 2
    fi
}

if [ "$QUIET_MODE" = false ]; then
    echo -e "${YELLOW}Checking preferred VM sizes...${NC}"
    echo ""
fi

AVAILABLE_SIZES=()
UNAVAILABLE_SIZES=()
QUOTA_OK_SIZES=()
QUOTA_INSUFFICIENT_SIZES=()
INSUFFICIENT_TOTAL_VCPU_SIZES=()

# Check each preferred size
for size in "${PREFERRED_SIZES[@]}"; do
    print_if_not_quiet "${BLUE}Checking $size...${NC}"
    if check_vm_size "$size"; then
        # Get VM cores to calculate cluster total
        vm_cores=$(az vm list-sizes --location "$REGION" --query "[?name=='$size'].numberOfCores" -o tsv 2>/dev/null)
        total_cluster_vcpus=$((vm_cores * NODE_COUNT))
        
        # Only check minimum requirement if user specified a custom minimum
        # Otherwise, evaluate all SKUs regardless of the baseline calculation
        meets_minimum=true
        if [ -n "$MIN_TOTAL_VCPUS" ] && [ "$MIN_TOTAL_VCPUS" -ne $((NODE_COUNT * 2)) ]; then
            # User specified a custom minimum, so enforce it
            if [ "$total_cluster_vcpus" -lt "$MIN_TOTAL_VCPUS" ]; then
                meets_minimum=false
            fi
        fi
        
        if [ "$meets_minimum" = true ]; then
            AVAILABLE_SIZES+=("$size")
            print_if_not_quiet "${GREEN}  ✓ Available in region (${vm_cores} vCPUs × ${NODE_COUNT} nodes = ${total_cluster_vcpus} total vCPUs)${NC}"
            
            # Check quota (suppress output in quiet mode)
            if [ "$QUIET_MODE" = true ]; then
                if check_quota_for_vm "$size" >/dev/null 2>&1 && check_vm_family_quota "$size" >/dev/null 2>&1; then
                    QUOTA_OK_SIZES+=("$size")
                else
                    QUOTA_INSUFFICIENT_SIZES+=("$size")
                fi
            else
                if check_quota_for_vm "$size" && check_vm_family_quota "$size"; then
                    QUOTA_OK_SIZES+=("$size")
                else
                    QUOTA_INSUFFICIENT_SIZES+=("$size")
                fi
            fi
        else
            INSUFFICIENT_TOTAL_VCPU_SIZES+=("$size")
            print_if_not_quiet "${YELLOW}  ⚠ Available but insufficient total vCPUs (${total_cluster_vcpus} < ${MIN_TOTAL_VCPUS} required)${NC}"
        fi
    else
        UNAVAILABLE_SIZES+=("$size")
        print_if_not_quiet "${RED}  ✗ Not available in region${NC}"
    fi
    print_if_not_quiet ""
done

print_if_not_quiet ""

if [ ${#QUOTA_OK_SIZES[@]} -eq 0 ]; then
    print_if_not_quiet "${RED}❌ No preferred VM sizes can provide sufficient quota for ${NODE_COUNT}-node cluster in region ${REGION}${NC}"
    
    if [ ${#AVAILABLE_SIZES[@]} -gt 0 ]; then
        print_if_not_quiet "${YELLOW}VM sizes available in region but with insufficient quota for ${NODE_COUNT} nodes:${NC}"
        if [ "$QUIET_MODE" = false ]; then
            for size in "${AVAILABLE_SIZES[@]}"; do
                vm_cores=$(az vm list-sizes --location "$REGION" --query "[?name=='$size'].numberOfCores" -o tsv 2>/dev/null)
                total_cores=$((vm_cores * NODE_COUNT))
                echo -e "${YELLOW}  - $size (${vm_cores} vCPUs × ${NODE_COUNT} = ${total_cores} total vCPUs)${NC}"
            done
            echo ""
            echo -e "${BLUE}💡 You may need to request quota increase for:${NC}"
            get_quota_info
        fi
    fi
    
    print_if_not_quiet "${YELLOW}Searching for alternative D-series VMs for ${NODE_COUNT}-node cluster...${NC}"
    
    # Only calculate minimum per-VM vCPUs if user specified a custom minimum
    if [ -n "$MIN_TOTAL_VCPUS" ] && [ "$MIN_TOTAL_VCPUS" -ne $((NODE_COUNT * 2)) ]; then
        # Calculate minimum per-VM vCPUs needed
        min_per_vm_vcpus=$(((MIN_TOTAL_VCPUS + NODE_COUNT - 1) / NODE_COUNT))  # Ceiling division
        query_filter="[?contains(name, 'Standard_D') && numberOfCores >= $min_per_vm_vcpus && numberOfCores <= 16]"
        print_if_not_quiet "${BLUE}Checking alternative D-series VMs (≥${min_per_vm_vcpus} vCPUs per VM for ${MIN_TOTAL_VCPUS} total):${NC}"
    else
        # No specific minimum, check all reasonable D-series VMs
        query_filter="[?contains(name, 'Standard_D') && numberOfCores >= 1 && numberOfCores <= 16]"
        print_if_not_quiet "${BLUE}Checking alternative D-series VMs (any size for ${NODE_COUNT} nodes):${NC}"
    fi
    
    # Search for any D-series VMs as alternatives and check their quota
    ALTERNATIVE_VMS=$(az vm list-sizes --location "$REGION" --query "${query_filter}.name" -o tsv 2>/dev/null | sort)
    
    if [ -n "$ALTERNATIVE_VMS" ]; then
        if [ "$QUIET_MODE" = false ]; then
            for vm in $ALTERNATIVE_VMS; do
                vm_cores=$(az vm list-sizes --location "$REGION" --query "[?name=='$vm'].numberOfCores" -o tsv 2>/dev/null)
                total_cores=$((vm_cores * NODE_COUNT))
                if check_quota_for_vm "$vm" >/dev/null 2>&1 && check_vm_family_quota "$vm" >/dev/null 2>&1; then
                    echo -e "${GREEN}  ✓ $vm (${vm_cores} vCPUs × ${NODE_COUNT} = ${total_cores} total vCPUs, has quota)${NC}"
                else
                    echo -e "${YELLOW}  - $vm (${vm_cores} vCPUs × ${NODE_COUNT} = ${total_cores} total vCPUs, insufficient quota)${NC}"
                fi
            done
        fi
    else
        if [ -n "$MIN_TOTAL_VCPUS" ] && [ "$MIN_TOTAL_VCPUS" -ne $((NODE_COUNT * 2)) ]; then
            print_if_not_quiet "${RED}No D-series VMs found that can provide ${MIN_TOTAL_VCPUS} total vCPUs for ${NODE_COUNT} nodes${NC}"
        else
            print_if_not_quiet "${RED}No D-series VMs found in this region${NC}"
        fi
    fi
else
    # Sort the available VMs by vCPU count (lowest first)
    readarray -t SORTED_QUOTA_OK_SIZES < <(sort_vms_by_vcpu "${QUOTA_OK_SIZES[@]}")
    
    if [ "$QUIET_MODE" = true ]; then
        # Quiet mode: only output SKU names, limited by RESULT_LIMIT
        count=0
        for size in "${SORTED_QUOTA_OK_SIZES[@]}"; do
            if [ $count -lt $RESULT_LIMIT ]; then
                echo "$size"
                ((count++))
            fi
        done
    else
        # Normal mode: full output
        echo -e "${GREEN}✅ VM sizes with sufficient quota for ${NODE_COUNT}-node cluster (ordered by lowest resources):${NC}"
        echo ""
        
        # Show details for limited number of results
        count=0
        for size in "${SORTED_QUOTA_OK_SIZES[@]}"; do
            if [ $count -lt $RESULT_LIMIT ]; then
                vm_cores=$(az vm list-sizes --location "$REGION" --query "[?name=='$size'].numberOfCores" -o tsv 2>/dev/null)
                total_cores=$((vm_cores * NODE_COUNT))
                echo -e "${GREEN}$((count+1)). $size${NC}"
                echo "   Per VM: ${vm_cores} vCPUs"
                echo "   Total cluster: ${total_cores} vCPUs (${NODE_COUNT} nodes)"
                get_vm_details "$size"
                echo ""
                ((count++))
            fi
        done
        
        # Show the top recommendation (lowest resource)
        TOP_CHOICE="${SORTED_QUOTA_OK_SIZES[0]}"
        vm_cores=$(az vm list-sizes --location "$REGION" --query "[?name=='$TOP_CHOICE'].numberOfCores" -o tsv 2>/dev/null)
        total_cores=$((vm_cores * NODE_COUNT))
        echo -e "${GREEN}🎯 TOP RECOMMENDATION (Most Cost-Effective): ${TOP_CHOICE}${NC}"
        echo -e "${BLUE}   Cluster configuration: ${NODE_COUNT} nodes × ${vm_cores} vCPUs = ${total_cores} total vCPUs${NC}"
        
        # Show if there are more results than displayed
        if [ ${#SORTED_QUOTA_OK_SIZES[@]} -gt $RESULT_LIMIT ]; then
            additional=$((${#SORTED_QUOTA_OK_SIZES[@]} - RESULT_LIMIT))
            echo -e "${YELLOW}   Note: ${additional} additional VM sizes available. Use -l to show more results.${NC}"
        fi
        
        echo ""
        echo "To use this VM size in your deployment, set:"
        echo -e "${BLUE}azd env set AKS_NODE_POOL_VM_SIZE ${TOP_CHOICE}${NC}"
        
        # Show quota status summary
        echo ""
        echo -e "${BLUE}📊 Quota Summary:${NC}"
        get_quota_info
    fi
fi

print_if_not_quiet ""
print_if_not_quiet "${BLUE}Region and quota check complete for: ${REGION}${NC}"

# Show summary of all checks
print_if_not_quiet ""
if [ -n "$MIN_TOTAL_VCPUS" ] && [ "$MIN_TOTAL_VCPUS" -ne $((NODE_COUNT * 2)) ]; then
    print_if_not_quiet "${YELLOW}📋 Summary for ${NODE_COUNT}-node AKS cluster (≥${MIN_TOTAL_VCPUS} total vCPUs required):${NC}"
    print_if_not_quiet "${GREEN}✓ Available with quota (≥${MIN_TOTAL_VCPUS} total vCPUs): ${#QUOTA_OK_SIZES[@]}${NC}"
    print_if_not_quiet "${YELLOW}- Available but insufficient quota: ${#QUOTA_INSUFFICIENT_SIZES[@]}${NC}"
    print_if_not_quiet "${YELLOW}⚠ Available but insufficient total vCPUs: ${#INSUFFICIENT_TOTAL_VCPU_SIZES[@]}${NC}"
    print_if_not_quiet "${RED}✗ Not available in region: ${#UNAVAILABLE_SIZES[@]}${NC}"
else
    print_if_not_quiet "${YELLOW}📋 Summary for ${NODE_COUNT}-node AKS cluster (evaluating all VM SKUs):${NC}"
    print_if_not_quiet "${GREEN}✓ Available with quota: ${#QUOTA_OK_SIZES[@]}${NC}"
    print_if_not_quiet "${YELLOW}- Available but insufficient quota: ${#QUOTA_INSUFFICIENT_SIZES[@]}${NC}"
    print_if_not_quiet "${RED}✗ Not available in region: ${#UNAVAILABLE_SIZES[@]}${NC}"
fi

# Optional: Show quota increase guidance
if [ ${#QUOTA_INSUFFICIENT_SIZES[@]} -gt 0 ] || [ ${#QUOTA_OK_SIZES[@]} -eq 0 ]; then
    print_if_not_quiet ""
    print_if_not_quiet "${YELLOW}💡 To request quota increase:${NC}"
    print_if_not_quiet "${BLUE}1. Go to Azure Portal > Subscriptions > Usage + quotas${NC}"
    print_if_not_quiet "${BLUE}2. Filter by region: ${REGION}${NC}"
    print_if_not_quiet "${BLUE}3. Search for 'vCPUs' quotas${NC}"
    print_if_not_quiet "${BLUE}4. Request increase for needed VM families${NC}"
fi
