# Task 7: CI/CD Pipeline Setup Instructions

## Prerequisites Completed ✓
- CI/CD workflow file (`cicd.yml`) has been fully configured
- All TODOs in the workflow file have been completed

## Step-by-Step Setup Guide

### 1. GitHub Authentication (If not already done)
```bash
cd /home/clouduser/Project_Containers/task7
gh auth login
```
- Choose **GitHub.com**
- Select **SSH** as preferred protocol
- Say **Yes** to generate a new SSH key
- Authenticate via web browser

### 2. Git Configuration
```bash
# Configure your Git user information
git config --global user.email "your-email@example.com"
git config --global user.name "your-username"
```

### 3. Initialize Git Repository
```bash
# Initialize the repository
git init -b main

# Copy microservices from task5
cp -r ../task5/Ingress ../task5/helm ../task5/profile-service ../task5/login-service .
cp -r ../task5/group-chat-service chat-service

# Initial commit and push
git add . && git commit -m "initial commit"
gh repo create containers-devops --source=. --private --push
```

### 4. Configure GitHub Secrets

#### Azure Secrets Setup
1. Get ACR credentials from Azure Portal:
   - Navigate to Container registries → Your ACR
   - Go to Settings → Access keys
   - Enable "Admin user"
   - Copy Username and Password

2. Set Azure secrets:
```bash
# Replace <repo-owner> with your GitHub username
gh secret set AZ_CONTAINER_REGISTRY --repo <repo-owner>/containers-devops
# Enter: cmucloudcomputingchenanc.azurecr.io

gh secret set AZ_REGISTRY_USERNAME --repo <repo-owner>/containers-devops
# Enter: Username from ACR

gh secret set AZ_REGISTRY_PASSWORD --repo <repo-owner>/containers-devops
# Enter: Password from ACR
```

#### Azure OIDC Setup
3. Create User-Assigned Managed Identity:
```bash
export RESOURCE_GROUP="MyMultiCloudRG"
export USER_ASSIGNED_IDENTITY_NAME="github-actions-identity"

# Create identity
az identity create -g $RESOURCE_GROUP -n $USER_ASSIGNED_IDENTITY_NAME --tags project=containers

# Get principal ID
export PRINCIPAL_ID=$(az identity show --name $USER_ASSIGNED_IDENTITY_NAME --resource-group $RESOURCE_GROUP --query 'principalId' --output tsv)

# Assign Contributor role
export SUBSCRIPTION_ID="your-subscription-id"
az role assignment create --assignee $PRINCIPAL_ID --role "Contributor" --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP
```

4. Configure Federated Identity Credential:
```bash
export GITHUB_USERNAME="your-github-username"
export GITHUB_REPO="containers-devops"
export BRANCH_NAME="main"
export CREDENTIAL_NAME="github-actions-federated-credential"

az identity federated-credential create --name $CREDENTIAL_NAME \
  --identity-name $USER_ASSIGNED_IDENTITY_NAME \
  --resource-group $RESOURCE_GROUP \
  --issuer "https://token.actions.githubusercontent.com" \
  --subject "repo:${GITHUB_USERNAME}/${GITHUB_REPO}:ref:refs/heads/${BRANCH_NAME}" \
  --audiences "api://AzureADTokenExchange"
```

5. Get and set Azure OIDC secrets:
```bash
# Get client ID and tenant ID
az identity list -g $RESOURCE_GROUP

# Set secrets
gh secret set AZURE_CLIENT_ID --repo <repo-owner>/containers-devops
# Enter: Client ID from above command

gh secret set AZURE_TENANT_ID --repo <repo-owner>/containers-devops
# Enter: Tenant ID from above command

gh secret set AZURE_SUBSCRIPTION_ID --repo <repo-owner>/containers-devops
# Enter: Your subscription ID
```

#### GCP Secrets Setup
6. Create GCP Service Account and Key:
```bash
export GKE_PROJECT="gcp-docker-kubernetes-486318"
export SA_NAME="github-actions-sa"
export SA_EMAIL="${SA_NAME}@${GKE_PROJECT}.iam.gserviceaccount.com"

# Create service account
gcloud iam service-accounts create $SA_NAME \
  --display-name "GitHub Actions Service Account" \
  --project $GKE_PROJECT

# Grant necessary roles
gcloud projects add-iam-policy-binding $GKE_PROJECT \
  --member=serviceAccount:$SA_EMAIL \
  --role=roles/container.developer

gcloud projects add-iam-policy-binding $GKE_PROJECT \
  --member=serviceAccount:$SA_EMAIL \
  --role=roles/artifactregistry.admin

gcloud projects add-iam-policy-binding $GKE_PROJECT \
  --member=serviceAccount:$SA_EMAIL \
  --role=roles/storage.admin

# Create and download key
gcloud iam service-accounts keys create key.json \
  --iam-account=$SA_EMAIL \
  --project=$GKE_PROJECT

# Set secret (paste entire contents of key.json)
gh secret set GCP_SA_KEY --repo <repo-owner>/containers-devops < key.json

# IMPORTANT: Delete the key file after setting secret
rm key.json
```

### 5. Verify All Secrets Are Set
```bash
gh secret list --repo <repo-owner>/containers-devops
```

You should see all 7 secrets:
- AZ_CONTAINER_REGISTRY
- AZ_REGISTRY_USERNAME
- AZ_REGISTRY_PASSWORD
- AZURE_CLIENT_ID
- AZURE_SUBSCRIPTION_ID
- AZURE_TENANT_ID
- GCP_SA_KEY

### 6. Update meta.json
Edit the `meta.json` file with your information:
```json
{
    "github_username": "your-github-username",
    "repository": "containers-devops",
    "token": "your-github-personal-access-token"
}
```

To create a personal access token:
1. Go to GitHub Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. Click "Generate new token"
3. Set token name and expiration
4. For repository access, select "Only select repositories" and choose `containers-devops`
5. Set permissions:
   - Actions: Read and Write
   - Contents: Read
   - Metadata: Read
6. Generate and copy the token

### 7. Test the Pipeline

#### Test 1: Helm Configuration Changes
```bash
# Modify helm values to trigger deployment
sed -i 's/replicaCount: 3/replicaCount: 2/g' helm/values.yaml
git add helm/values.yaml
git commit -m "Update replica count"
git push
```
Check GitHub Actions tab - should skip build-push-image and run deploy jobs.

#### Test 2: Source Code Changes (Optional)
```bash
# Make a simple change to a service
echo '// CI/CD Test' >> profile-service/src/main/java/com/wecloud/profile/ProfileServiceApplication.java
git add profile-service/
git commit -m "Test CI/CD pipeline with code change"
git push
```
Check GitHub Actions tab - should run all jobs including build-push-image.

### 8. Monitor Workflow Execution
1. Go to your GitHub repository
2. Click the "Actions" tab
3. Watch the workflow execution
4. Verify all jobs complete successfully

### 9. Validate Deployments

#### Verify GKE Deployment:
```bash
# Switch to GKE context
kubectl config use-context gke_gcp-docker-kubernetes-486318_us-central1-f_wecloudchatcluster

# Check deployments
kubectl get deployments
kubectl describe deployment spring-profile
kubectl describe deployment spring-login
kubectl describe deployment spring-chat

# Verify image tags match commit SHA
kubectl get deployment spring-profile -o jsonpath='{.spec.template.spec.containers[0].image}'
```

#### Verify AKS Deployment:
```bash
# Switch to AKS context
kubectl config use-context MyAKSCluster

# Check deployments
kubectl get deployments
kubectl describe deployment spring-profile
kubectl describe deployment spring-login

# Verify image tags match commit SHA
kubectl get deployment spring-profile -o jsonpath='{.spec.template.spec.containers[0].image}'
```

### 10. Submit Your Work
```bash
cd /home/clouduser/Project_Containers
./task7/submitter
```

## Troubleshooting

### Issue: Permission denied (publickey)
**Solution:** Generate and add new SSH key:
```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
# Copy the output and add to GitHub Settings → SSH and GPG keys
```

### Issue: Docker build fails in GitHub Actions
**Solution:** Check the build logs in GitHub Actions, ensure Dockerfiles exist in correct locations

### Issue: GCP authentication fails
**Solution:** 
- Verify GCP_SA_KEY secret contains valid JSON
- Check service account has necessary permissions
- Ensure Artifact Registry API is enabled

### Issue: Azure authentication fails
**Solution:**
- Verify federated credential is properly configured
- Check client-id, tenant-id, and subscription-id are correct
- Ensure managed identity has Contributor role

### Issue: Helm deployment fails
**Solution:**
- Verify Kubernetes context is correct
- Check values files have correct structure
- Ensure images exist in registries

### Issue: Zero score on Build Push Image
**Solution:** Ensure you're using the exact GitHub Actions we specified:
- `google-github-actions/auth@v2`
- `docker/login-action@v3`
- `google-github-actions/setup-gcloud@v2`
- `google-github-actions/get-gke-credentials@v2`
- `azure/docker-login@v1`
- `azure/login@v1`
- `azure/aks-set-context@v3`

## Configuration Summary

The completed CI/CD pipeline includes:

✅ **Environment Variables:**
- GCP_CLUSTER_NAME: wecloudchatcluster
- GCP_PROJECT_ID: gcp-docker-kubernetes-486318
- GCP_REGION: us-central1-f
- AZ_CONTAINER_REGISTRY: cmucloudcomputingchenanc.azurecr.io
- AZ_CLUSTER_NAME: MyAKSCluster
- AZ_RESOURCE_GROUP: MyMultiCloudRG
- DOCKER_TAG: ${{ github.sha }}

✅ **Job 1:** Detects file changes in profile-service, login-service, chat-service, and helm

✅ **Job 2:** Builds and pushes Docker images with Git commit SHA tags to:
- Google Artifact Registry (GAR)
- Azure Container Registry (ACR)

✅ **Job 3:** Deploys to GKE cluster using helm upgrade --install

✅ **Job 4:** Deploys to AKS cluster using helm upgrade --install

✅ **Docker Image Tagging:** Uses Git commit hash (${{ github.sha }})

✅ **Automated Updates:** sed commands update image tags in values files

Good luck with your submission!
