#!/bin/bash

az role assignment create --assignee "$AZURE_IDENTITY_PRINCIPAL_ID" --role 'DocumentDB Account Contributor' --scope "$AZURE_COSMOS_DATABASE_ID"
az role assignment create --assignee "$AZURE_IDENTITY_PRINCIPAL_ID" --role 'Cognitive Services OpenAI User' --scope "$AZURE_OPENAI_ID"
az role assignment create --assignee "$AZURE_IDENTITY_PRINCIPAL_ID" --role 'Azure Service Bus Data Owner' --scope "$AZURE_SERVICE_BUS_ID"

SignInName=$(az ad signed-in-user show --query userPrincipalName -o tsv)

az role assignment create --assignee "$SignInName" --role 'DocumentDB Account Contributor' --scope "$AZURE_COSMOS_DATABASE_ID"
az role assignment create --assignee "$SignInName" --role 'Cognitive Services OpenAI User' --scope "$AZURE_OPENAI_ID"
az role assignment create --assignee "$SignInName" --role 'Azure Service Bus Data Owner' --scope "$AZURE_SERVICE_BUS_ID"
