using System;
using System.Text.Json;
using System.Threading.Tasks;
using PhoneStore.Application.Interfaces;
using PhoneStore.Application.Interfaces.AI;

namespace PhoneStore.Infrastructure.AI.Tools;

public class GetRevenueAnalyticsTool : IAITool
{
    private readonly IDashboardService _dashboardService;

    public GetRevenueAnalyticsTool(IDashboardService dashboardService)
    {
        _dashboardService = dashboardService;
    }

    public string Name => "GetRevenueAnalytics";

    public string Description => "Retrieve real-time revenue statistics including total revenue, monthly revenue, daily revenue, and overall order statistics (pending, delivered, etc.).";

    public string ParametersSchema => @"{
        ""type"": ""object"",
        ""properties"": {},
        ""required"": []
    }";

    public async Task<string> ExecuteAsync(string arguments)
    {
        try
        {
            var revenue = await _dashboardService.GetRevenueStatsAsync();
            var orders = await _dashboardService.GetOrderStatsAsync();

            var result = new
            {
                Revenue = new 
                {
                    Total = revenue.TotalRevenue,
                    Monthly = revenue.MonthlyRevenue,
                    Daily = revenue.DailyRevenue
                },
                Orders = new
                {
                    Total = orders.TotalOrders,
                    Pending = orders.PendingOrders,
                    Delivered = orders.DeliveredOrders,
                    Cancelled = orders.CancelledOrders
                }
            };

            return JsonSerializer.Serialize(result);
        }
        catch (Exception ex)
        {
            return JsonSerializer.Serialize(new { Error = ex.Message });
        }
    }
}
