using AzureInfrastructureApi.Abstractions;
using AzureInfrastructureApi.Models;
using Microsoft.AspNetCore.Mvc;

namespace AzureInfrastructureApi.Controllers;

/// <summary>
/// Items API controller
/// </summary>
[ApiController]
[Route("api/v1/[controller]")]
[Produces("application/json")]
public class ItemsController : ControllerBase
{
    private readonly IRepository<Item> _repository;
    private readonly ICacheProvider _cache;
    private readonly IMessagePublisher _messagePublisher;
    private readonly ILogger<ItemsController> _logger;

    private const string CacheKeyPrefix = "items:";
    private static readonly TimeSpan CacheExpiration = TimeSpan.FromMinutes(5);

    public ItemsController(
        IRepository<Item> repository,
        ICacheProvider cache,
        IMessagePublisher messagePublisher,
        ILogger<ItemsController> logger)
    {
        _repository = repository;
        _cache = cache;
        _messagePublisher = messagePublisher;
        _logger = logger;
    }

    /// <summary>
    /// Get all items with pagination
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(PaginatedResponse<ItemResponse>), StatusCodes.Status200OK)]
    public async Task<ActionResult<PaginatedResponse<ItemResponse>>> GetItems(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 10,
        CancellationToken cancellationToken = default)
    {
        if (page < 1) page = 1;
        if (pageSize < 1) pageSize = 10;
        if (pageSize > 100) pageSize = 100;

        var (items, totalCount) = await _repository.GetPagedAsync(
            page, pageSize, null, cancellationToken);

        var response = new PaginatedResponse<ItemResponse>(
            items.Select(ItemResponse.FromEntity),
            totalCount,
            page,
            pageSize);

        return Ok(response);
    }

    /// <summary>
    /// Get item by ID
    /// </summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ItemResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ItemResponse>> GetItem(
        Guid id,
        CancellationToken cancellationToken = default)
    {
        // Try cache first
        var cacheKey = $"{CacheKeyPrefix}{id}";
        var cached = await _cache.GetAsync<ItemResponse>(cacheKey, cancellationToken);
        if (cached != null)
        {
            _logger.LogDebug("Cache hit for item {Id}", id);
            return Ok(cached);
        }

        var item = await _repository.GetByIdAsync(id, cancellationToken);
        if (item == null)
        {
            return NotFound(new { Error = "Item not found", Id = id });
        }

        var response = ItemResponse.FromEntity(item);

        // Cache the response
        await _cache.SetAsync(cacheKey, response, CacheExpiration, cancellationToken);

        return Ok(response);
    }

    /// <summary>
    /// Create a new item
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(ItemResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<ItemResponse>> CreateItem(
        [FromBody] CreateItemRequest request,
        CancellationToken cancellationToken = default)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var item = new Item
        {
            Name = request.Name,
            Description = request.Description,
            Price = request.Price
        };

        await _repository.AddAsync(item, cancellationToken);

        // Publish event
        await _messagePublisher.PublishAsync("items.created", new
        {
            ItemId = item.Id,
            item.Name,
            item.Price,
            Timestamp = DateTime.UtcNow
        }, cancellationToken: cancellationToken);

        _logger.LogInformation("Created item {Id}: {Name}", item.Id, item.Name);

        var response = ItemResponse.FromEntity(item);
        return CreatedAtAction(nameof(GetItem), new { id = item.Id }, response);
    }

    /// <summary>
    /// Update an existing item
    /// </summary>
    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(ItemResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ItemResponse>> UpdateItem(
        Guid id,
        [FromBody] UpdateItemRequest request,
        CancellationToken cancellationToken = default)
    {
        var item = await _repository.GetByIdAsync(id, cancellationToken);
        if (item == null)
        {
            return NotFound(new { Error = "Item not found", Id = id });
        }

        if (request.Name != null) item.Name = request.Name;
        if (request.Description != null) item.Description = request.Description;
        if (request.Price.HasValue) item.Price = request.Price.Value;
        if (request.IsActive.HasValue) item.IsActive = request.IsActive.Value;
        item.UpdatedAt = DateTime.UtcNow;

        await _repository.UpdateAsync(item, cancellationToken);

        // Invalidate cache
        await _cache.RemoveAsync($"{CacheKeyPrefix}{id}", cancellationToken);

        // Publish event
        await _messagePublisher.PublishAsync("items.updated", new
        {
            ItemId = item.Id,
            item.Name,
            Timestamp = DateTime.UtcNow
        }, cancellationToken: cancellationToken);

        _logger.LogInformation("Updated item {Id}", item.Id);

        return Ok(ItemResponse.FromEntity(item));
    }

    /// <summary>
    /// Delete an item
    /// </summary>
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeleteItem(
        Guid id,
        CancellationToken cancellationToken = default)
    {
        if (!await _repository.ExistsAsync(id, cancellationToken))
        {
            return NotFound(new { Error = "Item not found", Id = id });
        }

        await _repository.DeleteAsync(id, cancellationToken);

        // Invalidate cache
        await _cache.RemoveAsync($"{CacheKeyPrefix}{id}", cancellationToken);

        // Publish event
        await _messagePublisher.PublishAsync("items.deleted", new
        {
            ItemId = id,
            Timestamp = DateTime.UtcNow
        }, cancellationToken: cancellationToken);

        _logger.LogInformation("Deleted item {Id}", id);

        return NoContent();
    }
}
