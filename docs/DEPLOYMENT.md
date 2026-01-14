# ZavaStorefront - Azure Infrastructure Deployment Guide

## Overview
This project deploys the ZavaStorefront web application to Azure using Azure Developer CLI (azd) and Bicep Infrastructure as Code. The infrastructure is configured for a **development environment** in the **westus3** region.

## Architecture

The deployment includes:
- **Azure App Service (Linux)**: Hosts the containerized ASP.NET Core web application
- **Azure Container Registry**: Stores Docker container images with RBAC-based authentication
- **Application Insights**: End-to-end monitoring and telemetry
- **Azure AI Services**: GPT-4 and Phi model integration (Microsoft Foundry)
- **Managed Identity**: Secure, password-free authentication between services

## Prerequisites

Before deploying, ensure you have:

1. **Azure Developer CLI (azd)**: [Install azd](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd)
2. **Azure CLI**: [Install az CLI](https://learn.microsoft.com/cli/azure/install-azure-cli)
3. **An Azure subscription** with permissions to create resources
4. **No local Docker installation required** - the build happens in Azure

## Deployment Steps

### 1. Initialize the Environment

```bash
# Login to Azure
azd auth login

# Initialize the azd environment
azd init
```

When prompted:
- **Environment name**: Choose a name (e.g., `zava-dev`)
- **Location**: Select `westus3`

### 2. Provision Infrastructure

```bash
# Provision all Azure resources
azd provision
```

This command will:
- Create a resource group named `rg-<environment-name>`
- Deploy all infrastructure defined in `infra/main.bicep`
- Configure RBAC permissions for the App Service managed identity
- Set up Application Insights monitoring
- Deploy Azure AI Services for GPT-4 and Phi

### 3. Deploy the Application

```bash
# Build the Docker image in Azure and deploy to App Service
azd deploy
```

This command will:
- Build the Docker container using Azure Container Registry's build service (no local Docker needed)
- Push the image to Azure Container Registry
- Update App Service to use the new container image
- App Service will pull the image using its managed identity (no passwords)

### 4. Access Your Application

After deployment completes, run:

```bash
azd show
```

Look for the `AZURE_APP_SERVICE_URL` output to get your application URL.

Alternatively, check the outputs:
```bash
az deployment sub show --name <environment-name> --query properties.outputs
```

## One-Command Deployment

For first-time setup, you can combine everything:

```bash
azd up
```

This runs `azd provision` + `azd deploy` in sequence.

## Infrastructure Details

### Resource Naming Convention
All resources follow the pattern: `<type>-<environment-name>`
- Resource Group: `rg-zava-dev`
- App Service: `app-zava-dev`
- Container Registry: `crzavadev` (hyphens removed due to naming restrictions)
- Log Analytics: `log-zava-dev`
- Application Insights: `appi-zava-dev`
- AI Service: `ai-zava-dev`

### RBAC Configuration
The infrastructure uses **Role-Based Access Control** instead of passwords:
- App Service uses a **System-Assigned Managed Identity**
- The managed identity is granted the **AcrPull** role on the Container Registry
- App Service configuration sets `acrUseManagedIdentityCreds: true`

### Application Settings
The following environment variables are automatically configured in App Service:
- `APPLICATIONINSIGHTS_CONNECTION_STRING`: For Application Insights telemetry
- `AI_FOUNDRY_ENDPOINT`: Endpoint for Azure AI Services
- `AI_FOUNDRY_KEY`: API key for Azure AI Services
- `DOCKER_REGISTRY_SERVER_URL`: Container Registry URL

### Container Configuration
- Base image: `mcr.microsoft.com/dotnet/aspnet:6.0`
- Build image: `mcr.microsoft.com/dotnet/sdk:6.0`
- Multi-stage build for optimized image size
- Exposes ports 80 (HTTP) and 443 (HTTPS)

## Monitoring

### Application Insights
Access Application Insights in the Azure Portal to view:
- Request performance and failures
- Dependency tracking
- Custom telemetry
- Live metrics

### App Service Logs
View logs using:
```bash
az webapp log tail --name app-<environment-name> --resource-group rg-<environment-name>
```

Or in the Azure Portal: App Service → Monitoring → Log stream

## Development Workflow

### Local Development
The application can run locally without Azure resources:
```bash
cd src
dotnet run
```

### Update and Redeploy
After making code changes:
```bash
azd deploy
```

### Update Infrastructure
After modifying Bicep files:
```bash
azd provision
```

## Environment Variables

The following environment variables can be set before running `azd` commands:

- `AZURE_ENV_NAME`: Name of your environment (default: `zava-dev`)
- `AZURE_LOCATION`: Azure region (default: `westus3`)
- `AZURE_PRINCIPAL_ID`: Your user principal ID for ACR access (optional, auto-detected)

## Cleanup

To delete all Azure resources:

```bash
azd down
```

This will remove:
- The resource group and all contained resources
- All infrastructure costs will stop

## Troubleshooting

### Issue: Container fails to pull
**Solution**: Verify the App Service managed identity has the AcrPull role:
```bash
az role assignment list --scope /subscriptions/<sub-id>/resourceGroups/rg-<env>/providers/Microsoft.ContainerRegistry/registries/cr<env>
```

### Issue: Application Insights not showing data
**Solution**: Verify the connection string is set:
```bash
az webapp config appsettings list --name app-<env> --resource-group rg-<env> --query "[?name=='APPLICATIONINSIGHTS_CONNECTION_STRING']"
```

### Issue: AI Services not working
**Solution**: Verify the AI service is in westus3 and check the endpoint configuration:
```bash
az cognitiveservices account show --name ai-<env> --resource-group rg-<env>
```

## Additional Resources

- [Azure Developer CLI Documentation](https://learn.microsoft.com/azure/developer/azure-developer-cli/)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [App Service Docker Containers](https://learn.microsoft.com/azure/app-service/configure-custom-container)
- [Azure Container Registry Authentication](https://learn.microsoft.com/azure/container-registry/container-registry-authentication-managed-identity)
- [Application Insights for ASP.NET Core](https://learn.microsoft.com/azure/azure-monitor/app/asp-net-core)

## Support

For issues or questions, please create an issue in the repository.
