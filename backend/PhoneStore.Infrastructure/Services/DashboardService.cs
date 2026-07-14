using MongoDB.Driver;
using PhoneStore.Application.DTOs.Dashboard;
using PhoneStore.Application.Interfaces;
using PhoneStore.Domain.Entities;
using PhoneStore.Domain.Enums;
using PhoneStore.Domain.Interfaces;
using PhoneStore.Infrastructure.Data;

namespace PhoneStore.Infrastructure.Services;

public class DashboardService : IDashboardService
{
    private readonly MongoDbContext _context;
    private readonly IRepository<User> _userRepository;
    private readonly IRepository<Product> _productRepository;

    public DashboardService(
        MongoDbContext context,
        IRepository<User> userRepository,
        IRepository<Product> productRepository)
    {
        _context = context;
        _userRepository = userRepository;
        _productRepository = productRepository;
    }

    public async Task<DashboardDto> GetDashboardAsync()
    {
        var revenue = await GetRevenueStatsAsync();
        var orders = await GetOrderStatsAsync();
        var topProducts = await GetTopProductsAsync(5);
        var totalCustomers = (int)await _userRepository.CountAsync(u => u.Role == UserRole.Customer);
        var totalProducts = (int)await _productRepository.CountAsync();

        // Recent orders
        var recentOrders = await _context.Orders
            .Find(_ => true)
            .SortByDescending(o => o.CreatedAt)
            .Limit(10)
            .ToListAsync();

        var recentOrderDtos = new List<RecentOrderDto>();
        foreach (var order in recentOrders)
        {
            var user = await _userRepository.GetByIdAsync(order.UserId);
            recentOrderDtos.Add(new RecentOrderDto
            {
                OrderId = order.Id,
                CustomerName = user?.FullName ?? "Unknown",
                FinalAmount = order.FinalAmount,
                Status = order.Status,
                CreatedAt = order.CreatedAt
            });
        }

        return new DashboardDto
        {
            Revenue = revenue,
            Orders = orders,
            TotalCustomers = totalCustomers,
            TotalProducts = totalProducts,
            TopProducts = topProducts,
            RecentOrders = recentOrderDtos
        };
    }

    public async Task<RevenueStatsDto> GetRevenueStatsAsync()
    {
        var deliveredFilter = Builders<Order>.Filter.Eq(o => o.Status, OrderStatus.Delivered);

        var allDelivered = await _context.Orders.Find(deliveredFilter).ToListAsync();
        var totalRevenue = allDelivered.Sum(o => o.FinalAmount);

        var today = DateTime.UtcNow.Date;
        var firstDayOfMonth = new DateTime(today.Year, today.Month, 1);

        var monthlyRevenue = allDelivered
            .Where(o => o.CreatedAt >= firstDayOfMonth)
            .Sum(o => o.FinalAmount);

        var dailyRevenue = allDelivered
            .Where(o => o.CreatedAt >= today)
            .Sum(o => o.FinalAmount);

        return new RevenueStatsDto
        {
            TotalRevenue = totalRevenue,
            MonthlyRevenue = monthlyRevenue,
            DailyRevenue = dailyRevenue
        };
    }

    public async Task<OrderStatsDto> GetOrderStatsAsync()
    {
        var allOrders = await _context.Orders.Find(_ => true).ToListAsync();

        return new OrderStatsDto
        {
            TotalOrders = allOrders.Count,
            PendingOrders = allOrders.Count(o => o.Status == OrderStatus.Pending),
            ConfirmedOrders = allOrders.Count(o => o.Status == OrderStatus.Confirmed),
            ShippingOrders = allOrders.Count(o => o.Status == OrderStatus.Shipping),
            DeliveredOrders = allOrders.Count(o => o.Status == OrderStatus.Delivered),
            CancelledOrders = allOrders.Count(o => o.Status == OrderStatus.Cancelled)
        };
    }

    public async Task<List<TopProductDto>> GetTopProductsAsync(int count = 10)
    {
        var products = await _context.Products
            .Find(p => p.IsActive)
            .SortByDescending(p => p.Sold)
            .Limit(count)
            .ToListAsync();

        return products.Select(p => new TopProductDto
        {
            ProductId = p.Id,
            ProductName = p.Name,
            ProductImage = p.Images.FirstOrDefault() ?? string.Empty,
            TotalSold = p.Sold,
            TotalRevenue = p.Sold * (p.SalePrice > 0 ? p.SalePrice : p.Price)
        }).ToList();
    }
}
