"""Abstract base classes for caching operations.

These abstractions allow swapping cache implementations without
changing business logic. Implementations can be:
- Redis (via aioredis or redis-py async)
- In-memory (for testing/development)
- Memcached
- Azure Cache for Redis
"""

from abc import ABC, abstractmethod
from typing import Any, Optional, List, Set
from datetime import timedelta


class BaseCache(ABC):
    """Abstract base cache defining common operations.

    This interface defines the contract for all cache implementations.
    Business logic depends on this abstraction, not concrete implementations.

    Example:
        ```python
        class RedisCache(BaseCache):
            async def get(self, key: str) -> Optional[str]:
                return await self.client.get(key)

        class InMemoryCache(BaseCache):
            async def get(self, key: str) -> Optional[str]:
                return self._store.get(key)
        ```
    """

    # --- String Operations ---

    @abstractmethod
    async def get(self, key: str) -> Optional[str]:
        """Get a value by key.

        Args:
            key: Cache key

        Returns:
            Value if found, None otherwise
        """
        pass

    @abstractmethod
    async def set(
        self,
        key: str,
        value: str,
        ttl: Optional[timedelta] = None,
    ) -> bool:
        """Set a value with optional TTL.

        Args:
            key: Cache key
            value: Value to store
            ttl: Time to live (None = no expiration)

        Returns:
            True if successful
        """
        pass

    @abstractmethod
    async def delete(self, key: str) -> bool:
        """Delete a key.

        Args:
            key: Cache key

        Returns:
            True if key existed and was deleted
        """
        pass

    @abstractmethod
    async def exists(self, key: str) -> bool:
        """Check if a key exists.

        Args:
            key: Cache key

        Returns:
            True if key exists
        """
        pass

    @abstractmethod
    async def expire(self, key: str, ttl: timedelta) -> bool:
        """Set expiration on an existing key.

        Args:
            key: Cache key
            ttl: Time to live

        Returns:
            True if key exists and TTL was set
        """
        pass

    # --- Batch Operations ---

    @abstractmethod
    async def mget(self, keys: List[str]) -> List[Optional[str]]:
        """Get multiple values by keys.

        Args:
            keys: List of cache keys

        Returns:
            List of values (None for missing keys)
        """
        pass

    @abstractmethod
    async def mset(self, mapping: dict[str, str]) -> bool:
        """Set multiple key-value pairs.

        Args:
            mapping: Dict of key-value pairs

        Returns:
            True if successful
        """
        pass

    # --- Counter Operations ---

    @abstractmethod
    async def incr(self, key: str, amount: int = 1) -> int:
        """Increment a counter.

        Args:
            key: Cache key
            amount: Amount to increment by

        Returns:
            New value after increment
        """
        pass

    @abstractmethod
    async def decr(self, key: str, amount: int = 1) -> int:
        """Decrement a counter.

        Args:
            key: Cache key
            amount: Amount to decrement by

        Returns:
            New value after decrement
        """
        pass

    # --- Hash Operations ---

    @abstractmethod
    async def hget(self, name: str, key: str) -> Optional[str]:
        """Get a hash field value.

        Args:
            name: Hash name
            key: Field key

        Returns:
            Field value if found
        """
        pass

    @abstractmethod
    async def hset(self, name: str, key: str, value: str) -> bool:
        """Set a hash field value.

        Args:
            name: Hash name
            key: Field key
            value: Field value

        Returns:
            True if field is new, False if updated
        """
        pass

    @abstractmethod
    async def hgetall(self, name: str) -> dict[str, str]:
        """Get all fields from a hash.

        Args:
            name: Hash name

        Returns:
            Dict of all field-value pairs
        """
        pass

    @abstractmethod
    async def hdel(self, name: str, *keys: str) -> int:
        """Delete hash fields.

        Args:
            name: Hash name
            keys: Field keys to delete

        Returns:
            Number of fields deleted
        """
        pass

    # --- Set Operations ---

    @abstractmethod
    async def sadd(self, key: str, *values: str) -> int:
        """Add members to a set.

        Args:
            key: Set key
            values: Values to add

        Returns:
            Number of new members added
        """
        pass

    @abstractmethod
    async def smembers(self, key: str) -> Set[str]:
        """Get all members of a set.

        Args:
            key: Set key

        Returns:
            Set of all members
        """
        pass

    @abstractmethod
    async def sismember(self, key: str, value: str) -> bool:
        """Check if value is a member of set.

        Args:
            key: Set key
            value: Value to check

        Returns:
            True if value is a member
        """
        pass

    # --- Utility Operations ---

    @abstractmethod
    async def keys(self, pattern: str) -> List[str]:
        """Find keys matching pattern.

        Args:
            pattern: Glob-style pattern (e.g., "user:*")

        Returns:
            List of matching keys
        """
        pass

    @abstractmethod
    async def flush(self) -> bool:
        """Delete all keys (use with caution!).

        Returns:
            True if successful
        """
        pass


class CacheHealth(ABC):
    """Abstract interface for cache health checking."""

    @abstractmethod
    async def is_healthy(self) -> bool:
        """Check if cache is healthy and accepting connections.

        Returns:
            True if healthy, False otherwise
        """
        pass

    @abstractmethod
    async def get_status(self) -> dict:
        """Get detailed cache status.

        Returns:
            Dict with status information (memory, connections, etc.)
        """
        pass

    @abstractmethod
    async def ping(self) -> bool:
        """Ping the cache server.

        Returns:
            True if server responds
        """
        pass
