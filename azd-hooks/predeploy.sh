#!/bin/bash

##########################################################
# Check kubelogin and install if not exists
##########################################################
if ! command -v kubelogin &> /dev/null; then
  az aks install-cli
fi

###########################################################
# Create the custom-values.yaml file
###########################################################
cat > custom-values.yaml << EOF
namespace: ${AZURE_AKS_NAMESPACE}
EOF

###########################################################
# Set Company Name
###########################################################
if [ -n "$COMPANY_NAME" ]; then
cat >> custom-values.yaml << EOF
companyName: $COMPANY_NAME
EOF
fi

###########################################################
# Add Azure Managed Identity and set to use AzureAD auth 
###########################################################
if [ -n "$AZURE_IDENTITY_CLIENT_ID" ] && [ -n "$AZURE_IDENTITY_NAME" ]; then
cat >> custom-values.yaml << EOF
useAzureAd: true
managedIdentityName: $AZURE_IDENTITY_NAME
managedIdentityClientId: $AZURE_IDENTITY_CLIENT_ID
EOF
fi

###########################################################
# Add base images
###########################################################
cat >> custom-values.yaml << EOF
productService:
  image:
    repository: ${AZURE_REGISTRY_URI}/aks-store-demo/product-service
storeAdmin:
  image:
    repository: ${AZURE_REGISTRY_URI}/aks-store-demo/store-admin
storeFront:
  image:
    repository: ${AZURE_REGISTRY_URI}/aks-store-demo/store-front
virtualCustomer:
  image:
    repository: ${AZURE_REGISTRY_URI}/aks-store-demo/virtual-customer
virtualWorker:
  image:
    repository: ${AZURE_REGISTRY_URI}/aks-store-demo/virtual-worker
EOF

###########################################################
# Add ai-service if Azure OpenAI endpoint is provided
###########################################################
if [ -n "$AZURE_OPENAI_ENDPOINT" ]; then
cat >> custom-values.yaml << EOF
aiService:
  image:
    repository: ${AZURE_REGISTRY_URI}/aks-store-demo/ai-service
  create: true
  modelDeploymentName: ${AZURE_OPENAI_MODEL_NAME}
  openAiEndpoint: ${AZURE_OPENAI_ENDPOINT}
  useAzureOpenAi: true
EOF
fi

###########################################################
# Add order-service
###########################################################
cat >> custom-values.yaml << EOF
orderService:
  image:
    repository: ${AZURE_REGISTRY_URI}/aks-store-demo/order-service
EOF

# Add Azure Service Bus to order-service if provided
if [ -n "$AZURE_SERVICE_BUS_HOST" ]; then
cat >> custom-values.yaml << EOF
  queueHost: ${AZURE_SERVICE_BUS_HOST}
EOF
fi

###########################################################
# Add makeline-service
###########################################################
cat >> custom-values.yaml << EOF
makelineService:
  image:
    repository: ${AZURE_REGISTRY_URI}/aks-store-demo/makeline-service
EOF

# Add Azure Service Bus to makeline-service if provided
if [ -n "$AZURE_SERVICE_BUS_URI" ]; then
  # If Azure identity exists just set the Azure Service Bus Hostname
  if [ -n "$AZURE_IDENTITY_CLIENT_ID" ] && [ -n "$AZURE_IDENTITY_NAME" ]; then
    cat >> custom-values.yaml << EOF
  orderQueueHost: $AZURE_SERVICE_BUS_HOST
EOF
  fi
fi

# Add Azure Cosmos DB to makeline-service if provided
if [ -n "$AZURE_COSMOS_DATABASE_URI" ]; then
  cat >> custom-values.yaml << EOF
  orderDBApi: ${AZURE_DATABASE_API}
  orderDBUri: ${AZURE_COSMOS_DATABASE_URI}
  orderDBListConnectionStringsUrl: ${AZURE_COSMOS_DATABASE_LIST_CONNECTIONSTRINGS_URL}
EOF
fi

###########################################################
# Do not deploy RabbitMQ when using Azure Service Bus
###########################################################
if [ -n "$AZURE_SERVICE_BUS_HOST" ]; then
  cat >> custom-values.yaml << EOF
useRabbitMQ: false
EOF
fi

###########################################################
# Do not deploy MongoDB when using Azure Cosmos DB
###########################################################
if [ -n "$AZURE_COSMOS_DATABASE_URI" ]; then
  cat >> custom-values.yaml << EOF
useMongoDB: false
EOF
fi
