// ============================================================================
// Production Environment Parameters
// ============================================================================
// Usage: az deployment sub create --location westeurope --template-file main.bicep --parameters main.prod.bicepparam

using 'main.bicep'

// Organization & Project
param org = 'nl'
param env = 'prod'
param project = 'rooivalk'

// Location
param location = 'westeurope'
param region = 'euw'

// Database
param dbAdminLogin = 'dbadmin'
// Note: Password should be provided via --parameters dbAdminPassword=<value> or key vault reference

// Compute (production-grade SKUs)
param appServiceSku = 'P1v2'
param runtimeStack = 'PYTHON|3.11'
param acrSku = 'Premium'

// Networking (fully enabled for production security)
param enableVnet = true
param enableDdosProtection = true

// Storage
param storageContainers = ['uploads', 'processed', 'archive', 'backups', 'exports']

// Monitoring (extended retention for compliance)
param logRetentionDays = 365

// Frontend
param enableStaticWebApp = true
