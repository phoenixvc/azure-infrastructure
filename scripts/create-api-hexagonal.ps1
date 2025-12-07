# Create Hexagonal API files

$userEntity = @"
from dataclasses import dataclass
from datetime import datetime
from typing import Optional

@dataclass
class User:
    """User domain entity"""
    id: Optional[int]
    email: str
    name: str
    password_hash: str
    created_at: datetime
    updated_at: datetime
    
    def is_valid_email(self) -> bool:
        return '@' in self.email and '.' in self.email.split('@')[1]
"@

$userEntity | Out-File -FilePath "src/api-hexagonal/domain/entities/user.py" -Encoding UTF8

$userRepo = @"
from abc import ABC, abstractmethod
from typing import Optional
from domain.entities.user import User

class UserRepository(ABC):
    """Repository interface for User entity"""
    
    @abstractmethod
    async def create(self, user: User) -> User:
        pass
    
    @abstractmethod
    async def get_by_id(self, user_id: int) -> Optional[User]:
        pass
    
    @abstractmethod
    async def get_by_email(self, email: str) -> Optional[User]:
        pass
"@

$userRepo | Out-File -FilePath "src/api-hexagonal/domain/repositories/user_repository.py" -Encoding UTF8

$hexReadme = @"
# API - Hexagonal Architecture

Clean architecture with domain-driven design.

## Structure
- domain/ - Core business logic
- application/ - Use cases
- infrastructure/ - External dependencies
- adapters/ - Interface adapters

## Run
``````bash
pip install -r requirements.txt
uvicorn adapters.api.main:app --reload
``````
"@

$hexReadme | Out-File -FilePath "src/api-hexagonal/README.md" -Encoding UTF8

$hexReqs = @"
fastapi==0.109.0
uvicorn[standard]==0.27.0
pydantic==2.5.3
sqlalchemy==2.0.25
asyncpg==0.29.0
"@

$hexReqs | Out-File -FilePath "src/api-hexagonal/requirements.txt" -Encoding UTF8

Write-Host "  ✓ Hexagonal API" -ForegroundColor Green
