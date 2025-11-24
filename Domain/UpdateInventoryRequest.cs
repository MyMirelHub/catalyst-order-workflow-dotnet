namespace Diagrid.Labs.Catalyst.OrderWorkflow.Common.Domain;

public record UpdateInventoryRequest
{
    public required string OrderId { get; init; }
    public required List<ItemStatus> Items { get; init; } = [];
    public required string Operation { get; init; } // "reserve", "release", "restock"
}
