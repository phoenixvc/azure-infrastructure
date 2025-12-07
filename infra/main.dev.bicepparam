// ============================================================================
// Development Environment Parameters
// ============================================================================
// Usage: az deployment sub create --location westeurope --template-file main.bicep --parameters main.dev.bicepparam

using 'main.bicep'

// Organization & Project
param org = 'nl'
param env = 'dev'
param project = 'rooivalk'

// Location
param location = 'westeurope'
param region = 'euw'

// Database
param dbAdminLogin = 'dbadmin'
// Note: Password should be provided via --parameters dbAdminPassword=<value> or key vault reference

// Compute (use cheaper SKUs for dev)
param appServiceSku = 'B1'
param runtimeStack = 'PYTHON|3.11'
param acrSku = 'Basic'

// Networking (disabled for dev to reduce costs)
param enableVnet = false
param enableDdosProtection = false

// Storage
param storageContainers = ['uploads', 'processed', 'archive']

// Monitoring (shorter retention for dev)
param logRetentionDays = 30

// Frontend (optional)
param enableStaticWebApp = false
