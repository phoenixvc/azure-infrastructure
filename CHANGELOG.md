# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

---

## [1.1.0] - 2025-12-07

### Added

- **New Bicep Modules**
  - Virtual Network module (`infra/modules/vnet/`) with NSGs, subnets, and DDoS protection
  - Container Registry module (`infra/modules/container-registry/`) with RBAC and retention policies
  - Log Analytics module (`infra/modules/log-analytics/`) with Application Insights integration

- **Main Orchestrator**
  - Complete `main.bicep` orchestrator that composes all modules
  - Environment-specific parameter files:
    - `main.dev.bicepparam` - Development configuration
    - `main.staging.bicepparam` - Staging configuration
    - `main.prod.bicepparam` - Production configuration

- **API Implementation**
  - Complete FastAPI application in `src/api/app/`
  - Health check endpoints (`/health`, `/health/ready`, `/health/live`)
  - Items CRUD endpoints with full validation
  - Configuration management with Pydantic Settings
  - Pydantic models for request/response validation

- **Test Suite**
  - Unit tests (`tests/unit/`)
    - Health endpoint tests
    - Items CRUD tests
    - Model validation tests
    - Configuration tests
  - Integration tests (`tests/integration/`)
    - API integration tests
    - Database integration tests (mock-based)
    - Storage integration tests (mock-based)
  - E2E tests (`tests/e2e/`)
    - Complete user workflow tests
    - API discovery workflow tests
    - Error handling workflow tests
    - Performance tests
    - Reliability tests
  - Pytest configuration with markers and coverage

### Changed
- Updated module structure to follow consistent patterns
- Enhanced documentation for all modules

---

## [1.0.0] - 2025-12-07

### Added
- **Core Modules**
  - App Service module with auto-scaling
  - PostgreSQL Flexible Server module
  - Key Vault module with RBAC
  - Container Registry module
  - Application Insights module
  - Virtual Network module
  - Storage Account module
  - Static Web App module

- **Features**
  - Multi-environment support (dev/staging/prod)
  - Parameterized deployments
  - Resource tagging standards
  - Naming convention enforcement
  - Security best practices

- **Documentation**
  - Module usage guides
  - Architecture diagrams
  - Deployment instructions
  - Best practices guide
  - Contributing guidelines

- **Infrastructure as Code**
  - Modular Bicep templates
  - Reusable components
  - Parameter files per environment
  - Output values for integration

- **Examples**
  - FastAPI + PostgreSQL
  - Flask + MongoDB
  - .NET + SQL Server
  - Node.js + PostgreSQL
  - Go + Redis
  - Python + DynamoDB
  - Java Spring Boot + MySQL

- **CI/CD**
  - GitHub Actions workflows
  - Bicep validation
  - Automated deployment
  - Security scanning

### Security
- Managed identities for services
- Private endpoints support
- Network security groups
- Key Vault integration
- Diagnostic settings

---

## Release Notes

### v1.0.0 - Initial Release

**Highlights:**
- Production-ready Azure infrastructure modules
- Enterprise-grade security
- Scalable architecture
- Comprehensive documentation

**Modules Included:**
- App Service
- PostgreSQL
- Key Vault
- Container Registry
- Application Insights
- Virtual Network
- Storage Account
- Static Web App

**Getting Started:**
1. Clone the repository
2. Review module documentation
3. Configure parameters
4. Deploy using Azure CLI

---

## Version History

| Version | Date | Description |
|---------|------|-------------|
| 1.1.0 | 2025-12-07 | Added VNet, ACR, Log Analytics modules, main orchestrator, tests |
| 1.0.0 | 2025-12-07 | Initial release |

---

## How to Update This Changelog

### For Maintainers

When making changes, add entries under `[Unreleased]` in the appropriate category:

- **Added** - New features
- **Changed** - Changes in existing functionality
- **Deprecated** - Soon-to-be removed features
- **Removed** - Removed features
- **Fixed** - Bug fixes
- **Security** - Security improvements

### When Releasing

1. Move `[Unreleased]` items to a new version section
2. Add release date
3. Update version links at bottom
4. Tag the release in git

---

## Links

- [Repository](https://github.com/phoenixvc/azure-infrastructure)
- [Issues](https://github.com/phoenixvc/azure-infrastructure/issues)
- [Documentation](https://github.com/phoenixvc/azure-infrastructure/tree/main/docs)

---

[Unreleased]: https://github.com/phoenixvc/azure-infrastructure/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/phoenixvc/azure-infrastructure/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/phoenixvc/azure-infrastructure/releases/tag/v1.0.0
