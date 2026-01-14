# GitHub Actions Deployment Configuration

## Required GitHub Secrets

Navigate to **Settings → Secrets and variables → Actions** in your repository.

### Secret: `AZURE_CREDENTIALS`

Create a service principal and store its credentials:

```bash
az ad sp create-for-rbac \
  --name "github-actions-zava-storefront" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/{resource-group} \
  --sdk-auth
```

Copy the entire JSON output and save it as the `AZURE_CREDENTIALS` secret.

## Required GitHub Variables

Navigate to **Settings → Secrets and variables → Actions → Variables** tab.

Create the following repository variables:

| Variable Name | Example Value | How to Find |
|--------------|---------------|-------------|
| `AZURE_RESOURCE_GROUP` | `rg-github-workshop` | Your resource group name from `azd provision` output |
| `AZURE_CONTAINER_REGISTRY_NAME` | `crgithubworkshop` | ACR name from `azd provision` output (no `.azurecr.io`) |
| `AZURE_APP_SERVICE_NAME` | `app-github-workshop` | App Service name from `azd provision` output |

## Quick Setup

After running `azd provision`, get the values:

```bash
# Get resource group
azd env get-values | grep AZURE_RESOURCE_GROUP

# Get ACR name
azd env get-values | grep AZURE_CONTAINER_REGISTRY_NAME

# Get App Service name
azd env get-values | grep AZURE_APP_SERVICE_NAME
```

## Trigger Deployment

The workflow runs automatically on:
- Push to `main` branch
- Manual trigger via **Actions → Build and Deploy to Azure App Service → Run workflow**

## Verify Deployment

After the workflow completes:

```bash
# Get the App Service URL
azd env get-values | grep AZURE_APP_SERVICE_URL
```

Visit the URL to see your deployed application.
