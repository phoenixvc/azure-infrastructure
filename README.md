# Azure Project Template

Production-ready Azure project template with multiple architecture options.

## Quick Start

### 1. Create from Template
```bash
gh repo create myorg/my-project --template phoenixvc/azure-project-template --public --clone
cd my-project
```

### 2. Choose Architecture
```bash
# Standard (fast development)
cp -r src/api-standard src/api

# OR Hexagonal (clean architecture)
cp -r src/api-hexagonal src/api

# Clean up
rm -rf src/api-standard src/api-hexagonal
```

### 3. Configure
```bash
# Edit infrastructure parameters
code infra/parameters/dev.bicepparam
```

### 4. Deploy
```bash
az deployment sub create --location westeurope --template-file infra/main.bicep --parameters infra/parameters/dev.bicepparam
```

### 5. Run Locally
```bash
cd src/api
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

## Architecture Options

### Standard (Layered)
**Best for:** Quick development, MVPs, simple CRUD

- Fast development
- Easy to understand
- Simple structure

### Hexagonal (Clean Architecture)
**Best for:** Complex business logic, long-term projects

- Highly testable
- Easy to maintain
- Clear separation of concerns

See [ARCHITECTURE.md](docs/ARCHITECTURE.md) for details.

## Project Structure
```
├── infra/           # Bicep templates
├── src/             # Source code
│   ├── api-standard/
│   ├── api-hexagonal/
│   └── web/
├── config/          # Environment configs
├── db/              # Migrations & seeds
└── tests/           # Unit, integration, E2E
```

## Testing
```bash
pytest tests/unit -v
pytest tests/integration -v
pytest tests/e2e -v
```

## Related
- [azure-infrastructure](https://github.com/phoenixvc/azure-infrastructure) - Standards & modules

---

## Connect With Us

<div align="center">

[![ChatGPT](https://img.shields.io/badge/ChatGPT-74aa9c?style=for-the-badge&logo=openai&logoColor=white)](https://chat.openai.com)
[![X](https://img.shields.io/badge/X-000000?style=for-the-badge&logo=x&logoColor=white)](https://x.com/phoenixvc)
[![Meta](https://img.shields.io/badge/Meta-0668E1?style=for-the-badge&logo=meta&logoColor=white)](https://facebook.com/phoenixvc)
[![Bluesky](https://img.shields.io/badge/Bluesky-0285FF?style=for-the-badge&logo=bluesky&logoColor=white)](https://bsky.app/profile/phoenixvc)

</div>

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">

**Built with ❤️ by [Phoenix Venture Capital](https://phoenixvc.co.za)**

*Empowering innovation through technology*

</div>
