# Architecture Guide

## Overview

This template provides two architectural patterns to suit different project needs.

---

## Architecture Options

### Option A: Standard Architecture (Recommended for MVPs)

**Best for:**
- MVPs and prototypes
- Small to medium projects
- Teams new to clean architecture
- Time-sensitive deliverables

**Structure:**
```
src/api-standard/
├── main.py              # FastAPI app entry point
├── models.py            # SQLAlchemy models
├── schemas.py           # Pydantic schemas
├── database.py          # Database connection
├── routers/             # API endpoints
│   ├── users.py
│   └── items.py
└── services/            # Business logic
    ├── user_service.py
    └── item_service.py
```

**Characteristics:**
- Simple, flat structure
- Direct database access from routers
- Minimal abstraction layers
- Fast to develop and understand
- Easy onboarding for new developers

---

### Option B: Hexagonal Architecture (Recommended for Complex Projects)

**Best for:**
- Enterprise applications
- Long-term maintainability
- Complex business logic
- Multiple data sources
- High testability requirements

**Structure:**
```
src/api-hexagonal/
├── main.py                      # FastAPI app entry point
├── domain/                      # Core business logic (no dependencies)
│   ├── entities/
│   │   ├── user.py
│   │   └── item.py
│   ├── repositories/            # Repository interfaces
│   │   ├── user_repository.py
│   │   └── item_repository.py
│   └── services/                # Domain services
│       ├── user_service.py
│       └── item_service.py
├── application/                 # Use cases / application logic
│   ├── use_cases/
│   │   ├── create_user.py
│   │   └── get_items.py
│   └── ports/                   # Input/output interfaces
│       ├── input_ports.py
│       └── output_ports.py
└── infrastructure/              # External concerns
    ├── database/
    │   ├── models.py            # SQLAlchemy models
    │   ├── repositories/        # Repository implementations
    │   │   ├── user_repo_impl.py
    │   │   └── item_repo_impl.py
    │   └── connection.py
    ├── api/                     # HTTP layer
    │   ├── routers/
    │   │   ├── users.py
    │   │   └── items.py
    │   └── schemas.py           # Pydantic schemas
    └── config/
        └── settings.py
```

**Characteristics:**
- Clear separation of concerns
- Domain logic independent of frameworks
- Easy to test (mock repositories)
- Flexible (swap databases, APIs)
- Dependency injection throughout

---

## Decision Matrix

| Criteria | Standard | Hexagonal |
|----------|----------|-----------|
| **Development Speed** | Fast | Slower |
| **Learning Curve** | Easy | Moderate |
| **Testability** | Good | Excellent |
| **Maintainability** | Good | Excellent |
| **Flexibility** | Limited | High |
| **Team Size** | 1-3 devs | 3+ devs |
| **Project Lifespan** | < 1 year | 1+ years |

---

## Migration Path

You can start with **Standard** and migrate to **Hexagonal** later:

### Step 1: Extract Domain Entities
```python
# Before (models.py)
class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True)

# After (domain/entities/user.py)
@dataclass
class User:
    id: int
    name: str
```

### Step 2: Create Repository Interfaces
```python
# domain/repositories/user_repository.py
class UserRepository(ABC):
    @abstractmethod
    def get_by_id(self, user_id: int) -> User:
        pass
```

### Step 3: Implement Repositories
```python
# infrastructure/database/repositories/user_repo_impl.py
class UserRepositoryImpl(UserRepository):
    def get_by_id(self, user_id: int) -> User:
        # SQLAlchemy implementation
        pass
```

### Step 4: Use Dependency Injection
```python
# infrastructure/api/routers/users.py
@router.get("/users/{user_id}")
def get_user(
    user_id: int,
    repo: UserRepository = Depends(get_user_repository)
):
    return repo.get_by_id(user_id)
```

---

## Infrastructure Architecture

### Azure Resources

```
┌─────────────────────────────────────────────┐
│           Azure Subscription                │
│                                             │
│  ┌───────────────────────────────────────┐ │
│  │      Resource Group (dev/prod)        │ │
│  │                                       │ │
│  │  ┌─────────────────┐                 │ │
│  │  │   App Service   │                 │ │
│  │  │   (FastAPI)     │◄────────────┐   │ │
│  │  └────────┬────────┘             │   │ │
│  │           │                      │   │ │
│  │           ▼                      │   │ │
│  │  ┌─────────────────┐             │   │ │
│  │  │   PostgreSQL    │             │   │ │
│  │  │   Flexible      │             │   │ │
│  │  └─────────────────┘             │   │ │
│  │                                  │   │ │
│  │  ┌─────────────────┐             │   │ │
│  │  │   Key Vault     │─────────────┘   │ │
│  │  │   (Secrets)     │                 │ │
│  │  └─────────────────┘                 │ │
│  │                                       │ │
│  │  ┌─────────────────┐                 │ │
│  │  │ App Insights    │                 │ │
│  │  │ (Monitoring)    │                 │ │
│  │  └─────────────────┘                 │ │
│  └───────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

### Network Flow

```
Internet
   │
   ▼
Azure Front Door (Optional)
   │
   ▼
App Service
   │
   ├──► PostgreSQL (Private Endpoint)
   │
   ├──► Key Vault (Managed Identity)
   │
   └──► App Insights (Instrumentation)
```

---

## Security Architecture

### Authentication Flow

```
User Request
   │
   ▼
API Gateway
   │
   ├──► JWT Validation
   │    │
   │    ▼
   │    Azure AD / Auth0
   │
   ▼
FastAPI Middleware
   │
   ▼
Protected Endpoint
```

### Secrets Management

- **Development**: `.env` file (not committed)
- **Production**: Azure Key Vault
- **CI/CD**: GitHub Secrets

---

## Data Flow

### Standard Architecture
```
HTTP Request → Router → Service → SQLAlchemy → PostgreSQL
                  ▲         │
                  └─────────┘
                  (Direct DB access)
```

### Hexagonal Architecture
```
HTTP Request → Router → Use Case → Domain Service
                           │              │
                           ▼              ▼
                    Repository Interface
                           │
                           ▼
                  Repository Implementation
                           │
                           ▼
                      PostgreSQL
```

---

## Testing Strategy

### Standard Architecture
- **Unit Tests**: Services (mock database)
- **Integration Tests**: Full stack with test DB
- **E2E Tests**: API endpoints

### Hexagonal Architecture
- **Unit Tests**: Domain logic (pure functions)
- **Integration Tests**: Repository implementations
- **Contract Tests**: Port interfaces
- **E2E Tests**: API endpoints

---

## Deployment Architecture

### CI/CD Pipeline

```
GitHub Push
   │
   ▼
GitHub Actions
   │
   ├──► Lint & Format
   │
   ├──► Run Tests
   │
   ├──► Build Docker Image
   │
   ├──► Push to ACR
   │
   └──► Deploy to App Service
```

### Environment Strategy

| Environment | Branch | Auto-Deploy | Approval |
|-------------|--------|-------------|----------|
| **Dev** | develop | Yes | No |
| **Staging** | main | Yes | No |
| **Production** | main | Manual | Required |

---

## Further Reading

- [FastAPI Best Practices](https://fastapi.tiangolo.com/tutorial/)
- [Hexagonal Architecture](https://alistair.cockburn.us/hexagonal-architecture/)
- [Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/)
- [12-Factor App](https://12factor.net/)

---

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for architecture contribution guidelines.
