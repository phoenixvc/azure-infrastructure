# Welcome to Your New Azure Project!

You've successfully created a project from the Azure Project Template. Follow these steps to get started.

## Quick Setup (5 minutes)

### 1. Choose Your Architecture

**Option A: Standard (Recommended for MVPs)**
```bash
cp -r src/api-standard src/api
rm -rf src/api-hexagonal
```

**Option B: Hexagonal (Recommended for complex projects)**
```bash
cp -r src/api-hexagonal src/api
rm -rf src/api-standard
```

### 2. Update Project Info

Edit these files and replace placeholders:
- `infra/parameters/dev.bicepparam` - Update org, project name
- `README.md` - Update project description
- `.env.example` - Review environment variables

### 3. Configure Environment

```bash
cp .env.example .env
# Edit .env with your actual values
```

### 4. Install Dependencies

```bash
cd src/api
pip install -r requirements.txt
```

### 5. Run Locally

```bash
uvicorn main:app --reload --port 8000
```

Visit: http://localhost:8000/docs

---

## Deploy to Azure

### Prerequisites
- Azure CLI installed
- Logged in: `az login`
- Subscription selected: `az account set --subscription YOUR_SUBSCRIPTION_ID`

### Deploy Infrastructure

```bash
# Deploy to dev environment
az deployment sub create \
  --location westeurope \
  --template-file infra/main.bicep \
  --parameters infra/parameters/dev.bicepparam

# Deploy to production
az deployment sub create \
  --location westeurope \
  --template-file infra/main.bicep \
  --parameters infra/parameters/prod.bicepparam
```

### Deploy Application

```bash
# Build and deploy
cd src/api
az webapp up --name YOUR_APP_NAME --resource-group YOUR_RG
```

---

## Next Steps

### Essential Tasks
- [ ] Update `README.md` with your project details
- [ ] Configure GitHub Secrets for CI/CD
- [ ] Set up Azure resources
- [ ] Configure database connection
- [ ] Add your business logic
- [ ] Write tests
- [ ] Update documentation

### GitHub Secrets (for CI/CD)
Add these to your repo settings:
- `AZURE_CREDENTIALS` - Service principal JSON
- `AZURE_SUBSCRIPTION_ID` - Your subscription ID

### Recommended Tools
- **Azure CLI** - `az` command
- **Bicep CLI** - Infrastructure as code
- **GitHub CLI** - `gh` command
- **Docker** - For containerization
- **PostgreSQL** - Local database

---

## Documentation

- [Architecture Guide](docs/ARCHITECTURE.md)
- [Deployment Guide](docs/DEPLOYMENT.md)
- [Contributing Guide](CONTRIBUTING.md)
- [Azure Infrastructure Repo](https://github.com/phoenixvc/azure-infrastructure)

---

## Need Help?

- **Issues**: Open an issue in the original template repo
- **Discussions**: Start a discussion for questions
- **Docs**: Check the docs/ folder

---

## Cleanup

Once you're set up, you can delete this file:
```bash
rm .github/TEMPLATE_INSTRUCTIONS.md
git add .github/TEMPLATE_INSTRUCTIONS.md
git commit -m "chore: Remove template instructions"
```

---

**Happy coding!**

Built with love by Phoenix VC
