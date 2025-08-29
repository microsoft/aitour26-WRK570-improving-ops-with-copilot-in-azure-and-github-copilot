@minLength(3)
param nameSuffix string
param servicePrincipalId string = ''
param tags object

// https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/service-bus/namespace
module serviceBusNamespace 'br/public:avm/res/service-bus/namespace:0.13.2' = {
  name: 'namespaceDeployment'
  params: {
    name: 'sb-${nameSuffix}'
    disableLocalAuth: true
    skuObject: {
      name: 'Standard'
    }
    queues: [
      {
        name: 'orders'
      }
    ]
    roleAssignments: [
    ]
    tags: tags
  }
}

output name string = serviceBusNamespace.outputs.name
output id string = serviceBusNamespace.outputs.resourceId
