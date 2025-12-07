"""Cache module with abstract interfaces and implementations."""

from .base import BaseCache, CacheHealth
from .memory import InMemoryCache

__all__ = [
    # Abstract interfaces
    "BaseCache",
    "CacheHealth",
    # Implementations
    "InMemoryCache",
]
