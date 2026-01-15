targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Id of the principal to grant access to the Container Registry')
param principalId string = ''

// Tags that should be applied to all resources
var tags = {
  'azd-env-name': environmentName
  environment: 'dev'
}

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}'
  location: location
  tags: tags
}

// Container Registry
module containerRegistry './modules/container-registry.bicep' = {
  name: 'container-registry'
  scope: rg
  params: {
    name: 'cr${replace(environmentName, '-', '')}'
    location: location
    tags: tags
  }
}

// Application Insights
module monitoring './modules/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: 'log-${environmentName}'
    applicationInsightsName: 'appi-${environmentName}'
  }
}

// Azure AI Foundry (formerly Cognitive Services)
module aiFoundry './modules/ai-foundry.bicep' = {
  name: 'ai-foundry'
  scope: rg
  params: {
    name: 'ai-${environmentName}'
    location: location
    tags: tags
    logAnalyticsWorkspaceId: monitoring.outputs.logAnalyticsWorkspaceId
  }
}

// App Service Plan and Web App
module appService './modules/app-service.bicep' = {
  name: 'app-service'
  scope: rg
  params: {
    name: 'app-${environmentName}'
    location: location
    tags: tags
    applicationInsightsConnectionString: monitoring.outputs.applicationInsightsConnectionString
    containerRegistryName: containerRegistry.outputs.name
    aiFoundryEndpoint: aiFoundry.outputs.endpoint
  }
}

// RBAC: Grant App Service managed identity access to pull from Container Registry
module containerRegistryAccess './modules/container-registry-access.bicep' = {
  name: 'container-registry-access'
  scope: rg
  params: {
    containerRegistryName: containerRegistry.outputs.name
    principalId: appService.outputs.identityPrincipalId
  }
}

// Grant user access to Container Registry for pushing images
module userContainerRegistryAccess './modules/container-registry-access.bicep' = if (!empty(principalId)) {
  name: 'user-container-registry-access'
  scope: rg
  params: {
    containerRegistryName: containerRegistry.outputs.name
    principalId: principalId
    principalType: 'User'
  }
}

// Outputs
output AZURE_LOCATION string = location
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.outputs.loginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.outputs.name
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output AZURE_APP_SERVICE_NAME string = appService.outputs.name
output AZURE_APP_SERVICE_URL string = appService.outputs.uri
output AI_FOUNDRY_ENDPOINT string = aiFoundry.outputs.endpoint
