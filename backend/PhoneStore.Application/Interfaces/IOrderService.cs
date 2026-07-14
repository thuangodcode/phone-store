using PhoneStore.Application.DTOs.Order;
using PhoneStore.Application.DTOs.Product;

namespace PhoneStore.Application.Interfaces;

public interface IOrderService
{
    Task<OrderDto> CreateOrderAsync(string userId, CreateOrderDto dto);
    Task<PagedResultDto<OrderDto>> GetOrdersAsync(string? userId, int page, int pageSize);
    Task<OrderDto> GetOrderByIdAsync(string id, string? userId = null);
    Task<OrderDto> UpdateOrderStatusAsync(string id, UpdateOrderStatusDto dto);
    Task<OrderDto> CancelOrderAsync(string id, string userId);
    Task UpdatePaymentStatusByOrderCodeAsync(long orderCode, string paymentStatus);
}
