using System;
using System.Threading.Tasks;
using Dapr.Client;
using Dapr.Workflow;
using Diagrid.Labs.Catalyst.OrderWorkflow.Common.ServiceDefaults;
using Diagrid.Labs.Catalyst.OrderWorkflow.Worker.Model;

namespace Diagrid.Labs.Catalyst.OrderWorkflow.Worker.Activity;

public class SendNotificationActivity(DaprClient daprClient) : WorkflowActivity<NotificationRequest, bool>
{
    public override async Task<bool> RunAsync(WorkflowActivityContext context, NotificationRequest request)
    {
        var orderNotification = new OrderStatusNotification
        {
            OrderId = request.OrderId,
            Status = request.Status,
            Message = request.Message,
            Timestamp = DateTime.UtcNow,
        };

        await daprClient.PublishEventAsync(ShopActivityPubSub.ResourceName, ShopActivityPubSub.OrderTopic, orderNotification);

        return true;
    }
}
