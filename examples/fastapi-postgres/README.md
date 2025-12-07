# FastAPI + PostgreSQL Example

This is the default stack for the template.

## Stack
- **API**: FastAPI (Python 3.11+)
- **Database**: PostgreSQL 15
- **ORM**: SQLAlchemy
- **Migrations**: Alembic
- **Validation**: Pydantic

## Quick Start

```bash
cd src/api
pip install -r requirements.txt
uvicorn main:app --reload
```

## Features
- Auto-generated OpenAPI docs
- Type validation with Pydantic
- Async database operations
- JWT authentication ready
- CORS configured

## Endpoints
- `GET /` - Health check
- `GET /docs` - Swagger UI
- `GET /redoc` - ReDoc UI
