@description('The name of the Azure AI service')
param name string

@description('The location for the Azure AI service')
param location string

@description('Tags to apply to the Azure AI service')
param tags object = {}

@description('The SKU of the Azure AI service')
@allowed(['S0'])
param sku string = 'S0'

@description('Log Analytics workspace ID for diagnostic settings')
param logAnalyticsWorkspaceId string

// Azure AI services (formerly Cognitive Services) for GPT-4 and Phi models
resource aiService 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: 'AIServices' // Multi-service resource type that supports multiple AI capabilities
  sku: {
    name: sku
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true // Disable API key authentication - enforce Microsoft Entra ID only
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

// Diagnostic settings for AI Foundry
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${name}-diagnostics'
  scope: aiService
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'Audit'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'RequestResponse'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'Trace'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
}

output endpoint string = aiService.properties.endpoint
output id string = aiService.id
output name string = aiService.name
