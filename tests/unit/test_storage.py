"""Unit tests for storage abstraction."""

import pytest
from datetime import timedelta

from app.storage import InMemoryStorage
from app.storage.base import BlobNotFoundError


class TestInMemoryStorage:
    """Tests for InMemoryStorage implementation."""

    @pytest.fixture
    def storage(self):
        """Create a fresh storage instance for each test."""
        return InMemoryStorage()

    @pytest.mark.asyncio
    async def test_upload_and_download(self, storage):
        """Test basic upload and download."""
        await storage.create_container("test-container")

        content = b"Hello, World!"
        url = await storage.upload_bytes(
            "test-container",
            "test-file.txt",
            content,
            content_type="text/plain"
        )

        assert "test-container" in url
        assert "test-file.txt" in url

        downloaded = await storage.download("test-container", "test-file.txt")
        assert downloaded == content

    @pytest.mark.asyncio
    async def test_upload_with_metadata(self, storage):
        """Test upload with custom metadata."""
        await storage.create_container("test-container")

        metadata = {"author": "test", "version": "1.0"}
        await storage.upload_bytes(
            "test-container",
            "test-file.txt",
            b"content",
            metadata=metadata
        )

        blob_metadata = await storage.get_metadata("test-container", "test-file.txt")
        assert blob_metadata is not None
        assert blob_metadata.metadata == metadata

    @pytest.mark.asyncio
    async def test_delete_blob(self, storage):
        """Test blob deletion."""
        await storage.create_container("test-container")
        await storage.upload_bytes("test-container", "to-delete.txt", b"delete me")

        assert await storage.exists("test-container", "to-delete.txt")

        result = await storage.delete("test-container", "to-delete.txt")
        assert result is True

        assert not await storage.exists("test-container", "to-delete.txt")

    @pytest.mark.asyncio
    async def test_delete_nonexistent_blob(self, storage):
        """Test deleting a blob that doesn't exist."""
        await storage.create_container("test-container")

        result = await storage.delete("test-container", "nonexistent.txt")
        assert result is False

    @pytest.mark.asyncio
    async def test_download_nonexistent_blob(self, storage):
        """Test downloading a blob that doesn't exist."""
        await storage.create_container("test-container")

        with pytest.raises(BlobNotFoundError) as exc_info:
            await storage.download("test-container", "nonexistent.txt")

        assert "nonexistent.txt" in str(exc_info.value)

    @pytest.mark.asyncio
    async def test_list_blobs(self, storage):
        """Test listing blobs."""
        await storage.create_container("test-container")
        await storage.upload_bytes("test-container", "file1.txt", b"content1")
        await storage.upload_bytes("test-container", "file2.txt", b"content2")
        await storage.upload_bytes("test-container", "other/file3.txt", b"content3")

        all_blobs = await storage.list_blobs("test-container")
        assert len(all_blobs) == 3

    @pytest.mark.asyncio
    async def test_list_blobs_with_prefix(self, storage):
        """Test listing blobs with prefix filter."""
        await storage.create_container("test-container")
        await storage.upload_bytes("test-container", "docs/readme.txt", b"content")
        await storage.upload_bytes("test-container", "docs/guide.txt", b"content")
        await storage.upload_bytes("test-container", "images/logo.png", b"content")

        docs_blobs = await storage.list_blobs("test-container", prefix="docs/")
        assert len(docs_blobs) == 2
        assert all(b.name.startswith("docs/") for b in docs_blobs)

    @pytest.mark.asyncio
    async def test_exists(self, storage):
        """Test blob existence check."""
        await storage.create_container("test-container")

        assert not await storage.exists("test-container", "missing.txt")

        await storage.upload_bytes("test-container", "exists.txt", b"content")
        assert await storage.exists("test-container", "exists.txt")

    @pytest.mark.asyncio
    async def test_get_sas_url(self, storage):
        """Test SAS URL generation."""
        await storage.create_container("test-container")
        await storage.upload_bytes("test-container", "test.txt", b"content")

        sas_url = await storage.get_sas_url(
            "test-container",
            "test.txt",
            expiry=timedelta(hours=2),
            permissions="r"
        )

        assert "test-container" in sas_url
        assert "test.txt" in sas_url
        assert "sig=" in sas_url
        assert "sp=r" in sas_url

    @pytest.mark.asyncio
    async def test_copy_blob(self, storage):
        """Test blob copy operation."""
        await storage.create_container("source")
        await storage.create_container("dest")

        await storage.upload_bytes("source", "original.txt", b"copy me")

        url = await storage.copy("source", "original.txt", "dest", "copied.txt")

        assert "dest" in url
        assert "copied.txt" in url

        copied_content = await storage.download("dest", "copied.txt")
        assert copied_content == b"copy me"

    @pytest.mark.asyncio
    async def test_create_container(self, storage):
        """Test container creation."""
        result = await storage.create_container("new-container")
        assert result is True

        # Creating again should return False
        result = await storage.create_container("new-container")
        assert result is False

    @pytest.mark.asyncio
    async def test_delete_container(self, storage):
        """Test container deletion."""
        await storage.create_container("to-delete")
        await storage.upload_bytes("to-delete", "file.txt", b"content")

        result = await storage.delete_container("to-delete")
        assert result is True

        # Container should be gone
        blobs = await storage.list_blobs("to-delete")
        assert len(blobs) == 0

    @pytest.mark.asyncio
    async def test_health_check(self, storage):
        """Test health check."""
        await storage.create_container("test1")
        await storage.create_container("test2")
        await storage.upload_bytes("test1", "file.txt", b"content")

        health = await storage.check_health()

        assert health["healthy"] is True
        assert health["type"] == "in-memory"
        assert health["containers"] == 2
        assert health["total_blobs"] == 1

    @pytest.mark.asyncio
    async def test_clear(self, storage):
        """Test clearing all data."""
        await storage.create_container("test")
        await storage.upload_bytes("test", "file.txt", b"content")

        storage.clear()

        health = await storage.check_health()
        assert health["containers"] == 0
        assert health["total_blobs"] == 0
