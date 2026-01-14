# Azure Infrastructure

This directory contains the Infrastructure as Code (IaC) for deploying ZavaStorefront to Azure.

## Structure

```
infra/
├── main.bicep                          # Main orchestration template
├── main.bicepparam                     # Parameters file
└── modules/
    ├── app-service.bicep              # App Service and App Service Plan
    ├── container-registry.bicep        # Azure Container Registry
    ├── container-registry-access.bicep # RBAC for ACR
    ├── monitoring.bicep                # Log Analytics & Application Insights
    └── ai-foundry.bicep               # Azure AI Services (GPT-4, Phi)
```

## Bicep Modules

### main.bicep
Main entry point that:
- Creates a resource group
- Orchestrates all module deployments
- Configures RBAC between services
- Outputs connection strings and URLs

### app-service.bicep
Provisions:
- Linux App Service Plan (B1 SKU)
- App Service with System-Assigned Managed Identity
- Docker container configuration
- Application settings for monitoring and AI integration

### container-registry.bicep
Provisions:
- Azure Container Registry (Basic SKU)
- Admin user disabled (RBAC only)
- Public network access enabled

### container-registry-access.bicep
Configures:
- AcrPull role assignment
- Grants managed identity access to pull images

### monitoring.bicep
Provisions:
- Log Analytics workspace (30-day retention)
- Application Insights (web application type)

### ai-foundry.bicep
Provisions:
- Azure AI Services multi-service account
- Supports GPT-4 and Phi models
- S0 SKU for production workloads

## Parameters

All parameters are defined in `main.bicepparam`:
- `environmentName`: Name used for resource naming
- `location`: Azure region (default: westus3)
- `principalId`: Optional user principal ID for ACR access

## Outputs

The deployment outputs:
- `AZURE_LOCATION`: Deployment region
- `AZURE_CONTAINER_REGISTRY_ENDPOINT`: ACR login server
- `AZURE_CONTAINER_REGISTRY_NAME`: ACR resource name
- `APPLICATIONINSIGHTS_CONNECTION_STRING`: Monitoring connection string
- `AZURE_APP_SERVICE_NAME`: App Service name
- `AZURE_APP_SERVICE_URL`: Public URL of the application
- `AI_FOUNDRY_ENDPOINT`: Azure AI Services endpoint

## Deployment

Use Azure Developer CLI:
```bash
azd provision
```

Or Azure CLI:
```bash
az deployment sub create \
  --location westus3 \
  --template-file infra/main.bicep \
  --parameters infra/main.bicepparam
```

## Security Features

- **No password-based authentication**: All services use managed identities and RBAC
- **HTTPS only**: App Service enforces HTTPS
- **Minimum TLS 1.2**: Modern encryption standards
- **Admin user disabled**: Container Registry uses RBAC only
