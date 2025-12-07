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
