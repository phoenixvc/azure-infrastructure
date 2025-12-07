# Azure Infrastructure Standards

**Unified Azure infrastructure standards, modules, and tooling for:**
- **nl** – NeuralLiquid (Jurie)
- **pvc** – Phoenix VC (Eben)
- **tws** – Twines & Straps (Martyn)
- **mys** – Mystira (Eben)

---

## 🎯 Purpose

This repository is the **single source of truth** for:
- Azure naming conventions
- Reusable Infrastructure-as-Code (IaC) modules
- Validation and linting tools
- Resource discovery queries
- CI/CD workflows for standards enforcement

**This is NOT a template repo.** For project scaffolding, see [`phoenixvc/azure-project-template`](https://github.com/phoenixvc/azure-project-template).

---

## 📋 Quick Start

### **For New Projects**

Use the [azure-project-template](https://github.com/phoenixvc/azure-project-template) to scaffold a new project.

### **For Existing Projects**

#### **1. Reference the Naming Module**

```bicep
module naming 'br:phoenixvcacr.azurecr.io/bicep/modules/naming:v2.1' = {
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

#### **2. Add Naming Validation to CI**

```yaml
jobs:
validate-naming:
  uses: phoenixvc/azure-infrastructure/.github/workflows/validate-naming.yml@main
  with:
    bicep_path: './infra'
```

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [**Naming Conventions v2.1**](docs/azure-naming-conventions-v2.1.md) | Complete naming standard |
| [**Bicep Modules**](bicep/modules/README.md) | Reusable IaC modules |
| [**CLI Tools**](tools/README.md) | Validation tools |

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## 📄 License

MIT License - See [LICENSE](LICENSE)
