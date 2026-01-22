#!/bin/bash
# Update GitHub Secrets in Application Repository
# This script updates the target repository's secrets with the EC2 instance details

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Update Application Repository Secrets${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ Error: GitHub CLI (gh) is not installed${NC}"
    echo ""
    echo "Install it with:"
    echo "  macOS: brew install gh"
    echo "  Linux: https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
    exit 1
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}❌ Error: Terraform is not installed${NC}"
    exit 1
fi

# Check if user is authenticated with GitHub
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}⚠️  Not authenticated with GitHub${NC}"
    echo "Please run: gh auth login"
    exit 1
fi

# Get target repository from user
if [ -z "$1" ]; then
    echo -e "${YELLOW}Usage: $0 <target-repo> [deploy-path]${NC}"
    echo ""
    echo "Example:"
    echo "  $0 username/k8s-app-repo /home/ubuntu/app"
    echo ""
    read -p "Enter target repository (e.g., username/repo): " TARGET_REPO
else
    TARGET_REPO="$1"
fi

# Get deploy path (optional)
if [ -z "$2" ]; then
    DEPLOY_PATH="/home/ubuntu/app"
    echo -e "${BLUE}ℹ️  Using default deploy path: $DEPLOY_PATH${NC}"
else
    DEPLOY_PATH="$2"
fi

echo ""
echo -e "${BLUE}Target Repository: $TARGET_REPO${NC}"
echo -e "${BLUE}Deploy Path: $DEPLOY_PATH${NC}"
echo ""

# Verify the repository exists and we have access
echo "🔍 Verifying access to target repository..."
if ! gh repo view "$TARGET_REPO" &> /dev/null; then
    echo -e "${RED}❌ Error: Cannot access repository '$TARGET_REPO'${NC}"
    echo "Make sure:"
    echo "  1. The repository name is correct"
    echo "  2. You have admin access to the repository"
    echo "  3. Your GitHub token has 'repo' and 'admin:org' scopes"
    exit 1
fi
echo -e "${GREEN}✅ Repository access verified${NC}"
echo ""

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
    echo "🔧 Initializing Terraform..."
    terraform init -input=false
fi

# Get Terraform outputs
echo "📊 Getting Terraform outputs..."
PUBLIC_IP=$(terraform output -raw instance_public_ip 2>/dev/null)
PRIVATE_KEY_PATH=$(terraform output -raw private_key_path 2>/dev/null)

if [ -z "$PUBLIC_IP" ] || [ -z "$PRIVATE_KEY_PATH" ]; then
    echo -e "${RED}❌ Error: Could not get Terraform outputs${NC}"
    echo "Make sure you have run 'terraform apply' first"
    exit 1
fi

echo -e "${GREEN}✅ EC2 Public IP: $PUBLIC_IP${NC}"
echo -e "${GREEN}✅ Private Key Path: $PRIVATE_KEY_PATH${NC}"
echo ""

# Check if PEM file exists
if [ ! -f "$PRIVATE_KEY_PATH" ]; then
    echo -e "${RED}❌ Error: PEM key file not found at $PRIVATE_KEY_PATH${NC}"
    exit 1
fi

# Read the PEM key
echo "🔑 Reading SSH private key..."
PEM_CONTENT=$(cat "$PRIVATE_KEY_PATH")
echo -e "${GREEN}✅ SSH key read successfully${NC}"
echo ""

# Confirm before updating
echo -e "${YELLOW}⚠️  About to update the following secrets in '$TARGET_REPO':${NC}"
echo "  • EC2_HOST = $PUBLIC_IP"
echo "  • EC2_USER = ubuntu"
echo "  • EC2_SSH_PRIVATE_KEY = [PEM key content]"
echo "  • DEPLOY_PATH = $DEPLOY_PATH"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Update secrets
echo ""
echo "🔄 Updating secrets in $TARGET_REPO..."
echo ""

# EC2_HOST
echo "  Updating EC2_HOST..."
echo "$PUBLIC_IP" | gh secret set EC2_HOST --repo "$TARGET_REPO"
echo -e "${GREEN}  ✅ EC2_HOST updated${NC}"

# EC2_USER
echo "  Updating EC2_USER..."
echo "ubuntu" | gh secret set EC2_USER --repo "$TARGET_REPO"
echo -e "${GREEN}  ✅ EC2_USER updated${NC}"

# EC2_SSH_PRIVATE_KEY
echo "  Updating EC2_SSH_PRIVATE_KEY..."
echo "$PEM_CONTENT" | gh secret set EC2_SSH_PRIVATE_KEY --repo "$TARGET_REPO"
echo -e "${GREEN}  ✅ EC2_SSH_PRIVATE_KEY updated${NC}"

# DEPLOY_PATH
echo "  Updating DEPLOY_PATH..."
echo "$DEPLOY_PATH" | gh secret set DEPLOY_PATH --repo "$TARGET_REPO"
echo -e "${GREEN}  ✅ DEPLOY_PATH updated${NC}"

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  ✅ All secrets updated successfully!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Go to: https://github.com/$TARGET_REPO/settings/secrets/actions"
echo "  2. Verify the secrets are updated"
echo "  3. Trigger your deployment workflow in the application repository"
echo ""
