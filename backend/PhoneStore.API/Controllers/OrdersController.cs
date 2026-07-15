using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PhoneStore.Application.DTOs;
using PhoneStore.Application.DTOs.Order;
using PhoneStore.Application.DTOs.Product;
using PhoneStore.Application.Interfaces;
using PhoneStore.Domain.Enums;
using System.Security.Claims;

namespace PhoneStore.API.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class OrdersController : ControllerBase
{
    private readonly IOrderService _orderService;

    public OrdersController(IOrderService orderService)
    {
        _orderService = orderService;
    }

    private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
    private string GetUserName() => User.FindFirstValue(ClaimTypes.Name) ?? "Unknown";
    private bool IsAdminOrStaff() 
    {
        var role = User.FindFirstValue(ClaimTypes.Role);
        return role != null && (role.Equals(UserRole.Admin, StringComparison.OrdinalIgnoreCase) || role.Equals(UserRole.Staff, StringComparison.OrdinalIgnoreCase));
    }

    [HttpPost]
    public async Task<ActionResult<ApiResponse<OrderDto>>> CreateOrder([FromBody] CreateOrderDto dto)
    {
        var result = await _orderService.CreateOrderAsync(GetUserId(), dto);
        return CreatedAtAction(nameof(GetOrderById), new { id = result.Id }, ApiResponse<OrderDto>.SuccessResponse(result, "Order created successfully"));
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<PagedResultDto<OrderDto>>>> GetOrders(
        [FromQuery] int page = 1, 
        [FromQuery] int pageSize = 10,
        [FromQuery] string? search = null,
        [FromQuery] string? status = null,
        [FromQuery] string? paymentStatus = null)
    {
        var userId = IsAdminOrStaff() ? null : GetUserId();
        var result = await _orderService.GetOrdersAsync(userId, page, pageSize, search, status, paymentStatus);
        return Ok(ApiResponse<PagedResultDto<OrderDto>>.SuccessResponse(result));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<OrderDto>>> GetOrderById(string id)
    {
        var userId = IsAdminOrStaff() ? null : GetUserId();
        var result = await _orderService.GetOrderByIdAsync(id, userId);
        return Ok(ApiResponse<OrderDto>.SuccessResponse(result));
    }

    [Authorize(Roles = UserRole.Admin + "," + UserRole.Staff)]
    [HttpPut("{id}/status")]
    public async Task<ActionResult<ApiResponse<OrderDto>>> UpdateOrderStatus(string id, [FromBody] UpdateOrderStatusDto dto)
    {
        var result = await _orderService.UpdateOrderStatusAsync(id, dto, GetUserId(), GetUserName());
        return Ok(ApiResponse<OrderDto>.SuccessResponse(result, "Order status updated successfully"));
    }

    [Authorize(Roles = UserRole.Admin + "," + UserRole.Staff)]
    [HttpPut("{id}/payment-status")]
    public async Task<ActionResult<ApiResponse<OrderDto>>> UpdatePaymentStatus(string id, [FromBody] UpdateOrderStatusDto dto)
    {
        var result = await _orderService.UpdatePaymentStatusAsync(id, dto.Status, GetUserId(), GetUserName());
        return Ok(ApiResponse<OrderDto>.SuccessResponse(result, "Payment status updated successfully"));
    }

    [HttpPut("{id}/cancel")]
    public async Task<ActionResult<ApiResponse<OrderDto>>> CancelOrder(string id)
    {
        var result = await _orderService.CancelOrderAsync(id, GetUserId());
        return Ok(ApiResponse<OrderDto>.SuccessResponse(result, "Order cancelled successfully"));
    }
}
