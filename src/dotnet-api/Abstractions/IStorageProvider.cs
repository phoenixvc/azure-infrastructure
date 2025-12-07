namespace AzureInfrastructureApi.Abstractions;

/// <summary>
/// Storage provider interface for blob storage abstraction
/// Enables swapping between Azure Blob, S3, or local file system
/// </summary>
public interface IStorageProvider
{
    Task<Stream> DownloadAsync(
        string containerName,
        string blobName,
        CancellationToken cancellationToken = default);

    Task<byte[]> DownloadBytesAsync(
        string containerName,
        string blobName,
        CancellationToken cancellationToken = default);

    Task UploadAsync(
        string containerName,
        string blobName,
        Stream content,
        string? contentType = null,
        IDictionary<string, string>? metadata = null,
        CancellationToken cancellationToken = default);

    Task UploadAsync(
        string containerName,
        string blobName,
        byte[] content,
        string? contentType = null,
        IDictionary<string, string>? metadata = null,
        CancellationToken cancellationToken = default);

    Task DeleteAsync(
        string containerName,
        string blobName,
        CancellationToken cancellationToken = default);

    Task<bool> ExistsAsync(
        string containerName,
        string blobName,
        CancellationToken cancellationToken = default);

    Task<IEnumerable<string>> ListAsync(
        string containerName,
        string? prefix = null,
        CancellationToken cancellationToken = default);

    Task<Uri> GetSasUriAsync(
        string containerName,
        string blobName,
        TimeSpan expiry,
        bool readOnly = true,
        CancellationToken cancellationToken = default);

    Task<BlobMetadata?> GetMetadataAsync(
        string containerName,
        string blobName,
        CancellationToken cancellationToken = default);
}

public record BlobMetadata(
    string Name,
    long Size,
    string? ContentType,
    DateTimeOffset? LastModified,
    IDictionary<string, string> Metadata
);
