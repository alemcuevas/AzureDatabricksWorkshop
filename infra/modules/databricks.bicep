@description('Azure region for Databricks resources.')
param location string

@description('Stable suffix generated from subscription and resource group.')
param suffix string

@description('Common governance tags.')
param tags object

param storageAccountName string
param keyVaultName string
param eventHubsNamespaceName string
param logAnalyticsWorkspaceId string

var workspaceName = 'dbw-adbws-${suffix}'
var accessConnectorName = 'ac-adbws-${suffix}'
var managedResourceGroupName = 'rg-${workspaceName}-managed'
var storageBlobDataContributorRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
var keyVaultSecretsUserRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
var eventHubsDataOwnerRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'f526a384-b230-433a-b45c-95f59c4a2dec')

resource storage 'Microsoft.Storage/storageAccounts@2025-01-01' existing = {
  name: storageAccountName
}

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' existing = {
  name: keyVaultName
}

resource eventHubsNamespace 'Microsoft.EventHub/namespaces@2024-01-01' existing = {
  name: eventHubsNamespaceName
}

resource accessConnector 'Microsoft.Databricks/accessConnectors@2024-05-01' = {
  name: accessConnectorName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
}

resource workspace 'Microsoft.Databricks/workspaces@2024-05-01' = {
  name: workspaceName
  location: location
  tags: tags
  sku: {
    name: 'premium'
  }
  properties: {
    managedResourceGroupId: subscriptionResourceId('Microsoft.Resources/resourceGroups', managedResourceGroupName)
    parameters: {
      enableNoPublicIp: {
        value: true
      }
    }
  }
}

resource storageRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storage.id, accessConnector.id, storageBlobDataContributorRoleId)
  scope: storage
  properties: {
    principalId: accessConnector.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: storageBlobDataContributorRoleId
  }
}

resource keyVaultRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, accessConnector.id, keyVaultSecretsUserRoleId)
  scope: keyVault
  properties: {
    principalId: accessConnector.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: keyVaultSecretsUserRoleId
  }
}

resource eventHubsRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(eventHubsNamespace.id, accessConnector.id, eventHubsDataOwnerRoleId)
  scope: eventHubsNamespace
  properties: {
    principalId: accessConnector.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: eventHubsDataOwnerRoleId
  }
}

resource workspaceDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'send-to-log-analytics'
  scope: workspace
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}

output workspaceName string = workspace.name
output workspaceUrl string = 'https://${workspace.properties.workspaceUrl}'
output accessConnectorId string = accessConnector.id
output accessConnectorPrincipalId string = accessConnector.identity.principalId
