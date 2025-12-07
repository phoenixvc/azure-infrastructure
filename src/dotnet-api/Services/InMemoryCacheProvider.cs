using System.Collections.Concurrent;
using AzureInfrastructureApi.Abstractions;

namespace AzureInfrastructureApi.Services;

/// <summary>
/// In-memory cache implementation for development and testing
/// </summary>
public class InMemoryCacheProvider : ICacheProvider
{
    private readonly ConcurrentDictionary<string, CacheEntry> _cache = new();

    private record CacheEntry(object Value, DateTime? ExpiresAt);

    public Task<T?> GetAsync<T>(string key, CancellationToken cancellationToken = default)
    {
        if (_cache.TryGetValue(key, out var entry))
        {
            if (entry.ExpiresAt == null || entry.ExpiresAt > DateTime.UtcNow)
            {
                return Task.FromResult((T?)entry.Value);
            }

            _cache.TryRemove(key, out _);
        }

        return Task.FromResult(default(T));
    }

    public Task SetAsync<T>(
        string key,
        T value,
        TimeSpan? expiration = null,
        CancellationToken cancellationToken = default)
    {
        var expiresAt = expiration.HasValue
            ? DateTime.UtcNow.Add(expiration.Value)
            : (DateTime?)null;

        _cache[key] = new CacheEntry(value!, expiresAt);
        return Task.CompletedTask;
    }

    public Task RemoveAsync(string key, CancellationToken cancellationToken = default)
    {
        _cache.TryRemove(key, out _);
        return Task.CompletedTask;
    }

    public Task<bool> ExistsAsync(string key, CancellationToken cancellationToken = default)
    {
        if (_cache.TryGetValue(key, out var entry))
        {
            if (entry.ExpiresAt == null || entry.ExpiresAt > DateTime.UtcNow)
            {
                return Task.FromResult(true);
            }

            _cache.TryRemove(key, out _);
        }

        return Task.FromResult(false);
    }

    public async Task<T> GetOrSetAsync<T>(
        string key,
        Func<Task<T>> factory,
        TimeSpan? expiration = null,
        CancellationToken cancellationToken = default)
    {
        var cached = await GetAsync<T>(key, cancellationToken);
        if (cached != null)
        {
            return cached;
        }

        var value = await factory();
        await SetAsync(key, value, expiration, cancellationToken);
        return value;
    }

    public Task RemoveByPrefixAsync(string prefix, CancellationToken cancellationToken = default)
    {
        var keysToRemove = _cache.Keys.Where(k => k.StartsWith(prefix)).ToList();
        foreach (var key in keysToRemove)
        {
            _cache.TryRemove(key, out _);
        }

        return Task.CompletedTask;
    }
}
