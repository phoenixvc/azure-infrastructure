# Azure Infrastructure Standards

Unified Azure infrastructure standards, modules, and tooling.

## Organizations
- **nl** - NeuralLiquid (Jurie)
- **pvc** - Phoenix VC (Eben)
- **tws** - Twines & Straps (Martyn)
- **mys** - Mystira (Eben)

## Quick Start

### Validate Names
\\\ash
pip install -r tools/validator/requirements.txt
python tools/validator/nl_az_name.py validate nl-prod-rooivalk-api-euw
\\\

### Use Bicep Modules
\\\icep
module naming 'infra/modules/naming/main.bicep' = {
  params: {
    org: 'nl'
    env: 'prod'
    project: 'rooivalk'
    region: 'euw'
  }
}
\\\

## Naming Convention
**Format:** [org]-[env]-[project]-[type]-[region]  
**Example:** nl-prod-rooivalk-api-euw

## Bicep Modules
- naming - Standardized names
- app-service - Azure App Service
- function-app - Azure Functions
- postgres - PostgreSQL
- storage - Storage Account
- key-vault - Key Vault
- static-web-app - Static Web Apps

## Related
- [azure-project-template](https://github.com/phoenixvc/azure-project-template)

Built with ❤️ by Phoenix VC
