targetScope = 'subscription'

@description('Short environment name used in resource names and tags.')
@minLength(2)
@maxLength(12)
param environmentName string = 'workshop'

@description('Azure region for all workshop resources.')
param location string = 'eastus2'

@description('Resource group that contains the workshop resources.')
param resourceGroupName string = 'rg-adb-workshop'

var suffix = take(uniqueString(subscription().id, resourceGroupName), 6)
var tags = {
  workload: 'azure-databricks-workshop'
  environment: 'training'
  'managed-by': 'azd'
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module foundation './modules/foundation.bicep' = {
  name: 'foundation-${environmentName}'
  scope: resourceGroup
  params: {
    location: location
    suffix: suffix
    tags: tags
  }
}

module databricks './modules/databricks.bicep' = {
  name: 'databricks-${environmentName}'
  scope: resourceGroup
  params: {
    location: location
    suffix: suffix
    tags: tags
    storageAccountName: foundation.outputs.storageAccountName
    keyVaultName: foundation.outputs.keyVaultName
    eventHubsNamespaceName: foundation.outputs.eventHubsNamespaceName
    logAnalyticsWorkspaceId: foundation.outputs.logAnalyticsWorkspaceId
  }
}

module cosmos './modules/cosmos.bicep' = {
  name: 'cosmos-${environmentName}'
  scope: resourceGroup
  params: {
    location: location
    suffix: suffix
    tags: tags
    logAnalyticsWorkspaceId: foundation.outputs.logAnalyticsWorkspaceId
    databricksPrincipalId: databricks.outputs.accessConnectorPrincipalId
  }
}

output resourceGroupName string = resourceGroup.name
output databricksWorkspaceName string = databricks.outputs.workspaceName
output databricksWorkspaceUrl string = databricks.outputs.workspaceUrl
output accessConnectorId string = databricks.outputs.accessConnectorId
output storageAccountName string = foundation.outputs.storageAccountName
output keyVaultName string = foundation.outputs.keyVaultName
output eventHubsNamespaceName string = foundation.outputs.eventHubsNamespaceName
output eventHubName string = foundation.outputs.eventHubName
output logAnalyticsWorkspaceName string = foundation.outputs.logAnalyticsWorkspaceName
output cosmosAccountName string = cosmos.outputs.accountName
output cosmosEndpoint string = cosmos.outputs.endpoint
output cosmosDatabaseName string = cosmos.outputs.databaseName
output cosmosContainerName string = cosmos.outputs.containerName
