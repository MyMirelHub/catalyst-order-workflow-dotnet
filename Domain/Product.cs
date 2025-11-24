namespace Diagrid.Labs.Catalyst.OrderWorkflow.Common.Domain;

public record Product
{
    public required string ProductId { get; init; }
    public required int Quantity { get; init; }
    public required DateTime LastUpdated { get; init; }
}
