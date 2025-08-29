@minLength(3)
param nameSuffix string
param location string
param servicePrincipalId string = ''
param modelDeployments array = []
param tags object

// https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/cognitive-services/account
module cognitiveServicesAccount 'br/public:avm/res/cognitive-services/account:0.10.1' = {
  name: 'accountDeployment'
  params: {
    name: 'aoai-${nameSuffix}'
    customSubDomainName: 'aoai-${nameSuffix}'
    location: location
    kind: 'OpenAI'
    sku: 'S0'
    deployments: [
      for model in modelDeployments: {
        name: model.name
        model: {
          name: model.name
          format: 'OpenAI'
          version: model.version
        }
        sku: {
          name: 'Standard'
          capacity: model.capacity
        }
      }
    ]
    disableLocalAuth: true
    publicNetworkAccess: 'Enabled'
    roleAssignments: [

    ]
    tags: tags
  }
}

output endpoint string = cognitiveServicesAccount.outputs.endpoint
output id string = cognitiveServicesAccount.outputs.resourceId
