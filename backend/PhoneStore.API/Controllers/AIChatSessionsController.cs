using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PhoneStore.Application.DTOs;
using PhoneStore.Application.DTOs.AI;
using PhoneStore.Application.Interfaces.AI;
using System.Security.Claims;

namespace PhoneStore.API.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class AIChatSessionsController : ControllerBase
{
    private readonly IAIChatSessionService _sessionService;

    public AIChatSessionsController(IAIChatSessionService sessionService)
    {
        _sessionService = sessionService;
    }

    private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier) ?? string.Empty;
    private string GetUserRole() => User.IsInRole("Admin") ? "admin" : User.IsInRole("Staff") ? "staff" : User.IsInRole("Customer") ? "customer" : "guest";

    [HttpGet]
    public async Task<IActionResult> GetSessions([FromQuery] bool includeDeleted = false)
    {
        var userId = GetUserId();
        var sessions = await _sessionService.GetSessionsAsync(userId, includeDeleted);
        return Ok(ApiResponse<List<AIChatSessionDto>>.SuccessResponse(sessions));
    }

    [HttpGet("{sessionId}")]
    public async Task<IActionResult> GetSession(string sessionId)
    {
        var session = await _sessionService.GetSessionAsync(sessionId);
        if (session == null)
        {
            return NotFound(ApiResponse.ErrorResponse("Session not found"));
        }
        return Ok(ApiResponse<AIChatSessionDto>.SuccessResponse(session));
    }

    [HttpGet("{sessionId}/messages")]
    public async Task<IActionResult> GetMessages(string sessionId)
    {
        var messages = await _sessionService.GetSessionMessagesAsync(sessionId);
        return Ok(ApiResponse<List<AIChatMessageDto>>.SuccessResponse(messages));
    }

    [HttpPost]
    public async Task<IActionResult> CreateSession([FromBody] AIChatSessionDto request)
    {
        var userId = GetUserId();
        var userRole = GetUserRole();
        var session = await _sessionService.CreateSessionAsync(userId, userRole, request.Title, request.Id);
        return Ok(ApiResponse<AIChatSessionDto>.SuccessResponse(session));
    }

    [HttpPatch("{sessionId}")]
    public async Task<IActionResult> UpdateSession(string sessionId, [FromBody] AIChatSessionDto request)
    {
        var session = await _sessionService.UpdateSessionAsync(sessionId, request.Title, request.DeletedAt);
        if (session == null)
        {
            return NotFound(ApiResponse.ErrorResponse("Session not found"));
        }
        return Ok(ApiResponse<AIChatSessionDto>.SuccessResponse(session));
    }
}
