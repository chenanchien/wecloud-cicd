#!/bin/bash
# Setup script for GCP Service Account with required permissions

set -e

echo "=== GCP Service Account Setup for GitHub Actions ==="
echo ""

PROJECT_ID="gcp-docker-kubernetes-486318"
SA_NAME="github-actions-wecloud"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "Project ID: $PROJECT_ID"
echo "Service Account: $SA_EMAIL"
echo ""

# Check if service account exists
if gcloud iam service-accounts describe $SA_EMAIL &>/dev/null; then
    echo "✓ Service account already exists"
else
    echo "Creating service account..."
    gcloud iam service-accounts create $SA_NAME \
        --display-name "GitHub Actions WeCloud CI/CD" \
        --description "Service account for GitHub Actions CI/CD pipeline"
    echo "✓ Service account created"
fi

# Grant necessary roles
echo ""
echo "Granting IAM roles..."

ROLES=(
    "roles/artifactregistry.writer"
    "roles/container.developer"
    "roles/iam.serviceAccountUser"
)

for ROLE in "${ROLES[@]}"; do
    echo "  Adding role: $ROLE"
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:$SA_EMAIL" \
        --role="$ROLE" \
        --condition=None \
        > /dev/null
done

echo "✓ All roles granted"

# Create key
echo ""
KEY_FILE="$HOME/gcp-sa-key-github-actions.json"

if [ -f "$KEY_FILE" ]; then
    echo "Key file already exists at: $KEY_FILE"
    read -p "Create a new key? (y/n): " CREATE_NEW
    if [ "$CREATE_NEW" != "y" ]; then
        echo "Using existing key file"
    else
        rm "$KEY_FILE"
        echo "Creating new service account key..."
        gcloud iam service-accounts keys create "$KEY_FILE" \
            --iam-account="$SA_EMAIL"
        echo "✓ Key created at: $KEY_FILE"
    fi
else
    echo "Creating service account key..."
    gcloud iam service-accounts keys create "$KEY_FILE" \
        --iam-account="$SA_EMAIL"
    echo "✓ Key created at: $KEY_FILE"
fi

echo ""
echo "=== Setup Complete! ==="
echo ""
echo "Add this secret to your GitHub repository:"
echo "Repository → Settings → Secrets and variables → Actions → New repository secret"
echo ""
echo "Secret Name: GCP_SA_KEY"
echo "Secret Value: Copy the entire content of this file:"
echo ""
echo "cat $KEY_FILE"
echo ""
echo "Then paste it as the secret value."
echo ""
echo "Quick copy command:"
echo "cat $KEY_FILE | pbcopy  # macOS"
echo "cat $KEY_FILE | xclip -selection clipboard  # Linux with xclip"
echo "cat $KEY_FILE  # Manual copy"
