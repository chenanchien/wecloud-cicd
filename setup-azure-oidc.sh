#!/bin/bash
# Setup script for Azure OIDC GitHub Actions integration

set -e

echo "=== Azure OIDC Setup for GitHub Actions ==="
echo ""

# Get GitHub repo info
echo "Please provide your GitHub information:"
read -p "GitHub Username: " GITHUB_USERNAME
read -p "Repository Name: " REPO_NAME

echo ""
echo "Creating Azure AD App Registration..."

# Create app registration
APP_NAME="GitHub-Actions-WeCloud-${GITHUB_USERNAME}"
APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)

if [ -z "$APP_ID" ]; then
    echo "Error: Failed to create app registration"
    exit 1
fi

echo "✓ App created with Client ID: $APP_ID"

# Create service principal
echo "Creating service principal..."
az ad sp create --id $APP_ID > /dev/null
echo "✓ Service principal created"

# Get subscription info
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo "✓ Subscription ID: $SUBSCRIPTION_ID"
echo "✓ Tenant ID: $TENANT_ID"

# Assign contributor role
echo "Assigning contributor role..."
az role assignment create \
  --role contributor \
  --assignee $APP_ID \
  --scope /subscriptions/$SUBSCRIPTION_ID \
  > /dev/null

echo "✓ Contributor role assigned"

# Create federated credential for main branch
echo "Creating federated credential for main branch..."

FEDERATED_CRED=$(cat <<EOF
{
  "name": "github-actions-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:${GITHUB_USERNAME}/${REPO_NAME}:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"],
  "description": "GitHub Actions for main branch"
}
EOF
)

echo "$FEDERATED_CRED" | az ad app federated-credential create --id $APP_ID --parameters @- > /dev/null
echo "✓ Federated credential created"

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Add these secrets to your GitHub repository:"
echo "Repository → Settings → Secrets and variables → Actions → New repository secret"
echo ""
echo "AZURE_CLIENT_ID: $APP_ID"
echo "AZURE_TENANT_ID: $TENANT_ID"
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"
echo ""
echo "Also add these ACR secrets:"
az acr credential show --name cmucloudcomputingchenanc --query "{AZ_CONTAINER_REGISTRY: loginServer, AZ_REGISTRY_USERNAME: username, AZ_REGISTRY_PASSWORD: passwords[0].value}" -o json
echo ""
echo "Don't forget to add GCP_SA_KEY as well!"
