# ============================================================================
# Create azure-project-template Repository (Complete)
# ============================================================================
# Run from: C:\Users\smitj\repos
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host "🚀 Creating azure-project-template repository..." -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# ============================================================================
# 1. Create Repository on GitHub
# ============================================================================
Write-Host "`n📦 Creating GitHub repository..." -ForegroundColor Yellow

# Check if gh CLI is installed
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Error: GitHub CLI (gh) not installed" -ForegroundColor Red
    Write-Host "Install from: https://cli.github.com/" -ForegroundColor Yellow
    exit 1
}

# Navigate to repos directory
cd C:\Users\smitj\repos

# Create repository
gh repo create phoenixvc/azure-project-template `
    --public `
    --description "Template repository for new Azure projects using phoenixvc standards" `
    --clone

# Navigate to repository
cd azure-project-template
Write-Host "  ✓ Created and cloned repository" -ForegroundColor Green

# ============================================================================
# 2. Create Directory Structure
# ============================================================================
Write-Host "`n📁 Creating directory structure..." -ForegroundColor Yellow

$directories = @(
    "infra/parameters",
    "src/api-standard/app/routers",
    "src/api-hexagonal/domain/entities",
    "src/api-hexagonal/domain/repositories",
    "src/api-hexagonal/application/use_cases",
    "src/api-hexagonal/infrastructure/database",
    "src/api-hexagonal/infrastructure/external",
    "src/api-hexagonal/adapters/api/routers",
    "src/web/public",
    "src/web/src/components",
    "src/web/src/pages",
    "src/web/src/styles",
    "src/functions",
    "tests/unit",
    "tests/integration",
    "tests/e2e",
    "config",
    "db/migrations",
    "db/seeds",
    ".github/workflows",
    "docs"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Write-Host "  ✓ Created $dir" -ForegroundColor Green
}

# ============================================================================
# 3. Create Main README
# ============================================================================
Write-Host "`n📝 Creating README.md..." -ForegroundColor Yellow

@'
# Azure Project Template

**Template repository for creating new Azure projects using phoenixvc standards.**

[![Use this template](https://img.shields.io/badge/use%20this-template-blue?logo=github)](https://github.com/phoenixvc/azure-project-template/generate)

---

## 🚀 Quick Start

### **1. Create New Project from Template**

Click **"Use this template"** button above, or:

```bash
gh repo create myorg/my-project --template phoenixvc/azure-project-template --private
cd my-project
```

### **2. Choose Architecture**

This template supports two architectures:

#### **Option A: Standard Architecture** (Recommended for simple projects)
```
src/api-standard/
├── app/
│   ├── main.py          # FastAPI app
│   ├── models.py        # Data models
│   ├── config.py        # Configuration
│   └── routers/         # API routes
```

**Use when:**
- ✅ Simple CRUD operations
- ✅ Small to medium projects
- ✅ Quick prototypes
- ✅ Team unfamiliar with hexagonal architecture

#### **Option B: Hexagonal Architecture** (Recommended for complex projects)
```
src/api-hexagonal/
├── domain/              # Business logic (core)
│   ├── entities/        # Domain entities
│   └── repositories/    # Repository interfaces
├── application/         # Use cases
│   └── use_cases/       # Application logic
├── infrastructure/      # External dependencies
│   ├── database/        # Database implementation
│   └── external/        # External APIs
└── adapters/            # Interface adapters
  └── api/             # FastAPI routes
```

**Use when:**
- ✅ Complex business logic
- ✅ Multiple external integrations
- ✅ Long-term maintainability critical
- ✅ Team experienced with clean architecture

**To choose:**
```bash
# Keep standard, remove hexagonal
rm -rf src/api-hexagonal

# OR keep hexagonal, remove standard
rm -rf src/api-standard

# Rename chosen architecture
mv src/api-standard src/api
# OR
mv src/api-hexagonal src/api
```

### **3. Configure Your Project**

Edit `infra/parameters/dev.bicepparam`:

```bicep
using '../main.bicep'

param org = 'nl'           // Your organization: nl, pvc, tws, mys
param env = 'dev'          // Environment: dev, staging, prod
param project = 'myproject' // Your project name (2-20 chars)
param region = 'euw'       // Azure region: euw, san, saf, etc.
param includeWeb = true    // Deploy Static Web App?
param includeApi = true    // Deploy API App Service?
param includeFunctions = false  // Deploy Functions?
```

### **4. Deploy Infrastructure**

```bash
# Login to Azure
az login

# Deploy to dev environment
az deployment sub create \
--location westeurope \
--template-file infra/main.bicep \
--parameters infra/parameters/dev.bicepparam
```

---

## 📋 What's Included

### **Infrastructure** (`infra/`)
- Main Bicep deployment referencing [azure-infrastructure](https://github.com/phoenixvc/azure-infrastructure) modules
- Environment-specific parameters (dev, staging, prod)
- Automated resource naming
- Optional components (API, Functions, Web)

### **Application Code** (`src/`)
- **API (Standard)** - FastAPI with simple structure
- **API (Hexagonal)** - FastAPI with clean architecture
- **Web** - React + TypeScript + Vite for Static Web Apps
- **Functions** - Azure Functions with HTTP and timer triggers

### **Tests** (`tests/`)
- Unit tests with pytest
- Integration tests for Azure services
- End-to-end tests for complete workflows

### **Configuration** (`config/`)
- Environment-specific JSON configs
- Feature flags
- Database connection settings

### **Database** (`db/`)
- Migration scripts
- Seed data for development

### **CI/CD** (`.github/workflows/`)
- Automated testing on pull requests
- Deployment workflows for each environment
- Separate workflows for API, Functions, and Web

---

## 🏗️ Project Structure

```
my-project/
├── infra/                             # Infrastructure-as-Code
│   ├── main.bicep                     # Main deployment
│   └── parameters/
│       ├── dev.bicepparam
│       ├── staging.bicepparam
│       └── prod.bicepparam
│
├── src/                               # Application code
│   ├── api-standard/                  # Standard architecture (choose one)
│   ├── api-hexagonal/                 # Hexagonal architecture (choose one)
│   ├── web/                           # React Static Web App
│   └── functions/                     # Azure Functions
│
├── tests/                             # Tests
│   ├── unit/
│   ├── integration/
│   └── e2e/
│
├── config/                            # Configuration
│   ├── dev.json
│   ├── staging.json
│   └── prod.json
│
├── db/                                # Database
│   ├── migrations/
│   └── seeds/
│
└── .github/workflows/                 # CI/CD
  ├── ci-api.yml
  ├── ci-web.yml
  ├── ci-functions.yml
  └── deploy.yml
```

---

## 📚 Documentation

- [**Setup Guide**](SETUP.md) - First-time setup instructions
- [**Architecture Decision**](docs/ARCHITECTURE.md) - Choosing between standard and hexagonal
- [**Infrastructure Guide**](infra/README.md) - Infrastructure deployment
- [**API Documentation**](docs/API.md) - API development
- [**Web Documentation**](docs/WEB.md) - Frontend development
- [**Testing Guide**](docs/TESTING.md) - Running tests

---

## 🔗 Related Resources

- [**azure-infrastructure**](https://github.com/phoenixvc/azure-infrastructure) - Shared standards and modules
- [**Naming Conventions**](https://github.com/phoenixvc/azure-infrastructure/blob/main/docs/naming-conventions.md) - Naming standard documentation

---

## 🎯 Architecture Comparison

| Aspect | Standard | Hexagonal |
|--------|----------|-----------|
| **Complexity** | Low | Medium-High |
| **Learning Curve** | Easy | Moderate |
| **Best For** | CRUD apps, MVPs | Complex business logic |
| **Testability** | Good | Excellent |
| **Maintainability** | Good | Excellent |
| **Initial Setup** | Fast | Slower |
| **Scalability** | Good | Excellent |

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## 📄 License

MIT License - See [LICENSE](LICENSE)

---

## 💬 Support

- **Issues:** [GitHub Issues](https://github.com/phoenixvc/azure-project-template/issues)
- **Discussions:** [GitHub Discussions](https://github.com/phoenixvc/azure-project-template/discussions)
- **Maintainers:** Hans Jurgens Smit, Jurie, Eben, Martyn
'@ | Out-File -FilePath "README.md" -Encoding UTF8
Write-Host "  ✓ Created README.md" -ForegroundColor Green

# ============================================================================
# 4. Create ARCHITECTURE.md
# ============================================================================
Write-Host "`n📝 Creating docs/ARCHITECTURE.md..." -ForegroundColor Yellow

@'
# Architecture Decision Guide

Choosing between Standard and Hexagonal architecture for your project.

---

## Overview

This template provides two architectural approaches:

1. **Standard Architecture** - Traditional layered architecture
2. **Hexagonal Architecture** - Ports and adapters pattern (clean architecture)

---

## Standard Architecture

### Structure

```
src/api-standard/
├── app/
│   ├── main.py              # FastAPI application entry point
│   ├── config.py            # Configuration management
│   ├── models.py            # Pydantic models (request/response)
│   ├── database.py          # Database connection
│   ├── dependencies.py      # Dependency injection
│   └── routers/
│       ├── health.py        # Health check endpoints
│       ├── users.py         # User endpoints
│       └── items.py         # Item endpoints
├── Dockerfile
└── requirements.txt
```

### Characteristics

- **Simple and straightforward**
- **Fast to develop**
- **Easy to understand**
- **Good for CRUD operations**
- **Less abstraction**

### Example Code

```python
# app/routers/users.py
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User, UserCreate

router = APIRouter()

@router.post("/users", response_model=User)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
  db_user = User(**user.dict())
  db.add(db_user)
  db.commit()
  db.refresh(db_user)
  return db_user

@router.get("/users/{user_id}", response_model=User)
def get_user(user_id: int, db: Session = Depends(get_db)):
  return db.query(User).filter(User.id == user_id).first()
```

### When to Use

✅ **Use Standard When:**
- Simple CRUD operations
- Small to medium projects
- Quick prototypes or MVPs
- Team unfamiliar with clean architecture
- Tight deadlines
- Limited business logic complexity

❌ **Avoid Standard When:**
- Complex business rules
- Multiple external integrations
- High testability requirements
- Long-term maintenance critical
- Frequent requirement changes

---

## Hexagonal Architecture

### Structure

```
src/api-hexagonal/
├── domain/                  # Core business logic (no dependencies)
│   ├── entities/
│   │   ├── user.py         # User entity
│   │   └── item.py         # Item entity
│   └── repositories/
│       ├── user_repository.py      # User repository interface
│       └── item_repository.py      # Item repository interface
│
├── application/             # Use cases (orchestration)
│   └── use_cases/
│       ├── create_user.py          # Create user use case
│       ├── get_user.py             # Get user use case
│       └── list_users.py           # List users use case
│
├── infrastructure/          # External dependencies
│   ├── database/
│   │   ├── models.py               # SQLAlchemy models
│   │   ├── user_repository_impl.py # User repository implementation
│   │   └── database.py             # Database connection
│   └── external/
│       └── email_service.py        # External email service
│
└── adapters/                # Interface adapters
  └── api/
      ├── main.py                 # FastAPI application
      ├── dependencies.py         # Dependency injection
      ├── schemas.py              # Request/response schemas
      └── routers/
          ├── health.py           # Health check
          └── users.py            # User endpoints
```

### Characteristics

- **Separation of concerns**
- **Highly testable**
- **Business logic isolated**
- **Easy to swap implementations**
- **More initial setup**

### Example Code

```python
# domain/entities/user.py
from dataclasses import dataclass
from datetime import datetime

@dataclass
class User:
  id: int
  email: str
  name: str
  created_at: datetime

# domain/repositories/user_repository.py
from abc import ABC, abstractmethod
from typing import Optional, List
from domain.entities.user import User

class UserRepository(ABC):
  @abstractmethod
  def create(self, user: User) -> User:
      pass
  
  @abstractmethod
  def get_by_id(self, user_id: int) -> Optional[User]:
      pass
  
  @abstractmethod
  def list_all(self) -> List[User]:
      pass

# application/use_cases/create_user.py
from domain.entities.user import User
from domain.repositories.user_repository import UserRepository

class CreateUserUseCase:
  def __init__(self, user_repository: UserRepository):
      self.user_repository = user_repository
  
  def execute(self, email: str, name: str) -> User:
      # Business logic here
      user = User(id=0, email=email, name=name, created_at=datetime.now())
      return self.user_repository.create(user)

# infrastructure/database/user_repository_impl.py
from sqlalchemy.orm import Session
from domain.repositories.user_repository import UserRepository
from domain.entities.user import User
from infrastructure.database.models import UserModel

class UserRepositoryImpl(UserRepository):
  def __init__(self, db: Session):
      self.db = db
  
  def create(self, user: User) -> User:
      db_user = UserModel(email=user.email, name=user.name)
      self.db.add(db_user)
      self.db.commit()
      self.db.refresh(db_user)
      return User(
          id=db_user.id,
          email=db_user.email,
          name=db_user.name,
          created_at=db_user.created_at
      )

# adapters/api/routers/users.py
from fastapi import APIRouter, Depends
from adapters.api.dependencies import get_create_user_use_case
from adapters.api.schemas import UserCreate, UserResponse
from application.use_cases.create_user import CreateUserUseCase

router = APIRouter()

@router.post("/users", response_model=UserResponse)
def create_user(
  user: UserCreate,
  use_case: CreateUserUseCase = Depends(get_create_user_use_case)
):
  created_user = use_case.execute(user.email, user.name)
  return UserResponse.from_entity(created_user)
```

### When to Use

✅ **Use Hexagonal When:**
- Complex business logic
- Multiple external integrations
- High testability requirements
- Long-term maintenance critical
- Frequent requirement changes
- Team experienced with clean architecture
- Need to swap implementations (e.g., different databases)

❌ **Avoid Hexagonal When:**
- Simple CRUD operations
- Tight deadlines
- Small team unfamiliar with pattern
- Prototype or proof-of-concept
- Limited business logic

---

## Decision Matrix

| Criteria | Weight | Standard | Hexagonal |
|----------|--------|----------|-----------|
| **Project Complexity** | High | 2/5 | 5/5 |
| **Team Experience** | Medium | 5/5 | 3/5 |
| **Time to Market** | High | 5/5 | 3/5 |
| **Testability Needs** | High | 3/5 | 5/5 |
| **Maintainability** | High | 3/5 | 5/5 |
| **Business Logic Complexity** | High | 2/5 | 5/5 |
| **External Integrations** | Medium | 3/5 | 5/5 |

---

## Migration Path

You can start with **Standard** and migrate to **Hexagonal** later:

### Step 1: Extract Business Logic
Move business logic from routers to separate service classes.

### Step 2: Define Interfaces
Create repository interfaces in `domain/repositories/`.

### Step 3: Implement Repositories
Move database logic to repository implementations.

### Step 4: Create Use Cases
Extract orchestration logic into use case classes.

### Step 5: Refactor Adapters
Update API routes to use use cases via dependency injection.

---

## Recommendations

### Start with Standard if:
- Building an MVP
- Team is new to clean architecture
- Project has simple requirements
- Need to ship quickly

### Start with Hexagonal if:
- Building a long-term product
- Complex business rules
- Multiple integrations planned
- Team has clean architecture experience
- Testability is critical

---

## Examples in This Template

Both architectures are fully implemented with:
- ✅ Complete FastAPI setup
- ✅ Database integration (PostgreSQL)
- ✅ Authentication
- ✅ Logging
- ✅ Error handling
- ✅ Health checks
- ✅ Docker support

**Choose one, delete the other, and rename to `src/api`.**

---

## Further Reading

- [Hexagonal Architecture (Alistair Cockburn)](https://alistair.cockburn.us/hexagonal-architecture/)
- [Clean Architecture (Robert C. Martin)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Ports and Adapters Pattern](https://herbertograca.com/2017/09/14/ports-adapters-architecture/)
'@ | Out-File -FilePath "docs/ARCHITECTURE.md" -Encoding UTF8
Write-Host "  ✓ Created docs/ARCHITECTURE.md" -ForegroundColor Green

Write-Host "`n✅ Part 1 of template creation complete!" -ForegroundColor Green
Write-Host "`n📍 Next: Run create-azure-project-template-part2.ps1 to add implementation files" -ForegroundColor Cyan