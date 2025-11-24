using System;
using Aspire.Hosting;
using Diagrid.Labs.Catalyst.OrderWorkflow.Development.AppHost;
using Projects;

var builder = DistributedApplication.CreateBuilder(args);

var useCatalyst = Environment.GetEnvironmentVariable("USE_CATALYST") switch
{
    "1" or "true" => true,
    _ => false,
};

builder.AddDapr();

var worker = builder.AddProject<Worker>("worker");
var inventoryService = builder.AddProject<InventoryService>("inventory-service");

if (useCatalyst) builder.ConfigureForCatalyst(worker, inventoryService);
else builder.ConfigureForLocal(worker, inventoryService);

builder.Build().Run();
