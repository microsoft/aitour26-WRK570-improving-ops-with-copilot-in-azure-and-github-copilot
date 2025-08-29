#!/usr/bin/env pwsh

az role assignment create --assignee $env:AZURE_IDENTITY_PRINCIPAL_ID --role 'DocumentDB Account Contributor' --scope $env:AZURE_COSMOS_DATABASE_ID
az role assignment create --assignee $env:AZURE_IDENTITY_PRINCIPAL_ID --role 'Cognitive Services OpenAI User' --scope $env:AZURE_OPENAI_ID
az role assignment create --assignee $env:AZURE_IDENTITY_PRINCIPAL_ID --role 'Azure Service Bus Data Owner' --scope $env:AZURE_SERVICE_BUS_ID

$SignInName = "$(az ad signed-in-user show --query userPrincipalName -o tsv)"

az role assignment create --assignee $SignInName --role 'DocumentDB Account Contributor' --scope $env:AZURE_COSMOS_DATABASE_ID
az role assignment create --assignee $SignInName --role 'Cognitive Services OpenAI User' --scope $env:AZURE_OPENAI_ID
az role assignment create --assignee $SignInName --role 'Azure Service Bus Data Owner' --scope $env:AZURE_SERVICE_BUS_ID
