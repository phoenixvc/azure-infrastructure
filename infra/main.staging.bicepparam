// ============================================================================
// Staging Environment Parameters
// ============================================================================
// Usage: az deployment sub create --location westeurope --template-file main.bicep --parameters main.staging.bicepparam

using 'main.bicep'

// Organization & Project
param org = 'nl'
param env = 'staging'
param project = 'rooivalk'

// Location
param location = 'westeurope'
param region = 'euw'

// Database
param dbAdminLogin = 'dbadmin'
// Note: Password should be provided via --parameters dbAdminPassword=<value> or key vault reference

// Compute (production-like but smaller)
param appServiceSku = 'S1'
param runtimeStack = 'PYTHON|3.11'
param acrSku = 'Standard'

// Networking (enable for staging to test VNet integration)
param enableVnet = true
param enableDdosProtection = false

// Storage
param storageContainers = ['uploads', 'processed', 'archive', 'backups']

// Monitoring (longer retention for debugging)
param logRetentionDays = 60

// Frontend
param enableStaticWebApp = true
