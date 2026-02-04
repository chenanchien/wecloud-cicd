# Task 7 - CI/CD Pipeline Setup Guide

## Quick Start

This repository is ready for GitHub Actions CI/CD. Follow these steps to complete the setup:

### Step 1: Create GitHub Repository

```bash
# Make sure you have GitHub CLI installed and authenticated
gh auth login

# Create the repository (run from task7 directory)
cd /home/clouduser/Project_Containers/task7
gh repo create wecloud-cicd --public --source=. --remote=origin --push
```

Alternatively, create manually:
1. Go to https://github.com/new
2. Repository name: `wecloud-cicd` (or your choice)
3. Make it Public
4. Don't initialize with README (we already have one)
5. Create repository
6. Follow the commands to push existing repository

### Step 2: Configure GitHub Secrets

You need to add 7 secrets to your GitHub repository.

#### 2.1 GCP Service Account Key

**The service account has already been created with these permissions:**
- Artifact Registry Writer
- Kubernetes Engine Developer
- Service Account User

**The key file is located at:** `/home/clouduser/gcp-sa-key-github-actions.json`

**To add to GitHub:**
```bash
# Display the key content
cat /home/clouduser/gcp-sa-key-github-actions.json

# Copy the entire JSON output
```

Then:
1. Go to: `https://github.com/<your-username>/wecloud-cicd/settings/secrets/actions`
2. Click "New repository secret"
3. Name: `GCP_SA_KEY`
4. Value: Paste the entire JSON from above
5. Click "Add secret"

#### 2.2 Azure Container Registry Secrets

Get ACR credentials:
```bash
az acr credential show --name cmucloudcomputingchenanc --query "{username: username, password: passwords[0].value}" -o json
```

Add these 3 secrets:

**AZ_CONTAINER_REGISTRY:**
- Name: `AZ_CONTAINER_REGISTRY`
- Value: `cmucloudcomputingchenanc.azurecr.io`

**AZ_REGISTRY_USERNAME:**
- Name: `AZ_REGISTRY_USERNAME`
- Value: Copy `username` from above command

**AZ_REGISTRY_PASSWORD:**
- Name: `AZ_REGISTRY_PASSWORD`
- Value: Copy `password` from above command

#### 2.3 Azure OIDC Secrets

Run the setup script:
```bash
cd /home/clouduser/Project_Containers/task7
./setup-azure-oidc.sh
```

This will:
1. Ask for your GitHub username and repository name
2. Create an Azure AD app registration
3. Create federated credentials for GitHub Actions
4. Display the secrets you need to add

Add these 3 secrets with the values from the script output:
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`

### Step 3: Push to GitHub and Test

```bash
cd /home/clouduser/Project_Containers/task7

# Add all files
git add .

# Commit
git commit -m "Initial commit - WeCloud CI/CD pipeline"

# Push (if you used gh repo create, origin is already set)
git push -u origin main
```

The workflow will automatically trigger! Check the Actions tab in your repository.

### Step 4: Verify Deployment

After the workflow completes:

```bash
# Check GCP deployments
kubectl config use-context gke_gcp-docker-kubernetes-486318_us-central1-f_wecloudchatcluster
kubectl get pods
kubectl get deployments

# Check Azure deployments
kubectl config use-context MyAKSCluster
kubectl get pods
kubectl get deployments
```

### Step 5: Update meta.json and Submit

```bash
cd /home/clouduser/Project_Containers/task7

# Edit meta.json with your information
nano meta.json
```

Add:
```json
{
    "github_username": "your-github-username",
    "repository": "wecloud-cicd",
    "token": ""
}
```

Then submit:
```bash
./submitter
```

The submitter will generate a token automatically.

---

## Workflow Details

The CI/CD pipeline in [.github/workflows/cicd.yml](.github/workflows/cicd.yml) does:

1. **Detect Changes**: Identifies which services have changed
2. **Build Images**: Builds Docker images for changed services
3. **Push to Registries**: Pushes to both Google Artifact Registry and Azure Container Registry
4. **Deploy to GCP**: Updates GKE cluster with new images
5. **Deploy to Azure**: Updates AKS cluster with new images

### Triggers

- Automatic: Push to `main` branch
- Manual: Workflow dispatch from GitHub Actions tab

---

## Testing the Pipeline

Make a small change to test:

```bash
cd /home/clouduser/Project_Containers/task7

# Make a change to profile service
echo "// Test change" >> profile-service/src/main/java/edu/cmu/ProfileApplication.java

# Commit and push
git add .
git commit -m "Test: trigger CI/CD pipeline"
git push origin main
```

Watch the workflow run in: `https://github.com/<username>/wecloud-cicd/actions`

---

## Troubleshooting

### Workflow fails with "Authentication failed"
- Verify all 7 secrets are correctly set
- Check secret names match exactly (case-sensitive)
- For GCP_SA_KEY, ensure the entire JSON is copied including { }

### Image pull errors in deployment
- Verify service account has GAR read permissions
- Check ACR credentials are correct
- Ensure image names match in values.yaml files

### Helm deployment fails
- Check cluster contexts are correct
- Verify helm charts are valid: `helm lint ./helm`
- Check resource quotas in clusters

### Azure OIDC authentication fails
- Verify federated credential subject matches: `repo:<username>/<repo>:ref:refs/heads/main`
- Check app has contributor role on subscription
- Ensure client ID, tenant ID, and subscription ID are correct

---

## Files Overview

```
task7/
├── .github/workflows/cicd.yml    # Main CI/CD workflow
├── profile-service/              # Profile microservice code
├── login-service/                # Login microservice code
├── chat-service/                 # Chat microservice code
├── helm/                         # Helm charts for deployment
│   ├── templates/                # K8s manifests
│   ├── values-gcp.yaml           # GCP-specific values
│   └── values-azure.yaml         # Azure-specific values
├── setup-gcp-sa.sh               # GCP service account setup
├── setup-azure-oidc.sh           # Azure OIDC setup
├── SECRETS_SETUP.md              # Detailed secrets guide
├── README.md                     # Main documentation
└── meta.json                     # Submission metadata
```

---

## Success Criteria

✅ GitHub repository created and pushed
✅ All 7 secrets configured in GitHub
✅ Workflow runs successfully on push to main
✅ Images built and pushed to both GAR and ACR
✅ Services deployed to both GKE and AKS clusters
✅ meta.json updated with correct information
✅ Task submitted successfully

---

## Quick Command Reference

```bash
# View GCP service account key
cat /home/clouduser/gcp-sa-key-github-actions.json

# Get Azure credentials
az acr credential show --name cmucloudcomputingchenanc
az account show --query "{subscriptionId:id, tenantId:tenantId}"

# Create GitHub repo
gh repo create wecloud-cicd --public --source=. --remote=origin --push

# Check workflow status
gh run list
gh run view --web

# View pods
kubectl get pods --all-namespaces

# Submit task
cd /home/clouduser/Project_Containers/task7
./submitter
```
