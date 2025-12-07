# Example: Phoenix VC Website

Static website implementation for Phoenix VC.

---

## Project Details

- **Organization:** pvc (Phoenix VC)
- **Project:** website
- **Environments:** staging, prod
- **Primary Region:** euw (West Europe)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Azure Subscription                       │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Resource Group: pvc-prod-website-rg-euw               │ │
│  │                                                          │ │
│  │  ┌──────────────┐  ┌──────────────┐                    │ │
│  │  │  Static Web  │  │  Storage     │                    │ │
│  │  │  App         │  │  Account     │                    │ │
│  │  └──────────────┘  └──────────────┘                    │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## Resource Naming

| Resource | Name |
|----------|------|
| Resource Group | `pvc-prod-website-rg-euw` |
| Static Web App | `pvc-prod-website-swa-euw` |
| Storage Account | `pvcprodwebsitestorageeuw` |

---

## Deployment

```bash
az deployment sub create \
--location westeurope \
--template-file infra/examples/pvc-website.bicep
```

---

## Related Resources

- [Infrastructure Code](../../infra/examples/pvc-website.bicep)
