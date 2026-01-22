#!/bin/bash
# Upload PEM Key to GitHub Secrets
# This uploads the EC2 SSH private key to THIS repository's secrets
# so the GitHub Actions workflow can use it

set -e

REPO="${1:-}"

echo "============================================"
echo "  Upload PEM Key to GitHub Secrets"
echo "============================================"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ Error: GitHub CLI (gh) is not installed"
    echo ""
    echo "Install it with:"
    echo "  macOS: brew install gh"
    exit 1
fi

# Check authentication
if ! gh auth status &> /dev/null; then
    echo "⚠️  Not authenticated with GitHub"
    echo "Please run: gh auth login"
    exit 1
fi

# Get repository (current if not specified)
if [ -z "$REPO" ]; then
    REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
    if [ -z "$REPO" ]; then
        echo "❌ Error: Could not detect repository"
        echo "Usage: $0 [owner/repo]"
        exit 1
    fi
fi

echo "Repository: $REPO"
echo ""

# Get PEM file path from terraform
echo "📊 Getting PEM key path from Terraform..."
PEM_PATH=$(terraform output -raw private_key_path 2>/dev/null || echo "")

if [ -z "$PEM_PATH" ]; then
    echo "❌ Error: Could not get PEM key path from terraform"
    echo "Make sure you've run 'terraform apply' first"
    exit 1
fi

if [ ! -f "$PEM_PATH" ]; then
    echo "❌ Error: PEM file not found at: $PEM_PATH"
    exit 1
fi

echo "✅ Found PEM key: $PEM_PATH"
echo ""

# Read PEM content
PEM_CONTENT=$(cat "$PEM_PATH")

echo "🔑 Uploading EC2_SSH_PRIVATE_KEY to $REPO..."
echo "$PEM_CONTENT" | gh secret set EC2_SSH_PRIVATE_KEY --repo "$REPO"
echo "✅ EC2_SSH_PRIVATE_KEY uploaded successfully"
echo ""

echo "============================================"
echo "  ✅ Setup Complete!"
echo "============================================"
echo ""
echo "The PEM key is now stored securely in GitHub Secrets."
echo ""
echo "Next steps:"
echo "  1. Go to: https://github.com/$REPO/actions"
echo "  2. Run the 'Update Application Repository Secrets' workflow"
echo "  3. Enter your target repository name"
echo ""
