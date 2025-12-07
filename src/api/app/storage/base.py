"""Abstract storage provider interface.

This module defines the interface for storage operations, enabling
swapping between Azure Blob Storage and in-memory implementations
for testing and development.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import BinaryIO, Optional, List


@dataclass
class BlobMetadata:
    """Metadata for a stored blob."""

    name: str
    size: int
    content_type: Optional[str]
    created_at: datetime
    modified_at: datetime
    etag: Optional[str] = None
    metadata: Optional[dict] = None


class BaseStorageProvider(ABC):
    """Abstract storage provider interface.

    Implementations:
    - InMemoryStorage: For testing and development
    - AzureBlobStorage: For production (Azure Blob Storage)
    - S3Storage: For AWS deployments
    - LocalFileStorage: For local development
    """

    @abstractmethod
    async def upload(
        self,
        container: str,
        blob_name: str,
        data: BinaryIO,
        content_type: Optional[str] = None,
        metadata: Optional[dict] = None,
    ) -> str:
        """Upload a blob and return its URL.

        Args:
            container: Container/bucket name
            blob_name: Name of the blob (can include path)
            data: Binary data to upload
            content_type: MIME type of the content
            metadata: Custom metadata key-value pairs

        Returns:
            URL of the uploaded blob
        """
        pass

    @abstractmethod
    async def upload_bytes(
        self,
        container: str,
        blob_name: str,
        data: bytes,
        content_type: Optional[str] = None,
        metadata: Optional[dict] = None,
    ) -> str:
        """Upload bytes directly and return URL."""
        pass

    @abstractmethod
    async def download(
        self,
        container: str,
        blob_name: str,
    ) -> bytes:
        """Download blob content.

        Args:
            container: Container/bucket name
            blob_name: Name of the blob

        Returns:
            Blob content as bytes

        Raises:
            BlobNotFoundError: If blob doesn't exist
        """
        pass

    @abstractmethod
    async def download_stream(
        self,
        container: str,
        blob_name: str,
    ) -> BinaryIO:
        """Download blob as a stream."""
        pass

    @abstractmethod
    async def delete(
        self,
        container: str,
        blob_name: str,
    ) -> bool:
        """Delete a blob.

        Args:
            container: Container/bucket name
            blob_name: Name of the blob

        Returns:
            True if deleted, False if not found
        """
        pass

    @abstractmethod
    async def exists(
        self,
        container: str,
        blob_name: str,
    ) -> bool:
        """Check if a blob exists."""
        pass

    @abstractmethod
    async def list_blobs(
        self,
        container: str,
        prefix: Optional[str] = None,
        max_results: Optional[int] = None,
    ) -> List[BlobMetadata]:
        """List blobs in container.

        Args:
            container: Container/bucket name
            prefix: Filter blobs starting with this prefix
            max_results: Maximum number of results to return

        Returns:
            List of blob metadata
        """
        pass

    @abstractmethod
    async def get_metadata(
        self,
        container: str,
        blob_name: str,
    ) -> Optional[BlobMetadata]:
        """Get blob metadata without downloading content."""
        pass

    @abstractmethod
    async def get_sas_url(
        self,
        container: str,
        blob_name: str,
        expiry: timedelta = timedelta(hours=1),
        permissions: str = "r",
    ) -> str:
        """Generate a time-limited signed URL for blob access.

        Args:
            container: Container/bucket name
            blob_name: Name of the blob
            expiry: How long the URL should be valid
            permissions: Permission string (r=read, w=write, d=delete)

        Returns:
            Signed URL with embedded credentials
        """
        pass

    @abstractmethod
    async def copy(
        self,
        source_container: str,
        source_blob: str,
        dest_container: str,
        dest_blob: str,
    ) -> str:
        """Copy a blob to another location."""
        pass

    @abstractmethod
    async def create_container(
        self,
        container: str,
        public_access: bool = False,
    ) -> bool:
        """Create a container if it doesn't exist."""
        pass

    @abstractmethod
    async def delete_container(
        self,
        container: str,
    ) -> bool:
        """Delete a container and all its contents."""
        pass


class StorageHealth(ABC):
    """Abstract storage health check interface."""

    @abstractmethod
    async def check_health(self) -> dict:
        """Check storage connectivity and return health status.

        Returns:
            Dict with 'healthy' bool and optional 'details'
        """
        pass


class BlobNotFoundError(Exception):
    """Raised when a blob is not found."""

    def __init__(self, container: str, blob_name: str):
        self.container = container
        self.blob_name = blob_name
        super().__init__(f"Blob not found: {container}/{blob_name}")
