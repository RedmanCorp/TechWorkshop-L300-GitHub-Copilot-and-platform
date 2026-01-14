@description('The name of the App Service')
param name string

@description('The location for the App Service')
param location string

@description('Tags to apply to the App Service')
param tags object = {}

@description('Application Insights connection string')
param applicationInsightsConnectionString string

@description('Container Registry name')
param containerRegistryName string

@description('AI Foundry endpoint')
param aiFoundryEndpoint string

@description('AI Foundry key')
@secure()
param aiFoundryKey string

@description('The SKU of the App Service Plan')
param sku string = 'B1'

// App Service Plan (Linux)
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'plan-${name}'
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: 'linux'
  properties: {
    reserved: true // Required for Linux
  }
}

// App Service (Web App)
resource appService 'Microsoft.Web/sites@2022-09-01' = {
  name: name
  location: location
  tags: tags
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistryName}.azurecr.io/zava-storefront:latest'
      acrUseManagedIdentityCreds: true // Use managed identity for ACR
      alwaysOn: true
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: applicationInsightsConnectionString
        }
        {
          name: 'ApplicationInsightsAgent_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'XDT_MicrosoftApplicationInsights_Mode'
          value: 'Recommended'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistryName}.azurecr.io'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'AI_FOUNDRY_ENDPOINT'
          value: aiFoundryEndpoint
        }
        {
          name: 'AI_FOUNDRY_KEY'
          value: aiFoundryKey
        }
      ]
    }
  }
}

output name string = appService.name
output uri string = 'https://${appService.properties.defaultHostName}'
output identityPrincipalId string = appService.identity.principalId
output id string = appService.id
