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
        var revenueFilter = Builders<Order>.Filter.Eq(o => o.PaymentStatus, "Paid");

        var validOrders = await _context.Orders.Find(revenueFilter).ToListAsync();
        var totalRevenue = validOrders.Sum(o => o.FinalAmount);

        var today = DateTime.UtcNow.Date;
        var firstDayOfMonth = new DateTime(today.Year, today.Month, 1);

        var monthlyRevenue = validOrders
            .Where(o => o.CreatedAt >= firstDayOfMonth)
            .Sum(o => o.FinalAmount);

        var dailyRevenue = validOrders
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
        // Get all paid orders
        var paidOrdersFilter = Builders<Order>.Filter.Eq(o => o.PaymentStatus, "Paid");
        var paidOrders = await _context.Orders.Find(paidOrdersFilter).ToListAsync();

        // Aggregate items
        var productStats = new Dictionary<string, TopProductDto>();

        foreach (var order in paidOrders)
        {
            foreach (var item in order.Items)
            {
                if (productStats.TryGetValue(item.ProductId, out var stat))
                {
                    stat.TotalSold += item.Quantity;
                    stat.TotalRevenue += item.Quantity * item.Price;
                }
                else
                {
                    productStats[item.ProductId] = new TopProductDto
                    {
                        ProductId = item.ProductId,
                        ProductName = item.ProductName,
                        ProductImage = item.ProductImage,
                        TotalSold = item.Quantity,
                        TotalRevenue = item.Quantity * item.Price
                    };
                }
            }
        }

        // Sort by revenue descending and take top N
        var topProducts = productStats.Values
            .OrderByDescending(p => p.TotalRevenue)
            .Take(count)
            .ToList();

        // If no paid orders, fallback to old logic for display purposes, but with 0 revenue
        if (topProducts.Count == 0)
        {
            var fallbackProducts = await _context.Products
                .Find(p => p.IsActive)
                .SortByDescending(p => p.Sold)
                .Limit(count)
                .ToListAsync();

            return fallbackProducts.Select(p => new TopProductDto
            {
                ProductId = p.Id,
                ProductName = p.Name,
                ProductImage = p.Images.FirstOrDefault() ?? string.Empty,
                TotalSold = p.Sold,
                TotalRevenue = 0 // Real revenue is 0 since no paid orders
            }).ToList();
        }

        return topProducts;
    }
}
