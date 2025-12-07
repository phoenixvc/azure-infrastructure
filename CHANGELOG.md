# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.1.0] - 2025-12-07

### Added
- Complete repository restructure with function-based organization
- Infrastructure modules:
- `naming` - Standardized resource naming
- `app-service` - App Service with monitoring
- `function-app` - Azure Functions with storage
- `postgres` - PostgreSQL Flexible Server
- `storage` - Storage Account with containers
- `key-vault` - Key Vault with access policies
- Source code templates:
- `src/api` - FastAPI template with Dockerfile
- `src/functions` - Azure Functions template
- `src/worker` - Background worker template
- Test structure (unit, integration, e2e)
- Configuration templates (dev, staging, prod)
- Database structure (migrations, seeds)
- Tools:
- Naming validator (Python CLI)
- Azure Resource Graph queries
- Automation scripts
- GitHub Actions workflows:
- `validate-naming.yml` - Reusable naming validation
- `publish-modules.yml` - Publish modules to ACR
- `ci-api.yml` - API CI/CD template
- `ci-functions.yml` - Functions CI/CD template
- Documentation examples (nl-rooivalk, pvc-website)

### Changed
- Reorganized directory structure:
- `bicep/` → `infra/`
- `cli/` → `tools/validator/`
- Added `src/`, `tests/`, `config/`, `db/`
- Updated all documentation to reflect new structure

### Removed
- Old directory structure (bicep/, cli/, scripts/, queries/)

---

## [2.0.0] - 2025-12-06

### Added
- Initial repository setup
- Basic naming module
- CLI validator
- GitHub Actions workflow for validation

---

## [1.0.0] - 2025-12-01

### Added
- Initial naming conventions document
- Basic project structure
