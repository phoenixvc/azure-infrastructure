# Tools

Operational tooling for Azure infrastructure management.

---

## Available Tools

### **Validator** (`validator/`)

CLI tool for validating Azure resource names.

```bash
cd tools/validator
pip install -r requirements.txt
python nl_az_name.py validate nl-prod-rooivalk-api-euw
```

See [validator/README.md](validator/README.md) for details.

---

### **Queries** (`queries/`)

Azure Resource Graph queries for compliance and inventory.

```bash
az graph query -q "$(cat tools/queries/compliance-check.kql)"
```

See [queries/README.md](queries/README.md) for details.

---

### **Scripts** (`scripts/`)

Automation scripts for common tasks.

- `setup-azure-infra.ps1` - Initial repository setup
- `publish-modules.ps1` - Publish Bicep modules to ACR

---

## Integration

All tools are designed to work in:
- ✅ Local development
- ✅ CI/CD pipelines (GitHub Actions, Azure DevOps)
- ✅ Azure Cloud Shell
