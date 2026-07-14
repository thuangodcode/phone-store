namespace PhoneStore.Application.DTOs.Auth;

public class RegisterDto
{
    public string FullName { get; set; } = null!;
    public string Email { get; set; } = null!;
    public string Password { get; set; } = null!;
    public string ConfirmPassword { get; set; } = null!;
    public string Phone { get; set; } = string.Empty;
}

public class LoginDto
{
    public string Email { get; set; } = null!;
    public string Password { get; set; } = null!;
}

public class AuthResponseDto
{
    public string Token { get; set; } = null!;
    public string RefreshToken { get; set; } = string.Empty;
    public UserInfoDto User { get; set; } = null!;
}

public class UserInfoDto
{
    public string Id { get; set; } = null!;
    public string FullName { get; set; } = null!;
    public string Email { get; set; } = null!;
    public string Phone { get; set; } = string.Empty;
    public string Role { get; set; } = null!;
    public string Avatar { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
}

public class ChangePasswordDto
{
    public string CurrentPassword { get; set; } = null!;
    public string NewPassword { get; set; } = null!;
    public string ConfirmNewPassword { get; set; } = null!;
}

public class ForgotPasswordDto
{
    public string Email { get; set; } = null!;
}
