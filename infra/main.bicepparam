using './main.bicep'

param environmentName = readEnvironmentVariable('AZURE_ENV_NAME', 'zava-dev')
param location = readEnvironmentVariable('AZURE_LOCATION', 'westus3')
param principalId = readEnvironmentVariable('AZURE_PRINCIPAL_ID', '')
