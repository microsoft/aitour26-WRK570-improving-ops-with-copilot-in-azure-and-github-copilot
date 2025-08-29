#!/usr/bin/env pwsh

$SignInName = "$(az ad signed-in-user show --query userPrincipalName -o tsv)"

az role assignment create --assignee $SignInName --role 'Azure Kubernetes Service RBAC Cluster Admin' --scope "/subscriptions/$env:AZURE_SUBSCRIPTION_ID/resourceGroups/$env:AZURE_RESOURCE_GROUP"
