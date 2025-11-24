namespace Diagrid.Labs.Catalyst.OrderWorkflow.Common.Domain;

public record UpdateInventoryResult
{
    public required bool Success { get; init; }
    public required DateTime UpdatedAt { get; init; }
}
