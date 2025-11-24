namespace Diagrid.Labs.Catalyst.OrderWorkflow.Common.ServiceDefaults;

public static class JsonSerializerOptions
{
    public static readonly System.Text.Json.JsonSerializerOptions Default = new()
    {
        PropertyNameCaseInsensitive = true,
    };
}
