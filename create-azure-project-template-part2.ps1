# ============================================================================
# Create azure-project-template Part 2: Implementations
# ============================================================================
# Run from: C:\Users\smitj\repos\azure-project-template
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host "🔧 Part 2: Creating implementations..." -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Verify we're in the right place
if (-not (Test-Path ".git")) {
  Write-Host "❌ Error: Not in azure-project-template repo" -ForegroundColor Red
  exit 1
}

# ============================================================================
# 1. Create Standard API Implementation
# ============================================================================
Write-Host "`n📝 Creating Standard API implementation..." -ForegroundColor Yellow

# main.py
@'
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import logging
from datetime import datetime

from app.config import settings
from app.routers import health, users

# Configure logging
logging.basicConfig(
  level=getattr(logging, settings.log_level),
  format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
  title=settings.app_name,
  version="1.0.0",
  description="API built with phoenixvc standards"
)

# CORS middleware
app.add_middleware(
  CORSMiddleware,
  allow_origins=settings.cors_origins,
  allow_credentials=True,
  allow_methods=["*"],
  allow_headers=["*"],
)

# Exception handler
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
  logger.error(f"Global exception: {exc}", exc_info=True)
  return JSONResponse(
      status_code=500,
      content={"detail": "Internal server error"}
  )

# Include routers
app.include_router(health.router, tags=["health"])
app.include_router(users.router, prefix="/api/v1", tags=["users"])

@app.on_event("startup")
async def startup_event():
  logger.info(f"Starting {settings.app_name}")
  logger.info(f"Environment: {settings.env}")

@app.on_event("shutdown")
async def shutdown_event():
  logger.info(f"Shutting down {settings.app_name}")
'@ | Out-File -FilePath "src/api-standard/app/main.py" -Encoding UTF8
Write-Host "  ✓ Created src/api-standard/app/main.py" -ForegroundColor Green

# config.py
@'
from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
  app_name: str = "API"
  env: str = "dev"
  log_level: str = "INFO"
  
  # Database
  database_url: str = "postgresql://user:pass@localhost/db"
  
  # CORS
  cors_origins: List[str] = ["http://localhost:3000", "http://localhost:5173"]
  
  # Azure
  azure_storage_connection_string: str = ""
  azure_key_vault_url: str = ""
  
  class Config:
      env_file = ".env"

settings = Settings()
'@ | Out-File -FilePath "src/api-standard/app/config.py" -Encoding UTF8
Write-Host "  ✓ Created src/api-standard/app/config.py" -ForegroundColor Green

# models.py
@'
from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional

class UserBase(BaseModel):
  email: EmailStr
  name: str

class UserCreate(UserBase):
  password: str

class UserUpdate(BaseModel):
  email: Optional[EmailStr] = None
  name: Optional[str] = None

class User(UserBase):
  id: int
  created_at: datetime
  updated_at: datetime
  
  class Config:
      from_attributes = True
'@ | Out-File -FilePath "src/api-standard/app/models.py" -Encoding UTF8
Write-Host "  ✓ Created src/api-standard/app/models.py" -ForegroundColor Green

# database.py
@'
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.config import settings

engine = create_engine(settings.database_url)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
  db = SessionLocal()
  try:
      yield db
  finally:
      db.close()
'@ | Out-File -FilePath "src/api-standard/app/database.py" -Encoding UTF8
Write-Host "  ✓ Created src/api-standard/app/database.py" -ForegroundColor Green

# routers/health.py
@'
from fastapi import APIRouter
from datetime import datetime

router = APIRouter()

@router.get("/health")
async def health_check():
  return {
      "status": "healthy",
      "timestamp": datetime.utcnow().isoformat(),
      "version": "1.0.0"
  }

@router.get("/ready")
async def readiness_check():
  # Add database connectivity check here
  return {
      "status": "ready",
      "timestamp": datetime.utcnow().isoformat()
  }
'@ | Out-File -FilePath "src/api-standard/app/routers/health.py" -Encoding UTF8
Write-Host "  ✓ Created src/api-standard/app/routers/health.py" -ForegroundColor Green

# routers/users.py
@'
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db
from app.models import User, UserCreate, UserUpdate

router = APIRouter()

@router.post("/users", response_model=User, status_code=201)
def create_user(user: UserCreate, db: Session = Depends(get_db)):
  """Create a new user"""
  # TODO: Implement user creation logic
  # - Hash password
  # - Check if email exists
  # - Save to database
  raise HTTPException(status_code=501, detail="Not implemented")

@router.get("/users", response_model=List[User])
def list_users(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
  """List all users"""
  # TODO: Implement user listing logic
  raise HTTPException(status_code=501, detail="Not implemented")

@router.get("/users/{user_id}", response_model=User)
def get_user(user_id: int, db: Session = Depends(get_db)):
  """Get user by ID"""
  # TODO: Implement get user logic
  raise HTTPException(status_code=501, detail="Not implemented")

@router.put("/users/{user_id}", response_model=User)
def update_user(user_id: int, user: UserUpdate, db: Session = Depends(get_db)):
  """Update user"""
  # TODO: Implement user update logic
  raise HTTPException(status_code=501, detail="Not implemented")

@router.delete("/users/{user_id}", status_code=204)
def delete_user(user_id: int, db: Session = Depends(get_db)):
  """Delete user"""
  # TODO: Implement user deletion logic
  raise HTTPException(status_code=501, detail="Not implemented")
'@ | Out-File -FilePath "src/api-standard/app/routers/users.py" -Encoding UTF8
Write-Host "  ✓ Created src/api-standard/app/routers/users.py" -ForegroundColor Green

# __init__.py files
New-Item -ItemType File -Path "src/api-standard/app/__init__.py" -Force | Out-Null
New-Item -ItemType File -Path "src/api-standard/app/routers/__init__.py" -Force | Out-Null
Write-Host "  ✓ Created __init__.py files" -ForegroundColor Green

# Dockerfile
@'
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY app/ ./app/

# Expose port
EXPOSE 8000

# Run application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
'@ | Out-File -FilePath "src/api-standard/Dockerfile" -Encoding UTF8
Write-Host "  ✓ Created src/api-standard/Dockerfile" -ForegroundColor Green

# requirements.txt
@'
fastapi==0.109.0
uvicorn[standard]==0.27.0
pydantic==2.5.3
pydantic-settings==2.1.0
python-dotenv==1.0.0
sqlalchemy==2.0.25
asyncpg==0.29.0
psycopg2-binary==2.9.9
azure-identity==1.15.0
azure-keyvault-secrets==4.7.0
azure-storage-blob==12.19.0
'@ | Out-File -FilePath "src/api-standard/requirements.txt" -Encoding UTF8
Write-Host "  ✓ Created src/api-standard/requirements.txt" -ForegroundColor Green

# README.md
@'
# API - Standard Architecture

FastAPI application with standard layered architecture.

---

## Structure

```
app/
├── main.py              # FastAPI application entry point
├── config.py            # Configuration management
├── models.py            # Pydantic models
├── database.py          # Database connection
└── routers/
  ├── health.py        # Health check endpoints
  └── users.py         # User endpoints
```

---

## Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Create .env file
cat > .env << EOF
DATABASE_URL=postgresql://user:pass@localhost/mydb
LOG_LEVEL=DEBUG
EOF

# Run locally
uvicorn app.main:app --reload --port 8000

# Test
curl http://localhost:8000/health
```

---

## Docker

```bash
# Build
docker build -t api:latest .

# Run
docker run -p 8000:8000 -e DATABASE_URL=postgresql://... api:latest
```

---

## API Documentation

Once running, visit:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc
'@ | Out-File -FilePath "src/api-standard/README.md" -Encoding UTF8
Write-Host "  ✓ Created src/api-standard/README.md" -ForegroundColor Green

# ============================================================================
# 2. Create Hexagonal API Implementation
# ============================================================================
Write-Host "`n📝 Creating Hexagonal API implementation..." -ForegroundColor Yellow

# Domain entities
@'
from dataclasses import dataclass
from datetime import datetime
from typing import Optional

@dataclass
class User:
  id: Optional[int]
  email: str
  name: str
  password_hash: str
  created_at: datetime
  updated_at: datetime
  
  def __post_init__(self):
      if self.id is None:
          self.id = 0
'@ | Out-File -FilePath "src/api-hexagonal/domain/entities/user.py" -Encoding UTF8
Write-Host "  ✓ Created src/api-hexagonal/domain/entities/user.py" -ForegroundColor Green

# Domain repository interface
@'
from abc import ABC, abstractmethod
from typing import Optional, List
from domain.entities.user import User

class UserRepository(ABC):
  @abstractmethod
  def create(self, user: User) -> User:
      """Create a new user"""
      pass
  
  @abstractmethod
  def get_by_id(self, user_id: int) -> Optional[User]:
      """Get user by ID"""
      pass
  
  @abstractmethod
  def get_by_email(self, email: str) -> Optional[User]:
      """Get user by email"""
      pass
  
  @abstractmethod
  def list_all(self, skip: int = 0, limit: int = 100) -> List[User]:
      """List all users"""
      pass
  
  @abstractmethod
  def update(self, user: User) -> User:
      """Update user"""
      pass
  
  @abstractmethod
  def delete(self, user_id: int) -> bool:
      """Delete user"""
      pass
'@ | Out-File -FilePath "src/api-hexagonal/domain/repositories/user_repository.py" -Encoding UTF8
Write-Host "  ✓ Created src/api-hexagonal/domain/repositories/user_repository.py" -ForegroundColor Green

# Use case: Create User
@'
from datetime import datetime
from domain.entities.user import User
from domain.repositories.user_repository import UserRepository

class CreateUserUseCase:
  def __init__(self, user_repository: UserRepository):
      self.user_repository = user_repository
  
  def execute(self, email: str, name: str, password: str) -> User:
      # Check if user exists
      existing_user = self.user_repository.get_by_email(email)
      if existing_user:
          raise ValueError("User with this email already exists")
      
      # Hash password (simplified - use proper hashing in production)
      password_hash = f"hashed_{password}"
      
      # Create user entity
      user = User(
          id=None,
          email=email,
          name=name,
          password_hash=password_hash,
          created_at=datetime.utcnow(),
          updated_at=datetime.utcnow()
      )
      
      # Save to repository
      return self.user_repository.create(user)
'@ | Out-File -FilePath "src/api-hexagonal/application/use_cases/create_user.py" -Encoding UTF8
Write-Host "  ✓ Created src/api-hexagonal/application/use_cases/create_user.py" -ForegroundColor Green

# Use case: Get User
@'
from typing import Optional
from domain.entities.user import User
from domain.repositories.user_repository import UserRepository

class GetUserUseCase:
  def __init__(self, user_repository: UserRepository):
      self.user_repository = user_repository
  
  def execute(self, user_id: int) -> Optional[User]:
      return self.user_repository.get_by_id(user_id)
'@ | Out-File -FilePath "src/api-hexagonal/application/use_cases/get_user.py" -Encoding UTF8
Write-Host "  ✓ Created src/api-hexagonal/application/use_cases/get_user.py" -ForegroundColor Green

# Infrastructure: Database models
@'
from sqlalchemy import Column, Integer, String, DateTime
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime

Base = declarative_base()

class UserModel(Base):
  __tablename__ = "users"
  
  id = Column(Integer, primary_key=True, index=True)
  email = Column(String, unique=True, index=True, nullable=False)
  name = Column(String, nullable=False)
  password_hash = Column(String, nullable=False)
  created_at = Column(DateTime, default=datetime.utcnow)
  updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
'@ | Out-File -FilePath "src/api-hexagonal/infrastructure/database/models.py" -Encoding UTF8
Write-Host "  ✓ Created src/api-hexagonal/infrastructure/database/models.py" -ForegroundColor Green

# Infrastructure: Repository implementation
@'
from typing import Optional, List
from sqlalchemy.orm import Session
from domain.entities.user import User
from domain.repositories.user_repository import UserRepository
from infrastructure.database.models import UserModel

class UserRepositoryImpl(UserRepository):
  def __init__(self, db: Session):
      self.db = db
  
  def create(self, user: User) -> User:
      db_user = UserModel(
          email=user.email,
          name=user.name,
          password_hash=user.password_hash
      )
      self.db.add(db_user)
      self.db.commit()
      self.db.refresh(db_user)
      return self._to_entity(db_user)
  
  def get_by_id(self, user_id: int) -> Optional[User]:
      db_user = self.db.query(UserModel).filter(UserModel.id == user_id).first()
      return self._to_entity(db_user) if db_user else None
  
  def get_by_email(self, email: str) -> Optional[User]:
      db_user = self.db.query(UserModel).filter(UserModel.email == email).first()
      return self._to_entity(db_user) if db_user else None
  
  def list_all(self, skip: int = 0, limit: int = 100) -> List[User]:
      db_users = self.db.query(UserModel).offset(skip).limit(limit).all()
      return [self._to_entity(db_user) for db_user in db_users]
  
  def update(self, user: User) -> User:
      db_user = self.db.query(UserModel).filter(UserModel.id == user.id).first()
      if not db_user:
          raise ValueError("User not found")
      
      db_user.email = user.email
      db_user.name = user.name
      self.db.commit()
      self.db.refresh(db_user)
      return self._to_entity(db_user)
  
  def delete(self, user_id: int) -> bool:
      db_user = self.db.query(UserModel).filter(UserModel.id == user_id).first()
      if not db_user:
          return False
      
      self.db.delete(db_user)
      self.db.commit()
      return True
  
  def _to_entity(self, db_user: UserModel) -> User:
      return User(
          id=db_user.id,
          email=db_user.email,
          name=db_user.name,
          password_hash=db_user.password_hash,
          created_at=db_user.created_at,
          updated_at=db_user.updated_at
      )
'@ | Out-File -FilePath "src/api-hexagonal/infrastructure/database/user_repository_impl.py" -Encoding UTF8
Write-Host "  ✓ Created src/api-hexagonal/infrastructure/database/user_repository_impl.py" -ForegroundColor Green

# Infrastructure: Database connection
@'
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

DATABASE_URL = "postgresql://user:pass@localhost/db"

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
  db = SessionLocal()
  try:
      yield db
  finally:
      db.close()
'@ | Out-File -FilePath "src/api-hexagonal/infrastructure/database/database.py" -Encoding UTF8
Write-Host "  ✓ Created src/api-hexagonal/infrastructure/database/database.py" -ForegroundColor Green

# Adapters: API schemas
@'
from pydantic import BaseModel, EmailStr
from datetime import datetime

class UserCreate(BaseModel):
  email: EmailStr
  name: str
  password: str

class UserResponse(BaseModel):
  id: int
  email: str
  name: str
  created_at: datetime
  updated_at: datetime
  
  @classmethod
  def from_entity(cls, user):
      return cls(
          id=user.id,
          email=user.email,
          name=user.name,
          created_at=user.created_at,
          updated_at=user.updated_at
      )
'@ | Out-File -FilePath "src/api-hexagonal/adapters/api/schemas.py" -Encoding UTF8
Write-Host "  ✓ Created src/api-hexagonal/adapters/api/schemas.py" -ForegroundColor Green

# Adapters: Dependencies
@'
from fastapi import Depends
from sqlalchemy.orm import Session
from infrastructure.database.database import get_db
from infrastructure.database.user_repository_impl import UserRepositoryImpl
from application.use_cases.create_user import CreateUserUseCase
from application.use_cases.get_user import GetUserUseCase

def get_user_repository(db: Session = Depends(get_db)):
  return UserRepositoryImpl(db)

def get_create_user_use_case(repo = Depends(get_user_repository)):
  return CreateUserUseCase(repo)

def get_get_user_use_case(repo = Depends(get_user_repository)):
  return GetUserUseCase(repo)
'@ | Out-File -FilePath "src/api-hexagonal/adapters/api/dependencies.py" -Encoding UTF8
Write-Host "  ✓ Created src/api-hexagonal/adapters/api/dependencies.py" -ForegroundColor Green

# Adapters: Router
@'
from fastapi import APIRouter, Depends, HTTPException
from adapters.api.schemas import UserCreate, UserResponse
from adapters.api.dependencies import get_create_user_use_case, get_get_user_use_case
from application.use_cases.create_user import CreateUserUseCase
from application.use_cases.get_user import GetUserUseCase

router = APIRouter()

@router.post("/users", response_model=UserResponse, status_code=201)
def create_user(
  user: UserCreate,
  use_case: CreateUserUseCase = Depends(get_create_user_use_case)
):
  try:
      created_user = use_case.execute(user.email, user.name, user.password)
      return UserResponse.from_entity(created_user)
  except ValueError as e:
      raise HTTPException(status_code=400, detail=str(e))

@router.get("/users/{user_id}", response_model=UserResponse)
def get_user(
  user_id: int,
  use_case: GetUserUseCase = Depends(get_get_user_use_case)
):
  user = use_case.execute(user_id)
  if not user:
      raise HTTPException(status_code=404, detail="User not found")
  return UserResponse.from_entity(user)
'@ | Out-File -FilePath "src/api-hexagonal/adapters/api/routers/users.py" -Encoding UTF8
Write-Host "  ✓ Created src/api-hexagonal/adapters/api/routers/users.py" -ForegroundColor Green

# Adapters: Health router
@'
from fastapi import APIRouter
from datetime import datetime

router = APIRouter()

@router.get("/health")
async def health_check():
  return {
      "status": "healthy",
      "timestamp": datetime.utcnow().isoformat(),
      "version": "1.0.0"
  }
'@ | Out-File -FilePath "src/api-hexagonal/adapters/api/routers/health.py" -Encoding UTF8
Write-Host "  ✓ Created src/api-hexagonal/adapters/api/routers/health.py" -ForegroundColor Green

# Adapters: Main app
@'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from adapters.api.routers import health, users

app = FastAPI(
  title="API - Hexagonal Architecture",
  version="1.0.0"
)

app.add_middleware(
  CORSMiddleware,
  allow_origins=["*"],
  allow_credentials=True,
  allow_methods=["*"],
  allow_headers=["*"],
)

app.include_router(health.router, tags=["health"])
app.include_router(users.router, prefix="/api/v1", tags=["users"])
'@ | Out-File -FilePath "src/api-hexagonal/adapters/api/main.py" -Encoding UTF8
Write-Host "  ✓ Created src/api-hexagonal/adapters/api/main.py" -ForegroundColor Green

# Create all __init__.py files for hexagonal
$hexInitFiles = @(
  "src/api-hexagonal/domain/__init__.py",
  "src/api-hexagonal/domain/entities/__init__.py",
  "src/api-hexagonal/domain/repositories/__init__.py",
  "src/api-hexagonal/application/__init__.py",
  "src/api-hexagonal/application/use_cases/__init__.py",
  "src/api-hexagonal/infrastructure/__init__.py",
  "src/api-hexagonal/infrastructure/database/__init__.py",
  "src/api-hexagonal/infrastructure/external/__init__.py",
  "src/api-hexagonal/adapters/__init__.py",
  "src/api-hexagonal/adapters/api/__init__.py",
  "src/api-hexagonal/adapters/api/routers/__init__.py"
)

foreach ($file in $hexInitFiles) {
  New-Item -ItemType File -Path $file -Force | Out-Null
}
Write-Host "  ✓ Created __init__.py files for hexagonal" -ForegroundColor Green

# Hexagonal Dockerfile
@'
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["uvicorn", "adapters.api.main:app", "--host", "0.0.0.0", "--port", "8000"]
'@ | Out-File -FilePath "src/api-hexagonal/Dockerfile" -Encoding UTF8
Write-Host "  ✓ Created src/api-hexagonal/Dockerfile" -ForegroundColor Green

# Hexagonal requirements.txt
@'
fastapi==0.109.0
uvicorn[standard]==0.27.0
pydantic==2.5.3
sqlalchemy==2.0.25
asyncpg==0.29.0
psycopg2-binary==2.9.9
'@ | Out-File -FilePath "src/api-hexagonal/requirements.txt" -Encoding UTF8
Write-Host "  ✓ Created src/api-hexagonal/requirements.txt" -ForegroundColor Green

# Hexagonal README
@'
# API - Hexagonal Architecture

FastAPI application with hexagonal (ports and adapters) architecture.

---

## Structure

```
├── domain/              # Core business logic
│   ├── entities/        # Domain entities
│   └── repositories/    # Repository interfaces
├── application/         # Use cases
│   └── use_cases/       # Application logic
├── infrastructure/      # External dependencies
│   └── database/        # Database implementation
└── adapters/            # Interface adapters
  └── api/             # FastAPI routes
```

---

## Local Development

```bash
pip install -r requirements.txt
uvicorn adapters.api.main:app --reload --port 8000
```

---

## Testing

The hexagonal architecture makes testing easy:

```python
# Test use case without database
from application.use_cases.create_user import CreateUserUseCase
from tests.mocks import MockUserRepository

def test_create_user():
  repo = MockUserRepository()
  use_case = CreateUserUseCase(repo)
  user = use_case.execute("test@example.com", "Test User", "password")
  assert user.email == "test@example.com"
```
'@ | Out-File -FilePath "src/api-hexagonal/README.md" -Encoding UTF8
Write-Host "  ✓ Created src/api-hexagonal/README.md" -ForegroundColor Green

Write-Host "`n✅ Part 2 implementations created!" -ForegroundColor Green
Write-Host "`n📍 Next: Run create-azure-project-template-part3.ps1 for Web + Infrastructure" -ForegroundColor Cyan