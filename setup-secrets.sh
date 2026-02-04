#!/bin/bash

# Task 7 GitHub Secrets Setup Script
# This script helps configure GitHub secrets for the CI/CD pipeline

set -e

echo "==========================================="
echo "Task 7: GitHub Secrets Setup Helper Script"
echo "==========================================="
echo ""

# Check if gh CLI is authenticated
if ! gh auth status &>/dev/null; then
    echo "❌ GitHub CLI is not authenticated."
    echo "Please run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is authenticated"
echo ""

# Get repository information
read -p "Enter your GitHub username: " GITHUB_USERNAME
REPO_NAME="containers-devops"
REPO_FULL="${GITHUB_USERNAME}/${REPO_NAME}"

echo ""
echo "Repository: $REPO_FULL"
echo ""

# Function to set secret
set_secret() {
    local secret_name=$1
    local secret_description=$2
    local secret_value=$3
    
    echo "Setting secret: $secret_name"
    echo "Description: $secret_description"
    
    if [ -z "$secret_value" ]; then
        read -sp "Enter value for $secret_name: " secret_value
        echo ""
    fi
    
    if [ -n "$secret_value" ]; then
        echo "$secret_value" | gh secret set "$secret_name" --repo "$REPO_FULL"
        echo "✅ $secret_name set successfully"
    else
        echo "⚠️  Skipping $secret_name (no value provided)"
    fi
    echo ""
}

echo "================================================"
echo "Step 1: Azure Container Registry Secrets"
echo "================================================"
echo ""
echo "Get these values from Azure Portal:"
echo "Navigate to: Container registries → Your ACR → Settings → Access keys"
echo "Enable 'Admin user' to see username and password"
echo ""

set_secret "AZ_CONTAINER_REGISTRY" "ACR login server (e.g., yourname.azurecr.io)" ""
set_secret "AZ_REGISTRY_USERNAME" "ACR username from Access keys" ""
set_secret "AZ_REGISTRY_PASSWORD" "ACR password from Access keys" ""

echo "================================================"
echo "Step 2: Azure OIDC Secrets"
echo "================================================"
echo ""
echo "These values come from the managed identity you created."
echo "Run: az identity list -g MyMultiCloudRG"
echo ""

set_secret "AZURE_CLIENT_ID" "Client ID from managed identity" ""
set_secret "AZURE_TENANT_ID" "Tenant ID from managed identity" ""
set_secret "AZURE_SUBSCRIPTION_ID" "Your Azure subscription ID" ""

echo "================================================"
echo "Step 3: GCP Service Account Key"
echo "================================================"
echo ""
echo "If you haven't created a service account key yet, run:"
echo ""
echo "export GKE_PROJECT=\"gcp-docker-kubernetes-486318\""
echo "export SA_NAME=\"github-actions-sa\""
echo "export SA_EMAIL=\"\${SA_NAME}@\${GKE_PROJECT}.iam.gserviceaccount.com\""
echo ""
echo "# Create service account"
echo "gcloud iam service-accounts create \$SA_NAME --display-name \"GitHub Actions Service Account\" --project \$GKE_PROJECT"
echo ""
echo "# Grant roles"
echo "gcloud projects add-iam-policy-binding \$GKE_PROJECT --member=serviceAccount:\$SA_EMAIL --role=roles/container.developer"
echo "gcloud projects add-iam-policy-binding \$GKE_PROJECT --member=serviceAccount:\$SA_EMAIL --role=roles/artifactregistry.admin"
echo "gcloud projects add-iam-policy-binding \$GKE_PROJECT --member=serviceAccount:\$SA_EMAIL --role=roles/storage.admin"
echo ""
echo "# Create key"
echo "gcloud iam service-accounts keys create key.json --iam-account=\$SA_EMAIL --project=\$GKE_PROJECT"
echo ""

if [ -f "key.json" ]; then
    echo "Found key.json file in current directory"
    read -p "Use this file for GCP_SA_KEY secret? (y/n): " use_key_file
    if [ "$use_key_file" = "y" ]; then
        gh secret set GCP_SA_KEY --repo "$REPO_FULL" < key.json
        echo "✅ GCP_SA_KEY set successfully from key.json"
        echo ""
        read -p "Delete key.json file now? (y/n): " delete_key
        if [ "$delete_key" = "y" ]; then
            rm key.json
            echo "✅ key.json deleted"
        fi
    fi
else
    echo "No key.json found. After creating it, run:"
    echo "gh secret set GCP_SA_KEY --repo $REPO_FULL < key.json"
fi

echo ""
echo "================================================"
echo "Verification: Listing all secrets"
echo "================================================"
echo ""

gh secret list --repo "$REPO_FULL"

echo ""
echo "================================================"
echo "Required Secrets Checklist:"
echo "================================================"
echo "1. AZ_CONTAINER_REGISTRY"
echo "2. AZ_REGISTRY_USERNAME"
echo "3. AZ_REGISTRY_PASSWORD"
echo "4. AZURE_CLIENT_ID"
echo "5. AZURE_SUBSCRIPTION_ID"
echo "6. AZURE_TENANT_ID"
echo "7. GCP_SA_KEY"
echo ""
echo "Ensure all 7 secrets are set before running the pipeline."
echo "================================================"
