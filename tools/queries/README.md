# Azure Resource Graph Queries

KQL queries for Azure resource discovery and compliance checking.

---

## Available Queries

### **Compliance Check** (`compliance-check.kql`)

Finds resources that don't follow naming conventions.

```bash
az graph query -q "$(cat tools/queries/compliance-check.kql)"
```

### **Resource Inventory** (`resource-inventory.kql`)

Generates inventory grouped by org/env/project.

```bash
az graph query -q "$(cat tools/queries/resource-inventory.kql)"
```

---

## Usage in CI/CD

```yaml
- name: Check naming compliance
run: |
  az graph query -q "$(cat tools/queries/compliance-check.kql)" --output table
```
