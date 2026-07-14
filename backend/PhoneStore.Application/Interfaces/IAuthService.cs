using PhoneStore.Application.DTOs.Auth;

namespace PhoneStore.Application.Interfaces;

public interface IAuthService
{
    Task<AuthResponseDto> RegisterAsync(RegisterDto dto);
    Task<AuthResponseDto> LoginAsync(LoginDto dto);
    Task<string> ForgotPasswordAsync(ForgotPasswordDto dto);
    Task ChangePasswordAsync(string userId, ChangePasswordDto dto);
}
