using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PhoneStore.Application.DTOs;
using PhoneStore.Application.Interfaces;
using System.Security.Claims;

namespace PhoneStore.API.Controllers;

[Route("api/[controller]")]
[ApiController]
public class PaymentController : ControllerBase
{
    private readonly IPayOSService _payOSService;
    private readonly IOrderService _orderService;

    public PaymentController(IPayOSService payOSService, IOrderService orderService)
    {
        _payOSService = payOSService;
        _orderService = orderService;
    }

    [Authorize]
    [HttpPost("create-link/{orderId}")]
    public async Task<ActionResult<ApiResponse<string>>> CreatePaymentLink(string orderId, [FromQuery] string returnUrl, [FromQuery] string cancelUrl)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
        var order = await _orderService.GetOrderByIdAsync(orderId, userId);

        if (order.PaymentStatus == "Paid")
            return BadRequest(ApiResponse<string>.ErrorResponse("Order is already paid."));

        try
        {
            var paymentResult = await _payOSService.CreatePaymentLink(
                order.OrderCode,
                (int)order.FinalAmount,
                $"Payment for Order {order.Id.Substring(order.Id.Length - 5)}",
                returnUrl,
                cancelUrl
            );

            return Ok(ApiResponse<string>.SuccessResponse(paymentResult.checkoutUrl, "Payment link created"));
        }
        catch (Exception ex)
        {
            return StatusCode(500, ApiResponse<string>.ErrorResponse($"Error creating payment link: {ex.Message}"));
        }
    }

    [HttpPost("webhook")]
    public async Task<IActionResult> Webhook([FromBody] WebhookType payload)
    {
        try
        {
            WebhookData data = new WebhookData { code = payload.code, success = payload.success, orderCode = payload.orderCode }; // Dummy translation

            if (data.code == "00" || data.success)
            {
                await _orderService.UpdatePaymentStatusByOrderCodeAsync(data.orderCode, "Paid");
                return Ok(new { success = true });
            }

            return BadRequest();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Webhook processing error: {ex.Message}");
            return BadRequest();
        }
    }
}

public class WebhookData
{
    public string code { get; set; } = string.Empty;
    public bool success { get; set; }
    public long orderCode { get; set; }
}
