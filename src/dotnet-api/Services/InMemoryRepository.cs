using System.Collections.Concurrent;
using System.Linq.Expressions;
using AzureInfrastructureApi.Abstractions;

namespace AzureInfrastructureApi.Services;

/// <summary>
/// In-memory repository implementation for development and testing
/// </summary>
public class InMemoryRepository<T> : IRepository<T> where T : class
{
    private readonly ConcurrentDictionary<Guid, T> _store = new();
    private readonly Func<T, Guid> _idSelector;

    public InMemoryRepository(Func<T, Guid> idSelector)
    {
        _idSelector = idSelector;
    }

    public Task<T?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        _store.TryGetValue(id, out var entity);
        return Task.FromResult(entity);
    }

    public Task<IEnumerable<T>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        return Task.FromResult<IEnumerable<T>>(_store.Values.ToList());
    }

    public Task<IEnumerable<T>> FindAsync(
        Expression<Func<T, bool>> predicate,
        CancellationToken cancellationToken = default)
    {
        var compiled = predicate.Compile();
        var results = _store.Values.Where(compiled).ToList();
        return Task.FromResult<IEnumerable<T>>(results);
    }

    public Task<(IEnumerable<T> Items, int TotalCount)> GetPagedAsync(
        int page,
        int pageSize,
        Expression<Func<T, bool>>? predicate = null,
        CancellationToken cancellationToken = default)
    {
        var query = _store.Values.AsEnumerable();

        if (predicate != null)
        {
            query = query.Where(predicate.Compile());
        }

        var totalCount = query.Count();
        var items = query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToList();

        return Task.FromResult((Items: (IEnumerable<T>)items, TotalCount: totalCount));
    }

    public Task<T> AddAsync(T entity, CancellationToken cancellationToken = default)
    {
        var id = _idSelector(entity);
        _store.TryAdd(id, entity);
        return Task.FromResult(entity);
    }

    public Task<T> UpdateAsync(T entity, CancellationToken cancellationToken = default)
    {
        var id = _idSelector(entity);
        _store[id] = entity;
        return Task.FromResult(entity);
    }

    public Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        _store.TryRemove(id, out _);
        return Task.CompletedTask;
    }

    public Task<bool> ExistsAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(_store.ContainsKey(id));
    }

    public Task<int> CountAsync(
        Expression<Func<T, bool>>? predicate = null,
        CancellationToken cancellationToken = default)
    {
        var query = _store.Values.AsEnumerable();

        if (predicate != null)
        {
            query = query.Where(predicate.Compile());
        }

        return Task.FromResult(query.Count());
    }
}
