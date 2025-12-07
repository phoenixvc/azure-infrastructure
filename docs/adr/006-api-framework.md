# ADR-006: API Framework Selection

## Status

Accepted

## Date

2025-12-07

## Context

We need a Python web framework for building REST APIs that:
- Handles high concurrency efficiently
- Provides automatic API documentation
- Supports async operations for I/O-bound workloads
- Integrates well with Python ecosystem (SQLAlchemy, Pydantic)
- Enables rapid development with good developer experience

## Decision Drivers

- **Performance**: Async support for high concurrency
- **Documentation**: Auto-generated OpenAPI specs
- **Type Safety**: Pydantic integration for validation
- **Ecosystem**: Middleware, extensions, and community
- **Learning Curve**: Time to productivity

## Considered Options

1. **FastAPI**
2. **Django REST Framework**
3. **Flask + Flask-RESTful**
4. **Starlette**
5. **aiohttp**

## Evaluation Matrix

| Criterion | Weight | FastAPI | Django RF | Flask | Starlette | aiohttp |
|-----------|--------|---------|-----------|-------|-----------|---------|
| Async Performance | 5 | 5 (25) | 2 (10) | 2 (10) | 5 (25) | 5 (25) |
| Auto Documentation | 5 | 5 (25) | 3 (15) | 2 (10) | 3 (15) | 2 (10) |
| Type Safety | 5 | 5 (25) | 2 (10) | 2 (10) | 3 (15) | 2 (10) |
| Pydantic Integration | 4 | 5 (20) | 2 (8) | 2 (8) | 4 (16) | 2 (8) |
| SQLAlchemy Async | 4 | 5 (20) | 3 (12) | 3 (12) | 5 (20) | 4 (16) |
| Learning Curve | 4 | 4 (16) | 3 (12) | 5 (20) | 4 (16) | 3 (12) |
| Dependency Injection | 4 | 5 (20) | 4 (16) | 2 (8) | 3 (12) | 2 (8) |
| Community/Ecosystem | 3 | 4 (12) | 5 (15) | 5 (15) | 3 (9) | 3 (9) |
| **Total** | **34** | **163** | **98** | **93** | **128** | **98** |

### Scoring Guide
- **Weight**: 1 (Nice to have) → 5 (Critical)
- **Score**: 1 (Poor) → 5 (Excellent)

## Decision

**FastAPI** as the API framework.

## Rationale

FastAPI scored significantly higher due to:

1. **Native async support**: Built on Starlette's ASGI foundation for true async performance.

2. **Automatic OpenAPI**: Request/response models generate Swagger and ReDoc docs automatically.

3. **Pydantic integration**: First-class type validation with detailed error messages.

4. **Dependency injection**: Built-in DI system for clean, testable code.

5. **Modern Python**: Leverages type hints for better IDE support and documentation.

## Consequences

### Positive

- Exceptional performance (comparable to Node.js/Go)
- Interactive API documentation out-of-box
- Type hints catch bugs at development time
- Easy testing with TestClient
- Great async database/cache integration
- Active community and rapid development

### Negative

- Requires Python 3.8+ (type hints)
- Async complexity for simple use cases
- Less mature than Django for full-stack apps
- Some plugins still catching up to async

### Risks and Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Async complexity | Medium | Medium | Provide team training, code reviews |
| Breaking changes | Low | Medium | Pin versions, review changelogs |
| Scaling issues | Low | Medium | Use proper connection pooling |
| Missing features | Low | Low | Starlette middleware compatible |

## Implementation Notes

### Project Structure

```
src/api/
├── app/
│   ├── __init__.py
│   ├── main.py           # App factory
│   ├── config.py         # Settings management
│   ├── models.py         # Pydantic schemas
│   ├── database/         # SQLAlchemy async
│   ├── middleware/       # Auth, logging, etc.
│   └── routers/          # API endpoints
│       ├── __init__.py
│       ├── health.py
│       └── items.py
└── requirements.txt
```

### Application Factory

```python
def create_app() -> FastAPI:
    app = FastAPI(
        title="Azure Infrastructure API",
        version="1.0.0",
        docs_url="/docs",
        redoc_url="/redoc",
    )

    # Add middleware
    app.add_middleware(CORSMiddleware, ...)

    # Include routers
    app.include_router(health_router)
    app.include_router(items_router, prefix="/api/v1")

    return app
```

### Router Pattern

```python
from fastapi import APIRouter, Depends, HTTPException

router = APIRouter(prefix="/items", tags=["Items"])

@router.get("", response_model=List[Item])
async def list_items(
    skip: int = 0,
    limit: int = 100,
    db = Depends(get_db),
) -> List[Item]:
    return await repository.get_all(db, skip, limit)
```

### Pydantic Models

```python
from pydantic import BaseModel, Field

class ItemBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    price: float = Field(..., ge=0)

class Item(ItemBase):
    id: UUID
    created_at: datetime

    class Config:
        from_attributes = True  # ORM mode
```

### Dependency Injection

```python
async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db = Depends(get_db),
) -> User:
    user = await authenticate(token, db)
    if not user:
        raise HTTPException(401, "Invalid credentials")
    return user

@router.get("/me")
async def get_me(user: User = Depends(get_current_user)):
    return user
```

## References

- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Starlette Framework](https://www.starlette.io/)
- [Pydantic v2](https://docs.pydantic.dev/latest/)
- [SQLAlchemy Async](https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html)
