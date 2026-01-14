@description('The name of the Container Registry')
param containerRegistryName string

@description('The principal ID to grant access to')
param principalId string

@description('The type of principal (ServicePrincipal or User)')
@allowed(['ServicePrincipal', 'User'])
param principalType string = 'ServicePrincipal'

// Reference to existing Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: containerRegistryName
}

// AcrPull role definition ID
var acrPullRoleId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

// Grant AcrPull role to the principal
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(containerRegistry.id, principalId, acrPullRoleId)
  scope: containerRegistry
  properties: {
    roleDefinitionId: acrPullRoleId
    principalId: principalId
    principalType: principalType
  }
}

output roleAssignmentId string = roleAssignment.id
