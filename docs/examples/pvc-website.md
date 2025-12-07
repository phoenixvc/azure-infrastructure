# Example: Phoenix VC Website

Static website implementation for Phoenix VC using Azure Static Web Apps.

---

## Project Details

- **Organization:** pvc (Phoenix VC)
- **Project:** website
- **Environments:** staging, prod
- **Primary Region:** euw (West Europe)
- **Framework:** React + TypeScript + Vite

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Azure Subscription                       │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Resource Group: pvc-prod-website-rg-euw               │ │
│  │                                                          │ │
│  │  ┌──────────────────────────────────────┐              │ │
│  │  │  Static Web App                      │              │ │
│  │  │  - React Frontend                    │              │ │
│  │  │  - GitHub CI/CD                      │              │ │
│  │  │  - Custom Domain                     │              │ │
│  │  │  - SSL Certificate (auto)            │              │ │
│  │  └──────────────────────────────────────┘              │ │
│  │                                                          │ │
│  │  ┌──────────────┐  ┌──────────────┐                    │ │
│  │  │  Storage     │  │  Log         │                    │ │
│  │  │  Account     │  │  Analytics   │                    │ │
│  │  └──────────────┘  └──────────────┘                    │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## Resource Naming

| Resource | Name |
|----------|------|
| Resource Group | `pvc-prod-website-rg-euw` |
| Static Web App | `pvc-prod-website-swa-euw` |
| Storage Account | `pvcprodwebsitestorageeuw` |
| Log Analytics | `pvc-prod-website-log-euw` |

---

## Deployment

### **1. Create GitHub Token**

```bash
# Create GitHub PAT with 'repo' scope
# Store in Key Vault
az keyvault secret set \
--vault-name pvc-prod-website-kv-euw \
--name github-token \
--value "ghp_xxxxxxxxxxxx"
```

### **2. Deploy Infrastructure**

```bash
# Get GitHub token from Key Vault
GITHUB_TOKEN=$(az keyvault secret show \
--vault-name pvc-prod-website-kv-euw \
--name github-token \
--query value -o tsv)

# Deploy
az deployment sub create \
--location westeurope \
--template-file infra/examples/pvc-website.bicep \
--parameters githubToken="$GITHUB_TOKEN"
```

### **3. Configure Custom Domain**

```bash
# Add custom domain
az staticwebapp hostname set \
--name pvc-prod-website-swa-euw \
--hostname www.phoenixvc.com

# SSL certificate is automatically provisioned
```

---

## Frontend Setup

### **Create React App**

```bash
# Create project
npm create vite@latest website -- --template react-ts
cd website

# Install dependencies
npm install

# Add SWA configuration
cat > public/staticwebapp.config.json << 'EOF'
{
"navigationFallback": {
  "rewrite": "/index.html",
  "exclude": ["/images/*.{png,jpg,gif}", "/css/*"]
},
"routes": [
  {
    "route": "/*",
    "headers": {
      "cache-control": "public, max-age=31536000, immutable"
    }
  }
],
"globalHeaders": {
  "content-security-policy": "default-src 'self'; img-src 'self' data: https:; script-src 'self' 'unsafe-inline';"
}
}
EOF
```

### **Environment Variables**

Create `.env.production`:

```bash
VITE_API_URL=https://api.phoenixvc.com
VITE_SITE_NAME=Phoenix VC
```

---

## GitHub Actions

Azure Static Web Apps automatically creates a GitHub Actions workflow on first deployment.

Example workflow (`.github/workflows/azure-static-web-apps.yml`):

```yaml
name: Deploy Static Web App

on:
push:
  branches:
    - main
pull_request:
  types: [opened, synchronize, reopened, closed]
  branches:
    - main

jobs:
build_and_deploy:
  if: github.event_name == 'push' || (github.event_name == 'pull_request' && github.event.action != 'closed')
  runs-on: ubuntu-latest
  name: Build and Deploy
  steps:
    - uses: actions/checkout@v4
      with:
        submodules: true
    
    - name: Build And Deploy
      uses: Azure/static-web-apps-deploy@v1
      with:
        azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
        repo_token: ${{ secrets.GITHUB_TOKEN }}
        action: "upload"
        app_location: "/"
        api_location: ""
        output_location: "dist"
```

---

## Local Development

```bash
# Install dependencies
npm install

# Start dev server
npm run dev

# Open http://localhost:5173
```

---

## Testing

```bash
# Install testing libraries
npm install -D @testing-library/react @testing-library/jest-dom vitest

# Run tests
npm test
```

---

## Monitoring

- **Application Insights** - Integrated with Static Web App
- **Log Analytics** - Centralized logging
- **Azure Monitor** - Traffic and performance metrics

---

## Features

- ✅ Automatic HTTPS with custom domain
- ✅ Global CDN distribution
- ✅ GitHub-based CI/CD
- ✅ Preview environments for PRs
- ✅ Built-in authentication (optional)
- ✅ API backend support (Azure Functions)

---

## Related Resources

- [Infrastructure Code](../../infra/examples/pvc-website.bicep)
- [Static Web App Module](../../infra/modules/static-web-app/)
- [Web Template](../../src/web/)
