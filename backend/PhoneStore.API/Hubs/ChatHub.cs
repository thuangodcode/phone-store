using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;

namespace PhoneStore.API.Hubs;

public class ChatHub : Hub
{
    public async Task JoinSession(string sessionId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, sessionId);
    }

    public async Task LeaveSession(string sessionId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, sessionId);
    }

    public async Task JoinStaff()
    {
        var role = Context.User?.FindFirstValue(ClaimTypes.Role);
        if (role == "Admin" || role == "Staff")
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, "Staff");
        }
    }

    public async Task LeaveStaff()
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, "Staff");
    }
}

