# Azure Infrastructure Standards

**Unified Azure infrastructure standards, modules, and tooling for:**
- **nl** – NeuralLiquid (Jurie)
- **pvc** – Phoenix VC (Eben)
- **tws** – Twines & Straps (Martyn)
- **mys** – Mystira (Eben)

---

## 🎯 Purpose

This repository is the **single source of truth** for:
- ✅ Azure naming conventions
- ✅ Reusable Infrastructure-as-Code modules
- ✅ Source code templates
- ✅ Validation and operational tools
- ✅ CI/CD workflows
- ✅ Configuration patterns

**This is NOT a template repo.** For project scaffolding, see [`phoenixvc/azure-project-template`](https://github.com/phoenixvc/azure-project-template).

---

## 📋 Quick Start

### **Reference Naming Module**

```bicep
module naming 'br:phoenixvcacr.azurecr.io/infra/modules/naming:v2.1' = {
name: 'naming'
params: {
  org: 'nl'
  env: 'prod'
  project: 'rooivalk'
  region: 'euw'
}
}

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
name: naming.outputs.rgName  // nl-prod-rooivalk-rg-euw
location: 'westeurope'
}
```

### **Validate Resource Names**

```bash
pip install -r tools/validator/requirements.txt
python tools/validator/nl_az_name.py validate nl-prod-rooivalk-api-euw
```

### **Use in CI/CD**

```yaml
jobs:
validate-naming:
  uses: phoenixvc/azure-infrastructure/.github/workflows/validate-naming.yml@main
```

---

## 🏗️ Repository Structure

```
azure-infrastructure/
├── docs/                          # Documentation
│   ├── naming-conventions.md     # Authoritative standard
│   └── examples/                 # Real-world examples
│
├── infra/                        # Infrastructure-as-Code
│   ├── modules/                  # Reusable Bicep modules
│   │   ├── naming/              # Naming convention module
│   │   ├── app-service/         # App Service module
│   │   ├── function-app/        # Function App module
│   │   ├── postgres/            # PostgreSQL module
│   │   ├── storage/             # Storage Account module
│   │   └── key-vault/           # Key Vault module
│   └── examples/                # Deployable examples
│
├── src/                          # Source code templates
│   ├── api/                     # FastAPI template
│   ├── functions/               # Azure Functions template
│   └── worker/                  # Background worker template
│
├── tests/                        # Test templates
│   ├── unit/                    # Unit tests
│   ├── integration/             # Integration tests
│   └── e2e/                     # End-to-end tests
│
├── config/                       # Configuration templates
│   ├── dev.json
│   ├── staging.json
│   └── prod.json
│
├── db/                           # Database
│   ├── migrations/              # Schema migrations
│   └── seeds/                   # Seed data
│
├── tools/                        # Operational tooling
│   ├── validator/               # Naming validator
│   ├── queries/                 # Azure Resource Graph queries
│   └── scripts/                 # Automation scripts
│
└── .github/workflows/            # Reusable CI/CD workflows
```

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [**Naming Conventions**](docs/naming-conventions.md) | Complete naming standard |
| [**Infrastructure Modules**](infra/modules/) | Reusable Bicep modules |
| [**Source Templates**](src/) | API, Functions, Worker templates |
| [**Tools**](tools/) | Validator, queries, scripts |
| [**Examples**](docs/examples/) | Real-world implementations |

---

## 🔧 Available Modules

All modules published to: `br:phoenixvcacr.azurecr.io/infra/modules/{module}:v2.1`

| Module | Description | Documentation |
|--------|-------------|---------------|
| `naming` | Standardized resource naming | [README](infra/modules/naming/README.md) |
| `app-service` | App Service with monitoring | [README](infra/modules/app-service/README.md) |
| `function-app` | Azure Functions with storage | [README](infra/modules/function-app/README.md) |
| `postgres` | PostgreSQL Flexible Server | [README](infra/modules/postgres/README.md) |
| `storage` | Storage Account with containers | [README](infra/modules/storage/README.md) |
| `static-web-app` | Static Web App with GitHub CI/CD | [README](infra/modules/static-web-app/README.md) |
| `key-vault` | Key Vault with access policies | [README](infra/modules/key-vault/README.md) |

---

## 🛠️ Tools

### **Naming Validator**

```bash
python tools/validator/nl_az_name.py validate nl-prod-rooivalk-api-euw

# Output:
# ✅ Valid: nl-prod-rooivalk-api-euw
# Components:
#   org: nl
#   env: prod
#   project: rooivalk
#   type: api
#   region: euw
```

### **Azure Resource Graph Queries**

```bash
# Check naming compliance
az graph query -q "$(cat tools/queries/compliance-check.kql)"

# Generate resource inventory
az graph query -q "$(cat tools/queries/resource-inventory.kql)"
```

See [tools/README.md](tools/README.md) for all available tools.

---

## 📊 Examples

| Example | Organization | Description |
|---------|--------------|-------------|
| [nl-rooivalk](docs/examples/nl-rooivalk.md) | NeuralLiquid | AI platform with API, functions, database |
| [pvc-website](docs/examples/pvc-website.md) | Phoenix VC | Static website |

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- How to propose changes to naming standards
- Module development guidelines
- Pull request process
- Versioning strategy

**Key principle:** Changes to naming standards require consensus from all org leads.

---

## 📦 CI/CD Workflows

Reusable GitHub Actions workflows:

| Workflow | Purpose | Usage |
|----------|---------|-------|
| `validate-naming.yml` | Validate resource names | `uses: phoenixvc/azure-infrastructure/.github/workflows/validate-naming.yml@main` |
| `publish-modules.yml` | Publish Bicep modules to ACR | Runs on push to `main` |
| `ci-api.yml` | Test and build API | Template for projects |
| `ci-functions.yml` | Test and build Functions | Template for projects |

---

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

**Current Version:** v2.1

---

## 📄 License

MIT License - See [LICENSE](LICENSE)

---

## 🔗 Related Repositories

- [**azure-project-template**](https://github.com/phoenixvc/azure-project-template) - Project scaffolding template
- [**neuralliquid/rooivalk-platform**](https://github.com/neuralliquid/rooivalk-platform) - Example implementation

---

## 💬 Support

- **Issues:** [GitHub Issues](https://github.com/phoenixvc/azure-infrastructure/issues)
- **Discussions:** [GitHub Discussions](https://github.com/phoenixvc/azure-infrastructure/discussions)
- **Maintainers:** Hans Jurgens Smit, Jurie, Eben, Martyn

---

**Version:** v2.1  
**Last Updated:** 2025-12-07

