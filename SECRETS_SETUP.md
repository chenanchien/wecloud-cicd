# GitHub Secrets Configuration Guide

## Required Secrets for CI/CD Pipeline

### 1. GCP Service Account Key (GCP_SA_KEY)

**Get the service account key:**
```bash
# Get the service account email
gcloud iam service-accounts list

# Create and download the key
gcloud iam service-accounts keys create ~/gcp-sa-key.json \
  --iam-account=<SERVICE_ACCOUNT_EMAIL>

# Copy the entire JSON content
cat ~/gcp-sa-key.json
```

**Add to GitHub:**
- Go to: Repository → Settings → Secrets and variables → Actions
- Click "New repository secret"
- Name: `GCP_SA_KEY`
- Value: Paste the entire JSON content from the file above
- Click "Add secret"

---

### 2. Azure Container Registry (ACR) Secrets

**Get ACR credentials:**
```bash
# Get ACR credentials
az acr credential show --name cmucloudcomputingchenanc

# Get the full registry name
az acr list --query "[].{name:name, loginServer:loginServer}" -o table
```

**Add to GitHub:**

**AZ_CONTAINER_REGISTRY:**
- Name: `AZ_CONTAINER_REGISTRY`
- Value: `cmucloudcomputingchenanc.azurecr.io`

**AZ_REGISTRY_USERNAME:**
- Name: `AZ_REGISTRY_USERNAME`
- Value: `cmucloudcomputingchenanc` (from az acr credential show)

**AZ_REGISTRY_PASSWORD:**
- Name: `AZ_REGISTRY_PASSWORD`
- Value: Copy `password` or `password2` from az acr credential show output

---

### 3. Azure OIDC Authentication Secrets

**Get Azure subscription and tenant IDs:**
```bash
az account show --query "{subscriptionId:id, tenantId:tenantId}" -o json
```

**Create Azure AD App Registration for OIDC:**
```bash
# Create the app registration
az ad app create --display-name "GitHub-Actions-WeCloud"

# Get the app ID
APP_ID=$(az ad app list --display-name "GitHub-Actions-WeCloud" --query "[0].appId" -o tsv)
echo "Client ID: $APP_ID"

# Create a service principal for the app
az ad sp create --id $APP_ID

# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Assign contributor role to the service principal
az role assignment create \
  --role contributor \
  --assignee $APP_ID \
  --scope /subscriptions/$SUBSCRIPTION_ID

# Create federated credentials for GitHub Actions
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-actions-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:<YOUR_GITHUB_USERNAME>/<YOUR_REPO_NAME>:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

**Add to GitHub:**

**AZURE_CLIENT_ID:**
- Name: `AZURE_CLIENT_ID`
- Value: The APP_ID from above

**AZURE_TENANT_ID:**
- Name: `AZURE_TENANT_ID`
- Value: From `az account show` output (tenantId)

**AZURE_SUBSCRIPTION_ID:**
- Name: `AZURE_SUBSCRIPTION_ID`
- Value: From `az account show` output (subscriptionId)

---

## Summary Checklist

Once you have your GitHub repository created, add these 7 secrets:

- [ ] `GCP_SA_KEY` - Service account JSON key
- [ ] `AZ_CONTAINER_REGISTRY` - ACR login server
- [ ] `AZ_REGISTRY_USERNAME` - ACR username
- [ ] `AZ_REGISTRY_PASSWORD` - ACR password
- [ ] `AZURE_CLIENT_ID` - Azure AD app client ID
- [ ] `AZURE_TENANT_ID` - Azure tenant ID
- [ ] `AZURE_SUBSCRIPTION_ID` - Azure subscription ID

---

## Quick Commands Reference

```bash
# GCP Service Account
gcloud iam service-accounts list
gcloud iam service-accounts keys create ~/gcp-sa-key.json --iam-account=<EMAIL>

# Azure Credentials
az acr credential show --name cmucloudcomputingchenanc
az account show --query "{subscriptionId:id, tenantId:tenantId}"

# Azure AD App for OIDC
APP_ID=$(az ad app list --display-name "GitHub-Actions-WeCloud" --query "[0].appId" -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
```

---

## Verification

After adding secrets, you can verify they're set:
1. Go to: Repository → Settings → Secrets and variables → Actions
2. You should see all 7 secrets listed
3. The workflow will use these secrets automatically when triggered
