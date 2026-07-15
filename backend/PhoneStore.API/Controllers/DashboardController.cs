using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PhoneStore.Application.DTOs;
using PhoneStore.Application.DTOs.Dashboard;
using PhoneStore.Application.Interfaces;
using PhoneStore.Domain.Enums;

namespace PhoneStore.API.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize(Roles = UserRole.Admin + "," + UserRole.Staff)]
public class DashboardController : ControllerBase
{
    private readonly IDashboardService _dashboardService;

    public DashboardController(IDashboardService dashboardService)
    {
        _dashboardService = dashboardService;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<DashboardDto>>> GetDashboard()
    {
        var result = await _dashboardService.GetDashboardAsync();
        return Ok(ApiResponse<DashboardDto>.SuccessResponse(result));
    }

    [HttpGet("revenue")]
    public async Task<ActionResult<ApiResponse<RevenueStatsDto>>> GetRevenueStats()
    {
        var result = await _dashboardService.GetRevenueStatsAsync();
        return Ok(ApiResponse<RevenueStatsDto>.SuccessResponse(result));
    }

    [HttpGet("orders")]
    public async Task<ActionResult<ApiResponse<OrderStatsDto>>> GetOrderStats()
    {
        var result = await _dashboardService.GetOrderStatsAsync();
        return Ok(ApiResponse<OrderStatsDto>.SuccessResponse(result));
    }

    [HttpGet("top-products")]
    public async Task<ActionResult<ApiResponse<List<TopProductDto>>>> GetTopProducts([FromQuery] int count = 10)
    {
        var result = await _dashboardService.GetTopProductsAsync(count);
        return Ok(ApiResponse<List<TopProductDto>>.SuccessResponse(result));
    }
}
