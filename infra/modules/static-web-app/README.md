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
