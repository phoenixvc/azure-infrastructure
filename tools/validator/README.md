# CLI Tools

## nl_az_name.py

Azure naming convention validator.

### Installation

```bash
pip install -r requirements.txt
```

### Usage

```bash
# Validate a resource name
python nl_az_name.py validate nl-prod-rooivalk-api-euw

# Expected output:
# ✅ Valid: nl-prod-rooivalk-api-euw
# Components:
#   org: nl
#   env: prod
#   project: rooivalk
#   type: api
#   region: euw
```
