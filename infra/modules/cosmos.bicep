@description('Azure region for Cosmos DB resources.')
param location string

@description('Stable suffix generated from subscription and resource group.')
param suffix string

@description('Common governance tags.')
param tags object

@description('Log Analytics workspace resource ID for diagnostics.')
param logAnalyticsWorkspaceId string

@description('Databricks access connector managed identity principal ID.')
param databricksPrincipalId string

var accountName = 'cosmos-adbws-${suffix}'
var databaseName = 'energy-serving'
var containerName = 'predictions'
var dataContributorRoleId = '00000000-0000-0000-0000-000000000002'
var containerScope = '${resourceGroup().id}/providers/Microsoft.DocumentDB/databaseAccounts/${accountName}/dbs/${databaseName}/colls/${containerName}'

module cosmosAccount 'br/public:avm/res/document-db/database-account:0.21.0' = {
  name: 'cosmos-serving'
  params: {
    name: accountName
    location: location
    tags: tags
    capacityMode: 'Serverless'
    defaultConsistencyLevel: 'Session'
    disableLocalAuthentication: true
    enableBurstCapacity: false
    networkRestrictions: {
      publicNetworkAccess: 'Enabled'
      networkAclBypass: 'AzureServices'
      ipRules: []
      virtualNetworkRules: []
    }
    sqlDatabases: [
      {
        name: databaseName
        containers: [
          {
            name: containerName
            paths: [
              '/countryCode'
            ]
            indexingPolicy: {
              automatic: true
              indexingMode: 'consistent'
              includedPaths: [
                {
                  path: '/*'
                }
              ]
              excludedPaths: [
                {
                  path: '/features/*'
                }
              ]
            }
          }
        ]
      }
    ]
    sqlRoleAssignments: [
      {
        principalId: databricksPrincipalId
        roleDefinitionId: dataContributorRoleId
        scope: containerScope
      }
    ]
    diagnosticSettings: [
      {
        name: 'send-to-log-analytics'
        workspaceResourceId: logAnalyticsWorkspaceId
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
          }
        ]
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
      }
    ]
    zoneRedundant: false
  }
}

output accountName string = cosmosAccount.outputs.name
output endpoint string = cosmosAccount.outputs.endpoint
output databaseName string = databaseName
output containerName string = containerName
