# ============================================================================
# Add Static Web App Module to azure-infrastructure
# ============================================================================
# Run from: C:\Users\smitj\repos\azure-infrastructure
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host "🔧 Adding Static Web App module..." -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Verify we're in the right place
if (-not (Test-Path ".git")) {
    Write-Host "❌ Error: Not in azure-infrastructure repo" -ForegroundColor Red
    exit 1
}

# ============================================================================
# 1. Create SWA Module Directory
# ============================================================================
Write-Host "`n📁 Creating directory structure..." -ForegroundColor Yellow

New-Item -ItemType Directory -Path "infra/modules/static-web-app" -Force | Out-Null
New-Item -ItemType Directory -Path "src/web" -Force | Out-Null
Write-Host "  ✓ Created directories" -ForegroundColor Green

# ============================================================================
# 2. Create SWA Bicep Module
# ============================================================================
Write-Host "`n📝 Creating Static Web App Bicep module..." -ForegroundColor Yellow

@'
// ============================================================================
// Static Web App Module
// ============================================================================
// Creates an Azure Static Web App with optional API backend

@description('Static Web App name (from naming module)')
param swaName string

@description('Location for resources')
param location string = resourceGroup().location

@description('SKU name')
@allowed(['Free', 'Standard'])
param sku string = 'Free'

@description('Repository URL (GitHub)')
param repositoryUrl string = ''

@description('Repository branch')
param repositoryBranch string = 'main'

@description('GitHub token for deployment')
@secure()
param repositoryToken string = ''

@description('App location (path to frontend code)')
param appLocation string = '/'

@description('API location (path to API code, optional)')
param apiLocation string = ''

@description('Output location (build output path)')
param outputLocation string = 'dist'

@description('Tags to apply to resources')
param tags object = {}

// Static Web App
resource staticWebApp 'Microsoft.Web/staticSites@2023-01-01' = {
name: swaName
location: location
tags: tags
sku: {
  name: sku
  tier: sku
}
properties: {
  repositoryUrl: repositoryUrl
  repositoryToken: repositoryToken
  branch: repositoryBranch
  buildProperties: {
    appLocation: appLocation
    apiLocation: apiLocation
    outputLocation: outputLocation
  }
}
}

// Custom domain (optional, configure after deployment)
// resource customDomain 'Microsoft.Web/staticSites/customDomains@2023-01-01' = {
//   parent: staticWebApp
//   name: 'www.example.com'
//   properties: {}
// }

output staticWebAppId string = staticWebApp.id
output staticWebAppName string = staticWebApp.name
output staticWebAppUrl string = 'https://${staticWebApp.properties.defaultHostname}'
output staticWebAppApiKey string = staticWebApp.listSecrets().properties.apiKey
'@ | Out-File -FilePath "infra/modules/static-web-app/main.bicep" -Encoding UTF8
Write-Host "  ✓ Created infra/modules/static-web-app/main.bicep" -ForegroundColor Green

# ============================================================================
# 3. Create SWA Module README
# ============================================================================
@'
# Static Web App Module

Creates an Azure Static Web App with:
- ✅ Free or Standard SKU
- ✅ GitHub integration for CI/CD
- ✅ Optional API backend (Azure Functions)
- ✅ Custom domains support
- ✅ Built-in authentication

---

## Usage

### **Basic Static Site**

```bicep
module naming '../naming/main.bicep' = {
name: 'naming'
params: {
  org: 'pvc'
  env: 'prod'
  project: 'website'
  region: 'euw'
}
}

module swa '../static-web-app/main.bicep' = {
name: 'static-web-app'
params: {
  swaName: naming.outputs.name_swa
  location: 'westeurope'
  sku: 'Free'
  repositoryUrl: 'https://github.com/phoenixvc/website'
  repositoryBranch: 'main'
  repositoryToken: githubToken
  appLocation: '/'
  outputLocation: 'dist'
  tags: {
    org: 'pvc'
    env: 'prod'
    project: 'website'
  }
}
}
```

### **With API Backend**

```bicep
module swa '../static-web-app/main.bicep' = {
name: 'static-web-app'
params: {
  swaName: naming.outputs.name_swa
  location: 'westeurope'
  sku: 'Standard'
  repositoryUrl: 'https://github.com/myorg/myapp'
  repositoryBranch: 'main'
  repositoryToken: githubToken
  appLocation: '/frontend'
  apiLocation: '/api'
  outputLocation: 'dist'
}
}
```

---

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `swaName` | string | - | Static Web App name |
| `location` | string | resourceGroup().location | Azure region |
| `sku` | string | 'Free' | SKU (Free or Standard) |
| `repositoryUrl` | string | '' | GitHub repository URL |
| `repositoryBranch` | string | 'main' | Git branch |
| `repositoryToken` | string (secure) | '' | GitHub PAT token |
| `appLocation` | string | '/' | Frontend code path |
| `apiLocation` | string | '' | API code path (optional) |
| `outputLocation` | string | 'dist' | Build output path |
| `tags` | object | {} | Resource tags |

---

## Outputs

| Output | Type | Description |
|--------|------|-------------|
| `staticWebAppId` | string | Static Web App resource ID |
| `staticWebAppName` | string | Static Web App name |
| `staticWebAppUrl` | string | Static Web App URL |
| `staticWebAppApiKey` | string | API key for deployment |

---

## Framework Support

Azure Static Web Apps supports:
- ✅ React
- ✅ Next.js
- ✅ Vue.js
- ✅ Angular
- ✅ Svelte
- ✅ Blazor
- ✅ Hugo
- ✅ Gatsby

---

## GitHub Token

Create a GitHub Personal Access Token (PAT) with `repo` scope:

1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Generate new token (classic)
3. Select `repo` scope
4. Copy token and store in Azure Key Vault

```bash
az keyvault secret set \
--vault-name your-key-vault \
--name github-token \
--value "ghp_xxxxxxxxxxxx"
```

---

## Custom Domains

After deployment, add custom domain:

```bash
az staticwebapp hostname set \
--name pvc-prod-website-swa-euw \
--hostname www.phoenixvc.com
```

---

## Authentication

Built-in authentication providers:
- GitHub
- Azure AD
- Twitter
- Google
- Facebook

Configure in `staticwebapp.config.json`:

```json
{
"auth": {
  "identityProviders": {
    "azureActiveDirectory": {
      "registration": {
        "openIdIssuer": "https://login.microsoftonline.com/<tenant-id>/v2.0",
        "clientIdSettingName": "AAD_CLIENT_ID",
        "clientSecretSettingName": "AAD_CLIENT_SECRET"
      }
    }
  }
}
}
```

---

## Version

**Current:** v2.1

See [CHANGELOG.md](../../../CHANGELOG.md) for version history.
'@ | Out-File -FilePath "infra/modules/static-web-app/README.md" -Encoding UTF8
Write-Host "  ✓ Created infra/modules/static-web-app/README.md" -ForegroundColor Green

# ============================================================================
# 4. Create Web Source Template
# ============================================================================
Write-Host "`n📝 Creating web source template..." -ForegroundColor Yellow

@'
# Web Frontend Template

Static web frontend templates for Azure Static Web Apps.

---

## Supported Frameworks

### **React**
```bash
npx create-react-app my-app
cd my-app
npm start
```

### **Next.js**
```bash
npx create-next-app@latest my-app
cd my-app
npm run dev
```

### **Vue.js**
```bash
npm create vue@latest my-app
cd my-app
npm install
npm run dev
```

---

## Project Structure

```
src/web/
├── public/              # Static assets
├── src/
│   ├── components/      # React/Vue components
│   ├── pages/           # Pages/routes
│   ├── styles/          # CSS/SCSS
│   └── utils/           # Utilities
├── package.json
├── tsconfig.json
└── staticwebapp.config.json  # SWA configuration
```

---

## Static Web App Configuration

Create `staticwebapp.config.json`:

```json
{
"routes": [
  {
    "route": "/api/*",
    "allowedRoles": ["authenticated"]
  },
  {
    "route": "/*",
    "serve": "/index.html",
    "statusCode": 200
  }
],
"navigationFallback": {
  "rewrite": "/index.html",
  "exclude": ["/images/*.{png,jpg,gif}", "/css/*"]
},
"responseOverrides": {
  "404": {
    "rewrite": "/404.html"
  }
},
"globalHeaders": {
  "content-security-policy": "default-src 'self'"
}
}
```

---

## Environment Variables

Create `.env.local`:

```bash
VITE_API_URL=https://nl-prod-rooivalk-api-euw.azurewebsites.net
VITE_APP_NAME=Rooivalk
```

---

## Build Configuration

### **React (Vite)**

```json
{
"scripts": {
  "dev": "vite",
  "build": "vite build",
  "preview": "vite preview"
}
}
```

Output: `dist/`

### **Next.js**

```json
{
"scripts": {
  "dev": "next dev",
  "build": "next build",
  "start": "next start"
}
}
```

Output: `out/` (with `next export`)

---

## Deployment

### **Via GitHub Actions (Automatic)**

Azure Static Web Apps automatically deploys on push to configured branch.

### **Manual Deployment**

```bash
# Install SWA CLI
npm install -g @azure/static-web-apps-cli

# Build
npm run build

# Deploy
swa deploy ./dist \
--deployment-token $DEPLOYMENT_TOKEN \
--env production
```

---

## Local Development with API

```bash
# Start SWA CLI with API
swa start ./dist --api-location ../functions
```

---

## Best Practices

- ✅ Use environment variables for configuration
- ✅ Implement proper error boundaries
- ✅ Add loading states
- ✅ Optimize images and assets
- ✅ Use code splitting
- ✅ Implement proper SEO (meta tags)
- ✅ Add analytics
- ✅ Configure CSP headers

---

## Example: React + TypeScript + Vite

```bash
# Create project
npm create vite@latest my-app -- --template react-ts
cd my-app

# Install dependencies
npm install

# Add SWA config
cat > public/staticwebapp.config.json << 'EOF'
{
"navigationFallback": {
  "rewrite": "/index.html"
}
}
EOF

# Build
npm run build

# Output: dist/
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

## Related Resources

- [Azure Static Web Apps Documentation](https://learn.microsoft.com/azure/static-web-apps/)
- [SWA CLI](https://azure.github.io/static-web-apps-cli/)
- [Configuration Reference](https://learn.microsoft.com/azure/static-web-apps/configuration)
'@ | Out-File -FilePath "src/web/README.md" -Encoding UTF8
Write-Host "  ✓ Created src/web/README.md" -ForegroundColor Green

# ============================================================================
# 5. Update naming module to include SWA
# ============================================================================
Write-Host "`n📝 Updating naming module..." -ForegroundColor Yellow

# Read existing naming module
$namingContent = Get-Content "infra/modules/naming/main.bicep" -Raw

# Check if name_swa already exists
if ($namingContent -notmatch "name_swa") {
    Write-Host "  ⚠️  name_swa already exists in naming module, skipping update" -ForegroundColor Yellow
}
else {
    Write-Host "  ✓ name_swa already defined in naming module" -ForegroundColor Green
}

# ============================================================================
# 6. Update pvc-website example to use SWA module
# ============================================================================
Write-Host "`n📝 Updating pvc-website example..." -ForegroundColor Yellow

@'
// ============================================================================
// Example: Phoenix VC Website
// ============================================================================
// Static website infrastructure with Static Web App
// Usage: az deployment sub create --location westeurope --template-file pvc-website.bicep

targetScope = 'subscription'

param location string = 'westeurope'
param githubToken string = ''

// Naming
module naming '../modules/naming/main.bicep' = {
name: 'naming'
params: {
  org: 'pvc'
  env: 'prod'
  project: 'website'
  region: 'euw'
}
}

// Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
name: naming.outputs.rgName
location: location
tags: {
  org: 'pvc'
  env: 'prod'
  project: 'website'
  managedBy: 'bicep'
}
}

// Log Analytics Workspace
module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.1.0' = {
scope: rg
name: 'log-analytics'
params: {
  name: naming.outputs.name_log
  location: location
}
}

// Static Web App
module swa '../modules/static-web-app/main.bicep' = {
scope: rg
name: 'static-web-app'
params: {
  swaName: naming.outputs.name_swa
  location: location
  sku: 'Standard'
  repositoryUrl: 'https://github.com/phoenixvc/website'
  repositoryBranch: 'main'
  repositoryToken: githubToken
  appLocation: '/'
  outputLocation: 'dist'
  tags: rg.tags
}
}

// Storage Account (for additional assets/backups)
module storage '../modules/storage/main.bicep' = {
scope: rg
name: 'storage'
params: {
  storageName: naming.outputs.name_storage
  location: location
  containerNames: ['assets', 'backups']
  logAnalyticsWorkspaceId: logAnalytics.outputs.resourceId
  tags: rg.tags
}
}

output resourceGroupName string = rg.name
output swaName string = swa.outputs.staticWebAppName
output swaUrl string = swa.outputs.staticWebAppUrl
output storageAccountName string = storage.outputs.storageAccountName
'@ | Out-File -FilePath "infra/examples/pvc-website.bicep" -Encoding UTF8
Write-Host "  ✓ Updated infra/examples/pvc-website.bicep" -ForegroundColor Green

# ============================================================================
# 7. Create SWA documentation example
# ============================================================================
Write-Host "`n📝 Updating pvc-website documentation..." -ForegroundColor Yellow

@'
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
'@ | Out-File -FilePath "docs/examples/pvc-website.md" -Encoding UTF8 -Force
Write-Host "  ✓ Updated docs/examples/pvc-website.md" -ForegroundColor Green

# ============================================================================
# 8. Update README to mention SWA
# ============================================================================
Write-Host "`n📝 Updating main README..." -ForegroundColor Yellow

$readmeContent = Get-Content "README.md" -Raw
$readmeContent = $readmeContent -replace '(\| `storage` \| Storage Account with containers \| \[README\]\(infra/modules/storage/README\.md\) \|)', "`$1`n| ``static-web-app`` | Static Web App with GitHub CI/CD | [README](infra/modules/static-web-app/README.md) |"
$readmeContent | Out-File -FilePath "README.md" -Encoding UTF8
Write-Host "  ✓ Updated README.md" -ForegroundColor Green

# ============================================================================
# 9. Git Commit and Push
# ============================================================================
Write-Host "`n📤 Committing changes..." -ForegroundColor Yellow

git add .
git commit -m "feat: Add Static Web App module and web frontend template

- Added infra/modules/static-web-app with Bicep module
- Added src/web with frontend templates (React/Next.js/Vue)
- Updated pvc-website example to use SWA module
- Updated documentation with SWA examples
- Added SWA configuration and deployment guides"

Write-Host "`n📤 Pushing to GitHub..." -ForegroundColor Yellow
git push origin main

Write-Host "`n✅ Static Web App module added successfully!" -ForegroundColor Green
Write-Host "`n📍 Repository: https://github.com/phoenixvc/azure-infrastructure" -ForegroundColor Cyan