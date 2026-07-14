using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PhoneStore.Application.DTOs;
using PhoneStore.Application.DTOs.User;
using PhoneStore.Application.Interfaces;
using PhoneStore.Domain.Enums;
using System.Security.Claims;

namespace PhoneStore.API.Controllers;

[Route("api/[controller]")]
[ApiController]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;

    public UsersController(IUserService userService)
    {
        _userService = userService;
    }

    [Authorize(Roles = UserRole.Admin)]
    [HttpGet]
    public async Task<ActionResult<ApiResponse<List<UserDto>>>> GetAllUsers()
    {
        var result = await _userService.GetAllUsersAsync();
        return Ok(ApiResponse<List<UserDto>>.SuccessResponse(result));
    }

    [Authorize]
    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<UserDto>>> GetUserById(string id)
    {
        var currentUserId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (currentUserId != id && !User.IsInRole(UserRole.Admin))
            return Forbid();

        var result = await _userService.GetUserByIdAsync(id);
        return Ok(ApiResponse<UserDto>.SuccessResponse(result));
    }

    [Authorize]
    [HttpPut("profile")]
    public async Task<ActionResult<ApiResponse<UserDto>>> UpdateProfile([FromBody] UpdateProfileDto dto)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
        var result = await _userService.UpdateProfileAsync(userId, dto);
        return Ok(ApiResponse<UserDto>.SuccessResponse(result, "Profile updated successfully"));
    }

    [Authorize(Roles = UserRole.Admin)]
    [HttpDelete("{id}")]
    public async Task<ActionResult<ApiResponse>> DeleteUser(string id)
    {
        await _userService.DeleteUserAsync(id);
        return Ok(ApiResponse.SuccessResponse("User deleted successfully"));
    }

    [Authorize(Roles = UserRole.Admin)]
    [HttpPut("{id}/toggle-status")]
    public async Task<ActionResult<ApiResponse<UserDto>>> ToggleUserStatus(string id)
    {
        var result = await _userService.ToggleUserStatusAsync(id);
        var status = result.IsActive ? "activated" : "deactivated";
        return Ok(ApiResponse<UserDto>.SuccessResponse(result, $"User {status} successfully"));
    }
}
