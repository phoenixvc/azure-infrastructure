"""In-memory cache implementation for development and testing."""

import asyncio
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Set
from dataclasses import dataclass, field

from .base import BaseCache, CacheHealth


@dataclass
class CacheEntry:
    """Cache entry with optional expiration."""

    value: Any
    expires_at: Optional[datetime] = None

    def is_expired(self) -> bool:
        """Check if entry has expired."""
        if self.expires_at is None:
            return False
        return datetime.utcnow() > self.expires_at


class InMemoryCache(BaseCache, CacheHealth):
    """In-memory cache implementation.

    Suitable for:
    - Local development
    - Unit testing
    - Single-instance deployments

    Not suitable for:
    - Production multi-instance deployments
    - Persistent caching
    - Large datasets

    Example:
        ```python
        cache = InMemoryCache()
        await cache.set("key", "value", ttl=timedelta(minutes=5))
        value = await cache.get("key")
        ```
    """

    def __init__(self):
        self._store: Dict[str, CacheEntry] = {}
        self._hashes: Dict[str, Dict[str, str]] = {}
        self._sets: Dict[str, Set[str]] = {}

    def _cleanup_expired(self, key: str) -> bool:
        """Remove entry if expired. Returns True if removed."""
        if key in self._store and self._store[key].is_expired():
            del self._store[key]
            return True
        return False

    # --- String Operations ---

    async def get(self, key: str) -> Optional[str]:
        self._cleanup_expired(key)
        entry = self._store.get(key)
        return entry.value if entry else None

    async def set(
        self,
        key: str,
        value: str,
        ttl: Optional[timedelta] = None,
    ) -> bool:
        expires_at = datetime.utcnow() + ttl if ttl else None
        self._store[key] = CacheEntry(value=value, expires_at=expires_at)
        return True

    async def delete(self, key: str) -> bool:
        if key in self._store:
            del self._store[key]
            return True
        return False

    async def exists(self, key: str) -> bool:
        self._cleanup_expired(key)
        return key in self._store

    async def expire(self, key: str, ttl: timedelta) -> bool:
        if key not in self._store:
            return False
        self._store[key].expires_at = datetime.utcnow() + ttl
        return True

    # --- Batch Operations ---

    async def mget(self, keys: List[str]) -> List[Optional[str]]:
        return [await self.get(key) for key in keys]

    async def mset(self, mapping: dict[str, str]) -> bool:
        for key, value in mapping.items():
            await self.set(key, value)
        return True

    # --- Counter Operations ---

    async def incr(self, key: str, amount: int = 1) -> int:
        current = await self.get(key)
        new_value = int(current or 0) + amount
        await self.set(key, str(new_value))
        return new_value

    async def decr(self, key: str, amount: int = 1) -> int:
        return await self.incr(key, -amount)

    # --- Hash Operations ---

    async def hget(self, name: str, key: str) -> Optional[str]:
        hash_data = self._hashes.get(name, {})
        return hash_data.get(key)

    async def hset(self, name: str, key: str, value: str) -> bool:
        if name not in self._hashes:
            self._hashes[name] = {}
        is_new = key not in self._hashes[name]
        self._hashes[name][key] = value
        return is_new

    async def hgetall(self, name: str) -> dict[str, str]:
        return dict(self._hashes.get(name, {}))

    async def hdel(self, name: str, *keys: str) -> int:
        if name not in self._hashes:
            return 0
        deleted = 0
        for key in keys:
            if key in self._hashes[name]:
                del self._hashes[name][key]
                deleted += 1
        return deleted

    # --- Set Operations ---

    async def sadd(self, key: str, *values: str) -> int:
        if key not in self._sets:
            self._sets[key] = set()
        initial_size = len(self._sets[key])
        self._sets[key].update(values)
        return len(self._sets[key]) - initial_size

    async def smembers(self, key: str) -> Set[str]:
        return set(self._sets.get(key, set()))

    async def sismember(self, key: str, value: str) -> bool:
        return value in self._sets.get(key, set())

    # --- Utility Operations ---

    async def keys(self, pattern: str) -> List[str]:
        import fnmatch

        # Clean up expired keys first
        for key in list(self._store.keys()):
            self._cleanup_expired(key)

        return [key for key in self._store.keys() if fnmatch.fnmatch(key, pattern)]

    async def flush(self) -> bool:
        self._store.clear()
        self._hashes.clear()
        self._sets.clear()
        return True

    # --- Health Operations ---

    async def is_healthy(self) -> bool:
        return True

    async def get_status(self) -> dict:
        return {
            "type": "in-memory",
            "keys_count": len(self._store),
            "hashes_count": len(self._hashes),
            "sets_count": len(self._sets),
            "healthy": True,
        }

    async def ping(self) -> bool:
        return True
