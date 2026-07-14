using PhoneStore.Application.DTOs.Dashboard;

namespace PhoneStore.Application.Interfaces;

public interface IDashboardService
{
    Task<DashboardDto> GetDashboardAsync();
    Task<RevenueStatsDto> GetRevenueStatsAsync();
    Task<OrderStatsDto> GetOrderStatsAsync();
    Task<List<TopProductDto>> GetTopProductsAsync(int count = 10);
}
