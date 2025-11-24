using System.Text.Json.Serialization;

namespace Diagrid.Labs.Catalyst.OrderWorkflow.Common.Domain;

public record InventorySearchResult
{
    public List<ItemStatus> Statuses { get; init; } = [];

    [JsonIgnore]
    public IList<ItemStatus> OutOfStockItems => Statuses.Where((status) => status.Quantity <= 0).ToList();
}
