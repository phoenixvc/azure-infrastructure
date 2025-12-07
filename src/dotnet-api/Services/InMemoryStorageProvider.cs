using System.Collections.Concurrent;
using AzureInfrastructureApi.Abstractions;

namespace AzureInfrastructureApi.Services;

/// <summary>
/// In-memory storage provider for development and testing
/// </summary>
public class InMemoryStorageProvider : IStorageProvider
{
    private readonly ConcurrentDictionary<string, BlobData> _blobs = new();

    private record BlobData(
        byte[] Content,
        string? ContentType,
        IDictionary<string, string> Metadata,
        DateTimeOffset CreatedAt);

    private static string GetKey(string container, string blob) => $"{container}/{blob}";

    public Task<Stream> DownloadAsync(
        string containerName,
        string blobName,
        CancellationToken cancellationToken = default)
    {
        var key = GetKey(containerName, blobName);
        if (_blobs.TryGetValue(key, out var data))
        {
            return Task.FromResult<Stream>(new MemoryStream(data.Content));
        }

        throw new FileNotFoundException($"Blob not found: {key}");
    }

    public Task<byte[]> DownloadBytesAsync(
        string containerName,
        string blobName,
        CancellationToken cancellationToken = default)
    {
        var key = GetKey(containerName, blobName);
        if (_blobs.TryGetValue(key, out var data))
        {
            return Task.FromResult(data.Content);
        }

        throw new FileNotFoundException($"Blob not found: {key}");
    }

    public Task UploadAsync(
        string containerName,
        string blobName,
        Stream content,
        string? contentType = null,
        IDictionary<string, string>? metadata = null,
        CancellationToken cancellationToken = default)
    {
        using var ms = new MemoryStream();
        content.CopyTo(ms);
        return UploadAsync(containerName, blobName, ms.ToArray(), contentType, metadata, cancellationToken);
    }

    public Task UploadAsync(
        string containerName,
        string blobName,
        byte[] content,
        string? contentType = null,
        IDictionary<string, string>? metadata = null,
        CancellationToken cancellationToken = default)
    {
        var key = GetKey(containerName, blobName);
        _blobs[key] = new BlobData(
            content,
            contentType,
            metadata ?? new Dictionary<string, string>(),
            DateTimeOffset.UtcNow);

        return Task.CompletedTask;
    }

    public Task DeleteAsync(
        string containerName,
        string blobName,
        CancellationToken cancellationToken = default)
    {
        var key = GetKey(containerName, blobName);
        _blobs.TryRemove(key, out _);
        return Task.CompletedTask;
    }

    public Task<bool> ExistsAsync(
        string containerName,
        string blobName,
        CancellationToken cancellationToken = default)
    {
        var key = GetKey(containerName, blobName);
        return Task.FromResult(_blobs.ContainsKey(key));
    }

    public Task<IEnumerable<string>> ListAsync(
        string containerName,
        string? prefix = null,
        CancellationToken cancellationToken = default)
    {
        var containerPrefix = $"{containerName}/";
        var fullPrefix = prefix != null ? $"{containerPrefix}{prefix}" : containerPrefix;

        var blobs = _blobs.Keys
            .Where(k => k.StartsWith(fullPrefix))
            .Select(k => k.Substring(containerPrefix.Length))
            .ToList();

        return Task.FromResult<IEnumerable<string>>(blobs);
    }

    public Task<Uri> GetSasUriAsync(
        string containerName,
        string blobName,
        TimeSpan expiry,
        bool readOnly = true,
        CancellationToken cancellationToken = default)
    {
        // In-memory implementation returns a fake URI
        var uri = new Uri($"memory://{containerName}/{blobName}?expiry={expiry.TotalSeconds}");
        return Task.FromResult(uri);
    }

    public Task<BlobMetadata?> GetMetadataAsync(
        string containerName,
        string blobName,
        CancellationToken cancellationToken = default)
    {
        var key = GetKey(containerName, blobName);
        if (_blobs.TryGetValue(key, out var data))
        {
            return Task.FromResult<BlobMetadata?>(new BlobMetadata(
                blobName,
                data.Content.Length,
                data.ContentType,
                data.CreatedAt,
                data.Metadata));
        }

        return Task.FromResult<BlobMetadata?>(null);
    }
}
