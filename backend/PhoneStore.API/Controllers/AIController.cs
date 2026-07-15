using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PhoneStore.Application.DTOs.AI;
using PhoneStore.Application.Interfaces.AI;

namespace PhoneStore.API.Controllers;

[Route("api/[controller]")]
[ApiController]
public class AIController : ControllerBase
{
    private readonly IAIAgentService _aiAgentService;

    public AIController(IAIAgentService aiAgentService)
    {
        _aiAgentService = aiAgentService;
    }

    [HttpPost("chat")]
    [AllowAnonymous] // Allowing anonymous for Guest role, but ideally should read JWT
    public async Task<IActionResult> Chat([FromBody] AIChatRequestDto request)
    {
        // In a real app, read from HttpContext.User.Claims
        var userId = User.Identity?.IsAuthenticated == true ? "user-id-from-jwt" : "guest-id";
        var role = User.IsInRole("Admin") ? "admin" : 
                   User.IsInRole("Staff") ? "staff" : 
                   User.IsInRole("Customer") ? "customer" : "guest";

        var result = await _aiAgentService.ProcessChatAsync(request, userId, role);
        return Ok(result);
    }
}
