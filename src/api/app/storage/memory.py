"""In-memory storage implementation for testing and development."""

import io
from datetime import datetime, timedelta
from typing import BinaryIO, Dict, Optional, List
from uuid import uuid4

from .base import (
    BaseStorageProvider,
    StorageHealth,
    BlobMetadata,
    BlobNotFoundError,
)


class InMemoryStorage(BaseStorageProvider, StorageHealth):
    """In-memory storage implementation.

    Useful for:
    - Unit testing without external dependencies
    - Local development without Azure credentials
    - Integration tests with predictable state
    """

    def __init__(self):
        # Structure: {container: {blob_name: (bytes, metadata)}}
        self._containers: Dict[str, Dict[str, tuple]] = {}
        self._base_url = "memory://storage"

    async def upload(
        self,
        container: str,
        blob_name: str,
        data: BinaryIO,
        content_type: Optional[str] = None,
        metadata: Optional[dict] = None,
    ) -> str:
        content = data.read()
        return await self.upload_bytes(
            container, blob_name, content, content_type, metadata
        )

    async def upload_bytes(
        self,
        container: str,
        blob_name: str,
        data: bytes,
        content_type: Optional[str] = None,
        metadata: Optional[dict] = None,
    ) -> str:
        if container not in self._containers:
            self._containers[container] = {}

        now = datetime.utcnow()
        blob_metadata = BlobMetadata(
            name=blob_name,
            size=len(data),
            content_type=content_type or "application/octet-stream",
            created_at=now,
            modified_at=now,
            etag=str(uuid4()),
            metadata=metadata or {},
        )

        self._containers[container][blob_name] = (data, blob_metadata)
        return f"{self._base_url}/{container}/{blob_name}"

    async def download(
        self,
        container: str,
        blob_name: str,
    ) -> bytes:
        if container not in self._containers:
            raise BlobNotFoundError(container, blob_name)

        if blob_name not in self._containers[container]:
            raise BlobNotFoundError(container, blob_name)

        data, _ = self._containers[container][blob_name]
        return data

    async def download_stream(
        self,
        container: str,
        blob_name: str,
    ) -> BinaryIO:
        data = await self.download(container, blob_name)
        return io.BytesIO(data)

    async def delete(
        self,
        container: str,
        blob_name: str,
    ) -> bool:
        if container not in self._containers:
            return False

        if blob_name not in self._containers[container]:
            return False

        del self._containers[container][blob_name]
        return True

    async def exists(
        self,
        container: str,
        blob_name: str,
    ) -> bool:
        if container not in self._containers:
            return False
        return blob_name in self._containers[container]

    async def list_blobs(
        self,
        container: str,
        prefix: Optional[str] = None,
        max_results: Optional[int] = None,
    ) -> List[BlobMetadata]:
        if container not in self._containers:
            return []

        results = []
        for blob_name, (_, metadata) in self._containers[container].items():
            if prefix and not blob_name.startswith(prefix):
                continue
            results.append(metadata)
            if max_results and len(results) >= max_results:
                break

        return sorted(results, key=lambda x: x.name)

    async def get_metadata(
        self,
        container: str,
        blob_name: str,
    ) -> Optional[BlobMetadata]:
        if container not in self._containers:
            return None

        if blob_name not in self._containers[container]:
            return None

        _, metadata = self._containers[container][blob_name]
        return metadata

    async def get_sas_url(
        self,
        container: str,
        blob_name: str,
        expiry: timedelta = timedelta(hours=1),
        permissions: str = "r",
    ) -> str:
        # In-memory implementation returns a mock SAS URL
        expiry_time = datetime.utcnow() + expiry
        return (
            f"{self._base_url}/{container}/{blob_name}"
            f"?sig=mock-signature&se={expiry_time.isoformat()}&sp={permissions}"
        )

    async def copy(
        self,
        source_container: str,
        source_blob: str,
        dest_container: str,
        dest_blob: str,
    ) -> str:
        data = await self.download(source_container, source_blob)
        metadata = await self.get_metadata(source_container, source_blob)

        return await self.upload_bytes(
            dest_container,
            dest_blob,
            data,
            metadata.content_type if metadata else None,
            metadata.metadata if metadata else None,
        )

    async def create_container(
        self,
        container: str,
        public_access: bool = False,
    ) -> bool:
        if container in self._containers:
            return False  # Already exists

        self._containers[container] = {}
        return True

    async def delete_container(
        self,
        container: str,
    ) -> bool:
        if container not in self._containers:
            return False

        del self._containers[container]
        return True

    async def check_health(self) -> dict:
        """Check storage health (always healthy for in-memory)."""
        return {
            "healthy": True,
            "type": "in-memory",
            "containers": len(self._containers),
            "total_blobs": sum(
                len(blobs) for blobs in self._containers.values()
            ),
        }

    def clear(self):
        """Clear all stored data (useful for test cleanup)."""
        self._containers.clear()
