# Architecture Guide

## Overview

This template provides two battle-tested architectural patterns designed for Azure deployments. Choose based on your project's complexity, team size, and long-term goals.

**Key Principles:**
- Cloud-native design for Azure
- Infrastructure as Code (Bicep)
- Security by default
- Observable and maintainable
- Cost-optimized

---

## Quick Decision Guide

```
Is your project...
│
├─► MVP/Prototype with < 6 month timeline?
│   └─► Use Standard Architecture
│
├─► Complex business logic with multiple integrations?
│   └─► Use Hexagonal Architecture
│
├─► Unsure? Start with Standard, migrate later
│   └─► Migration path documented below
```

---

## Architecture Options

### Option A: Standard Architecture

**Recommended for:** MVPs, prototypes, small teams, time-sensitive projects

```
src/api-standard/
├── main.py              # FastAPI app entry point
├── config.py            # Configuration management
├── database.py          # Database connection & session
├── models.py            # SQLAlchemy ORM models
├── schemas.py           # Pydantic request/response schemas
├── dependencies.py      # FastAPI dependencies
├── routers/             # API endpoint handlers
│   ├── __init__.py
│   ├── users.py
│   ├── items.py
│   └── health.py
├── services/            # Business logic layer
│   ├── __init__.py
│   ├── user_service.py
│   └── item_service.py
├── middleware/          # Custom middleware
│   ├── __init__.py
│   ├── logging.py
│   └── error_handler.py
└── utils/               # Helper functions
    ├── __init__.py
    └── validators.py
```

**Code Example - Standard Pattern:**
```python
# routers/users.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from services import user_service
from schemas import UserCreate, UserResponse

router = APIRouter(prefix="/users", tags=["users"])

@router.post("/", response_model=UserResponse, status_code=201)
async def create_user(user: UserCreate, db: Session = Depends(get_db)):
    existing = user_service.get_by_email(db, user.email)
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    return user_service.create(db, user)

@router.get("/{user_id}", response_model=UserResponse)
async def get_user(user_id: int, db: Session = Depends(get_db)):
    user = user_service.get_by_id(db, user_id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user
```

```python
# services/user_service.py
from sqlalchemy.orm import Session
from models import User
from schemas import UserCreate

def get_by_id(db: Session, user_id: int) -> User | None:
    return db.query(User).filter(User.id == user_id).first()

def get_by_email(db: Session, email: str) -> User | None:
    return db.query(User).filter(User.email == email).first()

def create(db: Session, user: UserCreate) -> User:
    db_user = User(**user.model_dump())
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user
```

**Pros:**
- Fast development cycle
- Easy to understand and onboard
- Minimal boilerplate
- Direct debugging

**Cons:**
- Harder to test in isolation
- Business logic can leak into routers
- Tighter coupling to frameworks

---

### Option B: Hexagonal Architecture (Ports & Adapters)

**Recommended for:** Enterprise apps, complex domains, long-term projects, multiple integrations

```
src/api-hexagonal/
├── main.py                          # Application bootstrap
├── domain/                          # Core business logic (NO external dependencies)
│   ├── __init__.py
│   ├── entities/                    # Business objects
│   │   ├── __init__.py
│   │   ├── user.py                  # User entity
│   │   └── item.py                  # Item entity
│   ├── value_objects/               # Immutable domain concepts
│   │   ├── __init__.py
│   │   ├── email.py
│   │   └── money.py
│   ├── exceptions.py                # Domain-specific exceptions
│   ├── repositories/                # Repository interfaces (ports)
│   │   ├── __init__.py
│   │   ├── user_repository.py
│   │   └── item_repository.py
│   └── services/                    # Domain services
│       ├── __init__.py
│       ├── user_service.py
│       └── pricing_service.py
├── application/                     # Use cases & orchestration
│   ├── __init__.py
│   ├── use_cases/                   # Application use cases
│   │   ├── __init__.py
│   │   ├── users/
│   │   │   ├── create_user.py
│   │   │   ├── get_user.py
│   │   │   └── update_user.py
│   │   └── items/
│   │       ├── create_item.py
│   │       └── list_items.py
│   ├── dto/                         # Data transfer objects
│   │   ├── __init__.py
│   │   ├── user_dto.py
│   │   └── item_dto.py
│   └── interfaces/                  # Application interfaces
│       ├── __init__.py
│       └── email_service.py
└── infrastructure/                  # External adapters
    ├── __init__.py
    ├── config/
    │   ├── __init__.py
    │   └── settings.py
    ├── persistence/                 # Database adapters
    │   ├── __init__.py
    │   ├── database.py
    │   ├── models/                  # SQLAlchemy models
    │   │   ├── __init__.py
    │   │   ├── user_model.py
    │   │   └── item_model.py
    │   └── repositories/            # Repository implementations
    │       ├── __init__.py
    │       ├── sqlalchemy_user_repo.py
    │       └── sqlalchemy_item_repo.py
    ├── api/                         # HTTP adapter
    │   ├── __init__.py
    │   ├── app.py
    │   ├── dependencies.py
    │   ├── schemas/                 # API schemas
    │   │   ├── __init__.py
    │   │   ├── user_schemas.py
    │   │   └── item_schemas.py
    │   ├── routers/
    │   │   ├── __init__.py
    │   │   ├── users.py
    │   │   └── items.py
    │   └── middleware/
    │       ├── __init__.py
    │       └── error_handler.py
    └── external/                    # External service adapters
        ├── __init__.py
        ├── sendgrid_email.py
        └── stripe_payment.py
```

**Code Example - Hexagonal Pattern:**

```python
# domain/entities/user.py
from dataclasses import dataclass, field
from datetime import datetime
from domain.value_objects.email import Email
from domain.exceptions import InvalidUserError

@dataclass
class User:
    id: int | None
    email: Email
    name: str
    is_active: bool = True
    created_at: datetime = field(default_factory=datetime.utcnow)

    def __post_init__(self):
        if not self.name or len(self.name) < 2:
            raise InvalidUserError("Name must be at least 2 characters")

    def deactivate(self) -> None:
        self.is_active = False

    def update_email(self, new_email: Email) -> None:
        self.email = new_email
```

```python
# domain/repositories/user_repository.py
from abc import ABC, abstractmethod
from domain.entities.user import User
from domain.value_objects.email import Email

class UserRepository(ABC):
    @abstractmethod
    def get_by_id(self, user_id: int) -> User | None:
        pass

    @abstractmethod
    def get_by_email(self, email: Email) -> User | None:
        pass

    @abstractmethod
    def save(self, user: User) -> User:
        pass

    @abstractmethod
    def delete(self, user_id: int) -> bool:
        pass
```

```python
# application/use_cases/users/create_user.py
from dataclasses import dataclass
from domain.entities.user import User
from domain.value_objects.email import Email
from domain.repositories.user_repository import UserRepository
from domain.exceptions import UserAlreadyExistsError

@dataclass
class CreateUserRequest:
    email: str
    name: str

@dataclass
class CreateUserResponse:
    id: int
    email: str
    name: str

class CreateUserUseCase:
    def __init__(self, user_repository: UserRepository):
        self._user_repository = user_repository

    def execute(self, request: CreateUserRequest) -> CreateUserResponse:
        email = Email(request.email)

        existing = self._user_repository.get_by_email(email)
        if existing:
            raise UserAlreadyExistsError(f"User with email {email} already exists")

        user = User(id=None, email=email, name=request.name)
        saved_user = self._user_repository.save(user)

        return CreateUserResponse(
            id=saved_user.id,
            email=str(saved_user.email),
            name=saved_user.name
        )
```

```python
# infrastructure/persistence/repositories/sqlalchemy_user_repo.py
from sqlalchemy.orm import Session
from domain.entities.user import User
from domain.value_objects.email import Email
from domain.repositories.user_repository import UserRepository
from infrastructure.persistence.models.user_model import UserModel

class SQLAlchemyUserRepository(UserRepository):
    def __init__(self, session: Session):
        self._session = session

    def get_by_id(self, user_id: int) -> User | None:
        model = self._session.query(UserModel).filter(UserModel.id == user_id).first()
        return self._to_entity(model) if model else None

    def get_by_email(self, email: Email) -> User | None:
        model = self._session.query(UserModel).filter(UserModel.email == str(email)).first()
        return self._to_entity(model) if model else None

    def save(self, user: User) -> User:
        model = UserModel(
            id=user.id,
            email=str(user.email),
            name=user.name,
            is_active=user.is_active
        )
        self._session.add(model)
        self._session.commit()
        self._session.refresh(model)
        return self._to_entity(model)

    def _to_entity(self, model: UserModel) -> User:
        return User(
            id=model.id,
            email=Email(model.email),
            name=model.name,
            is_active=model.is_active,
            created_at=model.created_at
        )
```

```python
# infrastructure/api/routers/users.py
from fastapi import APIRouter, Depends, HTTPException
from infrastructure.api.dependencies import get_create_user_use_case
from infrastructure.api.schemas.user_schemas import CreateUserRequest, UserResponse
from application.use_cases.users.create_user import CreateUserUseCase
from domain.exceptions import UserAlreadyExistsError

router = APIRouter(prefix="/users", tags=["users"])

@router.post("/", response_model=UserResponse, status_code=201)
async def create_user(
    request: CreateUserRequest,
    use_case: CreateUserUseCase = Depends(get_create_user_use_case)
):
    try:
        result = use_case.execute(request)
        return UserResponse(**result.__dict__)
    except UserAlreadyExistsError as e:
        raise HTTPException(status_code=400, detail=str(e))
```

**Pros:**
- Highly testable (mock everything)
- Framework-agnostic domain
- Easy to swap implementations
- Clear boundaries and responsibilities
- Scales with complexity

**Cons:**
- More boilerplate code
- Steeper learning curve
- Overkill for simple CRUD

---

## Decision Matrix

| Criteria | Standard | Hexagonal |
|----------|:--------:|:---------:|
| **Initial Development Speed** | Fast | Slower |
| **Long-term Velocity** | Decreases | Stable |
| **Learning Curve** | Easy | Moderate |
| **Unit Testability** | Good | Excellent |
| **Integration Testability** | Good | Excellent |
| **Maintainability** | Good | Excellent |
| **Flexibility** | Limited | High |
| **Framework Lock-in** | High | Low |
| **Onboarding New Devs** | Easy | Moderate |
| **Refactoring Safety** | Risky | Safe |
| **Team Size** | 1-3 devs | 3+ devs |
| **Project Lifespan** | < 1 year | 1+ years |
| **Lines of Code** | Less | More |
| **External Integrations** | Few | Many |

### When to Choose What

**Choose Standard when:**
- Building an MVP to validate an idea
- Timeline is < 6 months
- Team is small (1-3 developers)
- Domain logic is straightforward CRUD
- You need to ship fast

**Choose Hexagonal when:**
- Building a product expected to last 2+ years
- Complex business rules and workflows
- Multiple external integrations (payments, email, etc.)
- High test coverage is required
- Team will grow over time
- Domain experts are involved

---

## Anti-Patterns to Avoid

### In Standard Architecture

```python
# BAD: Business logic in router
@router.post("/orders")
async def create_order(order: OrderCreate, db: Session = Depends(get_db)):
    # Don't do complex logic here!
    if order.total > 1000:
        discount = order.total * 0.1
        order.total -= discount
    # ... more business logic
    db.add(order)
    db.commit()

# GOOD: Delegate to service
@router.post("/orders")
async def create_order(order: OrderCreate, db: Session = Depends(get_db)):
    return order_service.create_with_discount(db, order)
```

```python
# BAD: Direct model exposure
@router.get("/users/{id}")
async def get_user(id: int, db: Session = Depends(get_db)):
    return db.query(User).filter(User.id == id).first()  # Exposes DB model!

# GOOD: Use response schema
@router.get("/users/{id}", response_model=UserResponse)
async def get_user(id: int, db: Session = Depends(get_db)):
    user = user_service.get_by_id(db, id)
    if not user:
        raise HTTPException(404)
    return user
```

### In Hexagonal Architecture

```python
# BAD: Domain depends on infrastructure
from sqlalchemy.orm import Session  # NO! Domain shouldn't know about SQLAlchemy

class UserService:
    def __init__(self, session: Session):  # Wrong!
        self.session = session

# GOOD: Domain depends on abstractions
from domain.repositories.user_repository import UserRepository

class UserService:
    def __init__(self, user_repository: UserRepository):
        self._user_repository = user_repository
```

```python
# BAD: Use case knows about HTTP
from fastapi import HTTPException  # NO! Use cases shouldn't know about HTTP

class CreateUserUseCase:
    def execute(self, request):
        if self._user_repo.exists(request.email):
            raise HTTPException(400, "exists")  # Wrong!

# GOOD: Use domain exceptions
from domain.exceptions import UserAlreadyExistsError

class CreateUserUseCase:
    def execute(self, request):
        if self._user_repo.exists(request.email):
            raise UserAlreadyExistsError(request.email)  # Correct!
```

---

## Error Handling

### Error Hierarchy

```python
# domain/exceptions.py
class DomainError(Exception):
    """Base exception for domain errors"""
    pass

class EntityNotFoundError(DomainError):
    """Raised when an entity is not found"""
    def __init__(self, entity_type: str, identifier: str):
        self.entity_type = entity_type
        self.identifier = identifier
        super().__init__(f"{entity_type} with id '{identifier}' not found")

class ValidationError(DomainError):
    """Raised when validation fails"""
    pass

class BusinessRuleViolationError(DomainError):
    """Raised when a business rule is violated"""
    pass

class UserAlreadyExistsError(BusinessRuleViolationError):
    """Raised when attempting to create a duplicate user"""
    pass
```

### Global Error Handler

```python
# infrastructure/api/middleware/error_handler.py
from fastapi import Request, status
from fastapi.responses import JSONResponse
from domain.exceptions import (
    EntityNotFoundError,
    ValidationError,
    BusinessRuleViolationError
)
import logging

logger = logging.getLogger(__name__)

async def error_handler(request: Request, call_next):
    try:
        return await call_next(request)
    except EntityNotFoundError as e:
        return JSONResponse(
            status_code=status.HTTP_404_NOT_FOUND,
            content={"error": str(e), "type": "not_found"}
        )
    except ValidationError as e:
        return JSONResponse(
            status_code=status.HTTP_400_BAD_REQUEST,
            content={"error": str(e), "type": "validation_error"}
        )
    except BusinessRuleViolationError as e:
        return JSONResponse(
            status_code=status.HTTP_409_CONFLICT,
            content={"error": str(e), "type": "business_rule_violation"}
        )
    except Exception as e:
        logger.exception("Unhandled exception")
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content={"error": "Internal server error", "type": "internal_error"}
        )
```

---

## Logging & Observability

### Structured Logging

```python
# infrastructure/logging.py
import logging
import json
from datetime import datetime

class JSONFormatter(logging.Formatter):
    def format(self, record):
        log_obj = {
            "timestamp": datetime.utcnow().isoformat(),
            "level": record.levelname,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
        }

        if hasattr(record, "user_id"):
            log_obj["user_id"] = record.user_id

        if hasattr(record, "request_id"):
            log_obj["request_id"] = record.request_id

        if record.exc_info:
            log_obj["exception"] = self.formatException(record.exc_info)

        return json.dumps(log_obj)

def setup_logging():
    handler = logging.StreamHandler()
    handler.setFormatter(JSONFormatter())

    logger = logging.getLogger()
    logger.addHandler(handler)
    logger.setLevel(logging.INFO)
```

### Request Tracing Middleware

```python
# infrastructure/api/middleware/tracing.py
import uuid
import time
import logging
from fastapi import Request

logger = logging.getLogger(__name__)

async def request_tracing_middleware(request: Request, call_next):
    request_id = str(uuid.uuid4())
    request.state.request_id = request_id

    start_time = time.time()

    logger.info(
        f"Request started",
        extra={
            "request_id": request_id,
            "method": request.method,
            "path": request.url.path,
        }
    )

    response = await call_next(request)

    duration = time.time() - start_time
    logger.info(
        f"Request completed",
        extra={
            "request_id": request_id,
            "status_code": response.status_code,
            "duration_ms": round(duration * 1000, 2),
        }
    )

    response.headers["X-Request-ID"] = request_id
    return response
```

### Azure Application Insights Integration

```python
# infrastructure/observability/app_insights.py
from opencensus.ext.azure.log_exporter import AzureLogHandler
from opencensus.ext.azure.trace_exporter import AzureExporter
from opencensus.trace.samplers import ProbabilitySampler
import logging

def setup_azure_monitoring(connection_string: str):
    # Logging
    logger = logging.getLogger(__name__)
    logger.addHandler(AzureLogHandler(connection_string=connection_string))

    # Tracing
    exporter = AzureExporter(connection_string=connection_string)
    sampler = ProbabilitySampler(1.0)  # Sample 100% in dev, reduce in prod

    return exporter, sampler
```

---

## API Design Guidelines

### RESTful Conventions

| Action | HTTP Method | Endpoint | Status Code |
|--------|-------------|----------|-------------|
| List | GET | `/users` | 200 |
| Create | POST | `/users` | 201 |
| Read | GET | `/users/{id}` | 200 |
| Update (full) | PUT | `/users/{id}` | 200 |
| Update (partial) | PATCH | `/users/{id}` | 200 |
| Delete | DELETE | `/users/{id}` | 204 |

### Response Format

```python
# Success response
{
    "data": {...},
    "meta": {
        "request_id": "uuid",
        "timestamp": "2025-01-15T10:30:00Z"
    }
}

# Error response
{
    "error": {
        "code": "VALIDATION_ERROR",
        "message": "Email is invalid",
        "details": [
            {"field": "email", "message": "Must be a valid email address"}
        ]
    },
    "meta": {
        "request_id": "uuid",
        "timestamp": "2025-01-15T10:30:00Z"
    }
}

# Paginated response
{
    "data": [...],
    "pagination": {
        "page": 1,
        "per_page": 20,
        "total": 100,
        "total_pages": 5
    },
    "meta": {...}
}
```

### Versioning Strategy

```python
# URL versioning (recommended)
/api/v1/users
/api/v2/users

# Header versioning (alternative)
Accept: application/vnd.myapi.v1+json
```

---

## Caching Strategy

### Redis Caching Layer

```python
# infrastructure/cache/redis_cache.py
import json
from typing import Any, Optional
from redis import Redis

class RedisCache:
    def __init__(self, redis_client: Redis, default_ttl: int = 3600):
        self._redis = redis_client
        self._default_ttl = default_ttl

    def get(self, key: str) -> Optional[Any]:
        value = self._redis.get(key)
        return json.loads(value) if value else None

    def set(self, key: str, value: Any, ttl: Optional[int] = None) -> None:
        self._redis.setex(
            key,
            ttl or self._default_ttl,
            json.dumps(value)
        )

    def delete(self, key: str) -> None:
        self._redis.delete(key)

    def invalidate_pattern(self, pattern: str) -> None:
        keys = self._redis.keys(pattern)
        if keys:
            self._redis.delete(*keys)
```

### Cache-Aside Pattern

```python
# application/use_cases/users/get_user.py
class GetUserUseCase:
    def __init__(self, user_repo: UserRepository, cache: RedisCache):
        self._user_repo = user_repo
        self._cache = cache

    def execute(self, user_id: int) -> UserResponse:
        cache_key = f"user:{user_id}"

        # Try cache first
        cached = self._cache.get(cache_key)
        if cached:
            return UserResponse(**cached)

        # Fetch from database
        user = self._user_repo.get_by_id(user_id)
        if not user:
            raise EntityNotFoundError("User", str(user_id))

        # Store in cache
        response = UserResponse(id=user.id, email=str(user.email), name=user.name)
        self._cache.set(cache_key, response.__dict__)

        return response
```

---

## Azure Infrastructure

### Resource Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                         Azure Subscription                              │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐  │
│  │                    Resource Group (rg-myapp-dev)                 │  │
│  │                                                                  │  │
│  │   ┌──────────────┐     ┌──────────────┐     ┌──────────────┐   │  │
│  │   │   Azure      │     │    App       │     │   Azure      │   │  │
│  │   │   Front Door │────►│   Service    │────►│   Redis      │   │  │
│  │   │   (CDN/WAF)  │     │   (API)      │     │   Cache      │   │  │
│  │   └──────────────┘     └──────┬───────┘     └──────────────┘   │  │
│  │                               │                                 │  │
│  │                               │ Private Endpoint                │  │
│  │                               ▼                                 │  │
│  │   ┌──────────────┐     ┌──────────────┐     ┌──────────────┐   │  │
│  │   │   Azure      │     │  PostgreSQL  │     │    Blob      │   │  │
│  │   │   Key Vault  │     │   Flexible   │     │   Storage    │   │  │
│  │   │   (Secrets)  │     │   Server     │     │   (Files)    │   │  │
│  │   └──────────────┘     └──────────────┘     └──────────────┘   │  │
│  │                                                                  │  │
│  │   ┌──────────────┐     ┌──────────────┐                        │  │
│  │   │    Log       │     │    App       │                        │  │
│  │   │   Analytics  │◄────│   Insights   │                        │  │
│  │   │   Workspace  │     │  (Telemetry) │                        │  │
│  │   └──────────────┘     └──────────────┘                        │  │
│  │                                                                  │  │
│  └─────────────────────────────────────────────────────────────────┘  │
│                                                                         │
└────────────────────────────────────────────────────────────────────────┘
```

### Environment Configuration

| Resource | Dev | Staging | Production |
|----------|-----|---------|------------|
| **App Service** | B1 | S1 | P1v3 |
| **PostgreSQL** | Burstable B1ms | GP Standard_D2s_v3 | GP Standard_D4s_v3 |
| **Redis** | Basic C0 | Standard C1 | Premium P1 |
| **Replicas** | 1 | 2 | 3+ |
| **Geo-redundancy** | No | No | Yes |

### Scaling Guidelines

```bicep
// Auto-scaling rules (infra/modules/app-service.bicep)
resource autoScaleSettings 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: 'autoscale-${appServiceName}'
  location: location
  properties: {
    targetResourceUri: appServicePlan.id
    enabled: true
    profiles: [
      {
        name: 'Auto scale based on CPU'
        capacity: {
          minimum: '1'
          maximum: '10'
          default: '1'
        }
        rules: [
          {
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
            metricTrigger: {
              metricName: 'CpuPercentage'
              operator: 'GreaterThan'
              threshold: 70
              timeAggregation: 'Average'
              timeWindow: 'PT5M'
            }
          }
        ]
      }
    ]
  }
}
```

---

## Security Best Practices

### Authentication Flow

```
┌─────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────┐
│  User   │────►│  Azure AD   │────►│   API       │────►│  Data   │
│         │     │  / Auth0    │     │   Gateway   │     │  Layer  │
└─────────┘     └─────────────┘     └─────────────┘     └─────────┘
     │                │                    │
     │   1. Login     │                    │
     │───────────────►│                    │
     │                │                    │
     │   2. JWT Token │                    │
     │◄───────────────│                    │
     │                                     │
     │   3. Request + Bearer Token         │
     │────────────────────────────────────►│
     │                                     │
     │                    4. Validate JWT  │
     │                    5. Check Scopes  │
     │                    6. Process       │
     │                                     │
     │   7. Response                       │
     │◄────────────────────────────────────│
```

### Security Checklist

- [ ] HTTPS only (TLS 1.2+)
- [ ] JWT validation on all protected endpoints
- [ ] Input validation (Pydantic schemas)
- [ ] SQL injection protection (ORM/parameterized queries)
- [ ] Rate limiting enabled
- [ ] CORS properly configured
- [ ] Secrets in Key Vault (never in code)
- [ ] Managed Identity for Azure resources
- [ ] Private endpoints for databases
- [ ] WAF enabled on Front Door
- [ ] Security headers (HSTS, CSP, etc.)
- [ ] Dependency scanning (Dependabot)
- [ ] Regular security audits

---

## Testing Strategy

### Test Pyramid

```
          /\
         /  \     E2E Tests (few)
        /    \    - Full API flows
       /──────\   - Critical paths only
      /        \
     /          \ Integration Tests (some)
    /            \ - Repository + DB
   /              \ - External services
  /────────────────\
 /                  \ Unit Tests (many)
/                    \ - Domain logic
/                      \ - Use cases
/────────────────────────\
```

### Example Tests

```python
# tests/unit/domain/test_user_entity.py
import pytest
from domain.entities.user import User
from domain.value_objects.email import Email
from domain.exceptions import InvalidUserError

class TestUserEntity:
    def test_create_valid_user(self):
        user = User(id=1, email=Email("test@example.com"), name="John")
        assert user.name == "John"
        assert user.is_active is True

    def test_create_user_with_short_name_raises(self):
        with pytest.raises(InvalidUserError):
            User(id=1, email=Email("test@example.com"), name="J")

    def test_deactivate_user(self):
        user = User(id=1, email=Email("test@example.com"), name="John")
        user.deactivate()
        assert user.is_active is False
```

```python
# tests/integration/test_user_repository.py
import pytest
from infrastructure.persistence.repositories.sqlalchemy_user_repo import SQLAlchemyUserRepository

class TestUserRepository:
    @pytest.fixture
    def repository(self, db_session):
        return SQLAlchemyUserRepository(db_session)

    def test_save_and_retrieve_user(self, repository):
        user = User(id=None, email=Email("test@example.com"), name="John")
        saved = repository.save(user)

        assert saved.id is not None
        retrieved = repository.get_by_id(saved.id)
        assert retrieved.name == "John"
```

---

## Migration Path: Standard to Hexagonal

### Phase 1: Extract Domain (Week 1-2)

1. Create `domain/` directory
2. Define entities as dataclasses
3. Create repository interfaces
4. Move business logic to domain services

### Phase 2: Create Application Layer (Week 2-3)

1. Create `application/` directory
2. Define use cases for each operation
3. Create DTOs for input/output
4. Inject repository interfaces

### Phase 3: Adapt Infrastructure (Week 3-4)

1. Implement repository interfaces
2. Create API adapters (routers)
3. Set up dependency injection
4. Update tests

### Migration Checklist

- [ ] Domain entities defined
- [ ] Repository interfaces created
- [ ] Use cases implemented
- [ ] Infrastructure adapters built
- [ ] Dependency injection configured
- [ ] Tests updated and passing
- [ ] Documentation updated

---

## Further Reading

### Architecture
- [Hexagonal Architecture - Alistair Cockburn](https://alistair.cockburn.us/hexagonal-architecture/)
- [Clean Architecture - Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Domain-Driven Design - Eric Evans](https://domainlanguage.com/ddd/)

### Azure
- [Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/)
- [Azure Architecture Center](https://docs.microsoft.com/en-us/azure/architecture/)
- [12-Factor App](https://12factor.net/)

### FastAPI
- [FastAPI Best Practices](https://fastapi.tiangolo.com/tutorial/)
- [FastAPI Full Stack Template](https://github.com/tiangolo/full-stack-fastapi-template)

---

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines on contributing to this architecture.
