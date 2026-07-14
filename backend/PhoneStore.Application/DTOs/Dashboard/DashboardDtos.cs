namespace PhoneStore.Application.DTOs.Dashboard;

public class DashboardDto
{
    public RevenueStatsDto Revenue { get; set; } = new();
    public OrderStatsDto Orders { get; set; } = new();
    public int TotalCustomers { get; set; }
    public int TotalProducts { get; set; }
    public List<TopProductDto> TopProducts { get; set; } = new();
    public List<RecentOrderDto> RecentOrders { get; set; } = new();
}

public class RevenueStatsDto
{
    public decimal TotalRevenue { get; set; }
    public decimal MonthlyRevenue { get; set; }
    public decimal DailyRevenue { get; set; }
}

public class OrderStatsDto
{
    public int TotalOrders { get; set; }
    public int PendingOrders { get; set; }
    public int ConfirmedOrders { get; set; }
    public int ShippingOrders { get; set; }
    public int DeliveredOrders { get; set; }
    public int CancelledOrders { get; set; }
}

public class TopProductDto
{
    public string ProductId { get; set; } = null!;
    public string ProductName { get; set; } = null!;
    public string ProductImage { get; set; } = string.Empty;
    public int TotalSold { get; set; }
    public decimal TotalRevenue { get; set; }
}

public class RecentOrderDto
{
    public string OrderId { get; set; } = null!;
    public string CustomerName { get; set; } = null!;
    public decimal FinalAmount { get; set; }
    public string Status { get; set; } = null!;
    public DateTime CreatedAt { get; set; }
}
