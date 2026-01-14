@description('The name of the Azure AI service')
param name string

@description('The location for the Azure AI service')
param location string

@description('Tags to apply to the Azure AI service')
param tags object = {}

@description('The SKU of the Azure AI service')
@allowed(['S0'])
param sku string = 'S0'

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
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

output endpoint string = aiService.properties.endpoint
output key string = aiService.listKeys().key1
output id string = aiService.id
output name string = aiService.name
