using AutoMapper;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MongoDB.Driver;
using PhoneStore.Application.DTOs;
using PhoneStore.Application.DTOs.Chat;
using PhoneStore.Domain.Entities;
using PhoneStore.Infrastructure.Data;
using PhoneStore.API.Hubs;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;

namespace PhoneStore.API.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class ChatController : ControllerBase
{
    private readonly MongoDbContext _context;
    private readonly IMapper _mapper;
    private readonly IHubContext<ChatHub> _hubContext;

    public ChatController(MongoDbContext context, IMapper mapper, IHubContext<ChatHub> hubContext)
    {
        _context = context;
        _mapper = mapper;
        _hubContext = hubContext;
    }

    private string GetUserId() => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
    private string GetUserName() => User.FindFirstValue(ClaimTypes.Name) ?? "User";
    private bool IsStaffOrAdmin() => User.IsInRole("Admin") || User.IsInRole("Staff");

    [HttpGet("session/active")]
    public async Task<ActionResult<ApiResponse<ChatSessionDto>>> GetActiveSession()
    {
        var userId = GetUserId();
        var session = await _context.ChatSessions.Find(s => s.CustomerId == userId && s.IsActive).FirstOrDefaultAsync();
        
        if (session == null)
        {
            session = new ChatSession
            {
                CustomerId = userId,
                CustomerName = GetUserName(),
                IsActive = true
            };
            await _context.ChatSessions.InsertOneAsync(session);
        }

        return Ok(ApiResponse<ChatSessionDto>.SuccessResponse(_mapper.Map<ChatSessionDto>(session)));
    }

    [HttpGet("sessions")]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<ActionResult<ApiResponse<IEnumerable<ChatSessionDto>>>> GetAllActiveSessions()
    {
        var sessions = await _context.ChatSessions.Find(s => s.IsActive).SortByDescending(s => s.UpdatedAt).ToListAsync();
        return Ok(ApiResponse<IEnumerable<ChatSessionDto>>.SuccessResponse(_mapper.Map<IEnumerable<ChatSessionDto>>(sessions)));
    }

    [HttpGet("messages/{sessionId}")]
    public async Task<ActionResult<ApiResponse<IEnumerable<ChatMessageDto>>>> GetMessages(string sessionId)
    {
        var messages = await _context.ChatMessages.Find(m => m.SessionId == sessionId).SortBy(m => m.Timestamp).ToListAsync();
        return Ok(ApiResponse<IEnumerable<ChatMessageDto>>.SuccessResponse(_mapper.Map<IEnumerable<ChatMessageDto>>(messages)));
    }

    [HttpPost("sessions/{sessionId}/assign")]
    [Authorize(Roles = "Admin,Staff")]
    public async Task<ActionResult<ApiResponse<ChatSessionDto>>> AssignStaff(string sessionId)
    {
        var session = await _context.ChatSessions.Find(s => s.Id == sessionId).FirstOrDefaultAsync();
        if (session == null)
            return NotFound(ApiResponse.FailResponse("Session not found"));

        var staffId = GetUserId();
        var staffName = GetUserName();

        // Update session with staff info
        var update = Builders<ChatSession>.Update
            .Set(s => s.StaffId, staffId)
            .Set(s => s.StaffName, staffName)
            .Set(s => s.UpdatedAt, DateTime.UtcNow);
        await _context.ChatSessions.UpdateOneAsync(s => s.Id == sessionId, update);

        var updatedSession = await _context.ChatSessions.Find(s => s.Id == sessionId).FirstOrDefaultAsync();

        // Notify the session that staff has been assigned
        await _hubContext.Clients.Group(sessionId).SendAsync("StaffAssigned", _mapper.Map<ChatSessionDto>(updatedSession));

        return Ok(ApiResponse<ChatSessionDto>.SuccessResponse(_mapper.Map<ChatSessionDto>(updatedSession), "Staff assigned successfully"));
    }

    [HttpPost("messages/{sessionId}")]
    public async Task<ActionResult<ApiResponse<ChatMessageDto>>> SendMessage(string sessionId, [FromBody] string content)
    {
        var role = IsStaffOrAdmin() ? "Staff" : "Customer";
        var msg = new ChatMessage
        {
            SessionId = sessionId,
            SenderId = GetUserId(),
            SenderName = GetUserName(),
            SenderRole = role,
            Content = content
        };

        await _context.ChatMessages.InsertOneAsync(msg);

        // Update session timestamp
        var update = Builders<ChatSession>.Update.Set(s => s.UpdatedAt, DateTime.UtcNow);
        await _context.ChatSessions.UpdateOneAsync(s => s.Id == sessionId, update);

        var dto = _mapper.Map<ChatMessageDto>(msg);
        
        // Broadcast to session
        await _hubContext.Clients.Group(sessionId).SendAsync("ReceiveMessage", dto);

        // If it's a customer message, notify all staff about new message
        if (!IsStaffOrAdmin())
        {
            await _hubContext.Clients.Group("Staff").SendAsync("NewMessage", _mapper.Map<ChatSessionDto>(await _context.ChatSessions.Find(s => s.Id == sessionId).FirstOrDefaultAsync()));
        }
        
        return Ok(ApiResponse<ChatMessageDto>.SuccessResponse(dto));
    }
}

