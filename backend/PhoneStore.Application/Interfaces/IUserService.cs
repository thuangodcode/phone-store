using PhoneStore.Application.DTOs.User;

namespace PhoneStore.Application.Interfaces;

public interface IUserService
{
    Task<List<UserDto>> GetAllUsersAsync();
    Task<UserDto> GetUserByIdAsync(string id);
    Task<UserDto> AdminCreateUserAsync(AdminCreateUserDto dto);
    Task<UserDto> UpdateProfileAsync(string id, UpdateProfileDto dto);
    Task DeleteUserAsync(string id);
    Task<UserDto> ToggleUserStatusAsync(string id);
}
