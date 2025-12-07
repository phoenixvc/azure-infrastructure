# GitHub Secrets Setup Guide

This guide explains how to configure the required GitHub secrets for CI/CD workflows.

---

## Required Secrets

The workflows in this repository require the following secrets to be configured in GitHub.

### Azure Authentication

#### AZURE_CREDENTIALS

Service Principal credentials in JSON format for Azure authentication.

**How to create:**

```bash
# Create a service principal
az ad sp create-for-rbac \
  --name "github-actions-azure-infrastructure" \
  --role contributor \
  --scopes /subscriptions/{subscription-id} \
  --sdk-auth

# Output will be JSON like:
{
  "clientId": "<client-id>",
  "clientSecret": "<client-secret>",
  "subscriptionId": "<subscription-id>",
  "tenantId": "<tenant-id>",
  "activeDirectoryEndpointUrl": "https://login.microsoftonline.com",
  "resourceManagerEndpointUrl": "https://management.azure.com/",
  "activeDirectoryGraphResourceId": "https://graph.windows.net/",
  "sqlManagementEndpointUrl": "https://management.core.windows.net:8443/",
  "galleryEndpointUrl": "https://gallery.azure.com/",
  "managementEndpointUrl": "https://management.core.windows.net/"
}
```

**Add to GitHub:**
1. Go to repository -> Settings -> Secrets and variables -> Actions
2. Click "New repository secret"
3. Name: `AZURE_CREDENTIALS`
4. Value: Paste the entire JSON output
5. Click "Add secret"

#### AZURE_SUBSCRIPTION_ID

Your Azure subscription ID.

**How to get:**

```bash
az account show --query id -o tsv
```

**Add to GitHub:**
- Name: `AZURE_SUBSCRIPTION_ID`
- Value: Your subscription ID

#### AZURE_TENANT_ID

Your Azure tenant ID.

**How to get:**

```bash
az account show --query tenantId -o tsv
```

**Add to GitHub:**
- Name: `AZURE_TENANT_ID`
- Value: Your tenant ID

---

## Deployment Secrets

### APP_SERVICE_NAME

The name of your Azure App Service (if deploying applications).

**Add to GitHub:**
- Name: `APP_SERVICE_NAME`
- Value: Your App Service name (e.g., `app-myproject-prod`)

### RESOURCE_GROUP

The name of your Azure Resource Group.

**Add to GitHub:**
- Name: `RESOURCE_GROUP`
- Value: Your resource group name (e.g., `rg-myproject-prod`)

---

## Optional Secrets

### CODECOV_TOKEN

Token for Codecov integration (if using code coverage).

**How to get:**
1. Go to https://codecov.io
2. Add your repository
3. Copy the token

**Add to GitHub:**
- Name: `CODECOV_TOKEN`
- Value: Your Codecov token

---

## Variables (Non-Secret Configuration)

These can be added as **Variables** (not secrets) since they're not sensitive:

### AZURE_LOCATION

**Add to GitHub:**
- Name: `AZURE_LOCATION`
- Value: `westeurope` (or your preferred region)

### ENVIRONMENT

**Add to GitHub:**
- Name: `ENVIRONMENT`
- Value: `dev`, `staging`, or `prod`

---

## Quick Setup Script

Run this script to set up all required secrets:

```bash
#!/bin/bash

# Azure Infrastructure GitHub Secrets Setup

echo "Setting up GitHub secrets for azure-infrastructure..."

# Get Azure credentials
echo "Step 1: Creating Azure Service Principal..."
AZURE_CREDS=$(az ad sp create-for-rbac \
  --name "github-actions-azure-infrastructure" \
  --role contributor \
  --scopes /subscriptions/$(az account show --query id -o tsv) \
  --sdk-auth)

# Get subscription and tenant IDs
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

# Set GitHub secrets using GitHub CLI
echo "Step 2: Adding secrets to GitHub..."

gh secret set AZURE_CREDENTIALS --body "$AZURE_CREDS"
gh secret set AZURE_SUBSCRIPTION_ID --body "$SUBSCRIPTION_ID"
gh secret set AZURE_TENANT_ID --body "$TENANT_ID"

# Prompt for deployment secrets
read -p "Enter App Service name (or press Enter to skip): " APP_SERVICE_NAME
if [ ! -z "$APP_SERVICE_NAME" ]; then
  gh secret set APP_SERVICE_NAME --body "$APP_SERVICE_NAME"
fi

read -p "Enter Resource Group name (or press Enter to skip): " RESOURCE_GROUP
if [ ! -z "$RESOURCE_GROUP" ]; then
  gh secret set RESOURCE_GROUP --body "$RESOURCE_GROUP"
fi

# Set variables
echo "Step 3: Adding variables to GitHub..."
gh variable set AZURE_LOCATION --body "westeurope"
gh variable set ENVIRONMENT --body "dev"

echo "Setup complete!"
echo ""
echo "Summary:"
echo "  - Service Principal created"
echo "  - Secrets added to GitHub"
echo "  - Variables configured"
echo ""
echo "Verify at: https://github.com/phoenixvc/azure-infrastructure/settings/secrets/actions"
```

**To run:**

```bash
# Make executable
chmod +x setup-github-secrets.sh

# Run
./setup-github-secrets.sh
```

---

## Verification

After adding secrets, verify they're configured:

1. Go to repository -> Settings -> Secrets and variables -> Actions
2. Check that all required secrets are listed
3. Run a workflow to test authentication

---

## Security Best Practices

### Service Principal Permissions

- Use least privilege principle
- Limit scope to specific resource groups
- Rotate credentials regularly
- Use separate service principals per environment

### Secret Management

- Never commit secrets to code
- Use GitHub secrets for sensitive data
- Use variables for non-sensitive configuration
- Rotate secrets periodically
- Audit secret access regularly

### Access Control

- Limit who can modify secrets
- Enable branch protection
- Require PR reviews for workflow changes
- Use environment-specific secrets

---

## Rotating Secrets

To rotate the Azure service principal credentials:

```bash
# Reset the service principal credentials
az ad sp credential reset \
  --name "github-actions-azure-infrastructure" \
  --sdk-auth

# Update the AZURE_CREDENTIALS secret in GitHub with the new output
```

---

## Troubleshooting

### "Authentication failed" in workflows

1. Verify service principal exists:
   ```bash
   az ad sp list --display-name "github-actions-azure-infrastructure"
   ```

2. Check service principal has correct permissions:
   ```bash
   az role assignment list --assignee <client-id>
   ```

3. Verify secret format is correct JSON

### "Subscription not found"

- Ensure `AZURE_SUBSCRIPTION_ID` matches your actual subscription
- Verify service principal has access to the subscription

### "Resource group not found"

- Ensure `RESOURCE_GROUP` name is correct
- Verify resource group exists in the specified subscription

---

## Support

For issues with secret setup:
- Email: support@phoenixvc.co.za
- GitHub Issues: https://github.com/phoenixvc/azure-infrastructure/issues

---

<div align="center">

**Built with love by [Phoenix Venture Capital](https://phoenixvc.co.za)**

</div>
