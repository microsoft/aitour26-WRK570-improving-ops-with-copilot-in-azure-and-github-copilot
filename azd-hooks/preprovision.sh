#!/bin/bash

SignInName=$(az ad signed-in-user show --query userPrincipalName -o tsv)

az role assignment create --assignee "$SignInName" --role 'Azure Kubernetes Service RBAC Cluster Admin' --scope "/subscriptions/$AZURE_SUBSCRIPTION_ID/resourceGroups/$AZURE_RESOURCE_GROUP"
