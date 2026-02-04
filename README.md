# WeCloud Multi-Cloud Kubernetes CI/CD

This repository contains the CI/CD pipeline for deploying WeCloud microservices to Google Kubernetes Engine (GKE) and Azure Kubernetes Service (AKS).

## Architecture

### Services
- **profile-service**: User profile management (deployed to both GCP and Azure)
- **login-service**: User authentication (deployed to both GCP and Azure)
- **chat-service**: Group chat functionality (deployed to GCP only)

### Infrastructure
- **GCP**: GKE cluster in us-central1-f
- **Azure**: AKS cluster in eastus
- **Container Registries**: 
  - Google Artifact Registry (GAR)
  - Azure Container Registry (ACR)

## CI/CD Pipeline

The GitHub Actions workflow (`/.github/workflows/cicd.yml`) automates:

1. **Change Detection**: Detects changes in service code or Helm charts
2. **Build**: Builds Docker images for modified services
3. **Push**: Pushes images to both GAR and ACR
4. **Deploy**: Deploys updated services to GKE and AKS using Helm

### Workflow Triggers
- Push to `main` branch
- Manual workflow dispatch

## Setup Instructions

### Prerequisites
1. GCP project with GKE cluster and GAR
2. Azure subscription with AKS cluster and ACR
3. GitHub repository

### Required GitHub Secrets

#### GCP Secrets
- `GCP_SA_KEY`: Service account JSON key with permissions:
  - Artifact Registry Writer
  - Kubernetes Engine Developer
  - Service Account User

#### Azure Secrets
- `AZ_CONTAINER_REGISTRY`: ACR login server (e.g., `registry.azurecr.io`)
- `AZ_REGISTRY_USERNAME`: ACR username
- `AZ_REGISTRY_PASSWORD`: ACR password
- `AZURE_CLIENT_ID`: Azure AD application client ID
- `AZURE_TENANT_ID`: Azure AD tenant ID
- `AZURE_SUBSCRIPTION_ID`: Azure subscription ID

### Deployment

The pipeline automatically deploys on code changes:

```bash
# Make changes to service code
git add .
git commit -m "Update service"
git push origin main
```

### Manual Deployment

Trigger manually from GitHub Actions tab or:

```bash
gh workflow run cicd.yml
```

## Project Structure

```
.
├── .github/
│   └── workflows/
│       └── cicd.yml          # CI/CD pipeline definition
├── profile-service/          # Profile microservice
├── login-service/            # Login microservice
├── chat-service/             # Chat microservice
├── helm/                     # Helm charts
│   ├── templates/            # Kubernetes manifests
│   ├── values-gcp.yaml       # GCP-specific values
│   └── values-azure.yaml     # Azure-specific values
└── README.md                 # This file
```

## Monitoring

View deployment status:
- GitHub Actions tab in repository
- `kubectl get pods` on respective clusters

## Troubleshooting

### Image Pull Errors
Ensure:
- Service account has GAR/ACR read permissions
- Kubernetes secrets are correctly configured
- Image tags match deployed versions

### Helm Deployment Failures
Check:
- Values files (values-gcp.yaml, values-azure.yaml)
- Resource quotas in clusters
- Network policies and ingress configuration

## License

CMU Cloud Computing Course Project
