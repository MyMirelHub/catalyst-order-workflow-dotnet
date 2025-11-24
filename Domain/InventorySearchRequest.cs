namespace Diagrid.Labs.Catalyst.OrderWorkflow.Common.Domain;

public record InventorySearchRequest
{
    public string OrderId { get; init; } = string.Empty;
    public List<ItemStatus> Items { get; init; } = [];
}
