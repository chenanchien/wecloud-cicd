#!/bin/bash
# This script must be run by an Azure AD admin with sufficient privileges

APP_ID=$(az ad app create --display-name "GitHub-Actions-WeCloud" --query appId -o tsv)
echo "Created Azure AD App with Client ID: $APP_ID"

az ad app federated-credential create --id $APP_ID --parameters '{
  "name": "GitHubActions",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:chenanchien/wecloud-cicd:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'
echo "Created federated credential"

az role assignment create --assignee $APP_ID --role Contributor --scope /subscriptions/060d2236-e023-4fbb-9c58-36f405e5dfba/resourceGroups/MyMultiCloudRG
echo "Assigned Contributor role"

echo ""
echo "==================================="
echo "AZURE_CLIENT_ID to add to GitHub Secrets: $APP_ID"
echo "==================================="
