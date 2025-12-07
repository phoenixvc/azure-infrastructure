using System.ComponentModel.DataAnnotations;

namespace AzureInfrastructureApi.Models;

/// <summary>
/// Domain entity representing an item
/// </summary>
public class Item
{
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required]
    [MaxLength(200)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(1000)]
    public string? Description { get; set; }

    public decimal Price { get; set; }

    public bool IsActive { get; set; } = true;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime? UpdatedAt { get; set; }
}

/// <summary>
/// DTO for creating a new item
/// </summary>
public record CreateItemRequest(
    [Required] string Name,
    string? Description,
    decimal Price
);

/// <summary>
/// DTO for updating an existing item
/// </summary>
public record UpdateItemRequest(
    string? Name,
    string? Description,
    decimal? Price,
    bool? IsActive
);

/// <summary>
/// DTO for item response
/// </summary>
public record ItemResponse(
    Guid Id,
    string Name,
    string? Description,
    decimal Price,
    bool IsActive,
    DateTime CreatedAt,
    DateTime? UpdatedAt
)
{
    public static ItemResponse FromEntity(Item item) => new(
        item.Id,
        item.Name,
        item.Description,
        item.Price,
        item.IsActive,
        item.CreatedAt,
        item.UpdatedAt
    );
}

/// <summary>
/// Paginated response wrapper
/// </summary>
public record PaginatedResponse<T>(
    IEnumerable<T> Items,
    int TotalCount,
    int Page,
    int PageSize
)
{
    public int TotalPages => (int)Math.Ceiling(TotalCount / (double)PageSize);
    public bool HasNextPage => Page < TotalPages;
    public bool HasPreviousPage => Page > 1;
}
