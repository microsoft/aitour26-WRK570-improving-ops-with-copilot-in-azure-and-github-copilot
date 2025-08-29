@minLength(3)
param nameSuffix string
param accountKind string
param identityPrincipalId string = ''
param servicePrincipalId string = ''
param tags object

// https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/document-db/database-account
module databaseAccount 'br/public:avm/res/document-db/database-account:0.15.0' = {
  name: 'databaseAccountDeployment'
  params: {
    name: 'db-${nameSuffix}'
    minimumTlsVersion: 'Tls12'
    serverVersion: '4.2'
    networkRestrictions: {
      publicNetworkAccess: 'Enabled'
      virtualNetworkRules: []
      ipRules: []
    }
    capabilitiesToAdd: accountKind == 'MongoDB'
      ? [
          'EnableMongo'
        ]
      : []
    mongodbDatabases: accountKind == 'MongoDB'
      ? [
          {
            name: 'orderdb'
            throughput: 400
            collections: [
              {
                name: 'orders'
                throughput: 400
                indexes: [
                  {
                    key: {
                      keys: [
                        '_id'
                      ]
                    }
                  }
                ]
                shardKey: {
                  _id: 'Hash'
                }
              }
            ]
          }
        ]
      : []
    zoneRedundant: false
    sqlDatabases: accountKind == 'GlobalDocumentDB'
      ? [
          {
            name: 'orderdb'
            throughput: 400
            containers: [
              {
                name: 'orders'
                paths: [
                  '/storeId'
                ]
              }
            ]
          }
        ]
      : []
    roleAssignments: [
    ]
    tags: tags
  }
}

output id string = databaseAccount.outputs.resourceId
output name string = databaseAccount.outputs.name
