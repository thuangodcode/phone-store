using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using AutoMapper;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using PhoneStore.Application.DTOs.Auth;
using PhoneStore.Application.Interfaces;
using PhoneStore.Domain.Entities;
using PhoneStore.Domain.Interfaces;

namespace PhoneStore.Infrastructure.Services;

public class AuthService : IAuthService
{
    private readonly IRepository<User> _userRepository;
    private readonly IMapper _mapper;
    private readonly IConfiguration _configuration;
    private readonly IEmailService _emailService;

    public AuthService(IRepository<User> userRepository, IMapper mapper, IConfiguration configuration, IEmailService emailService)
    {
        _userRepository = userRepository;
        _mapper = mapper;
        _configuration = configuration;
        _emailService = emailService;
    }

    public async Task<AuthResponseDto> RegisterAsync(RegisterDto dto)
    {
        // Check if email already exists
        var existingUser = await _userRepository.FindOneAsync(u => u.Email == dto.Email);
        if (existingUser != null)
            throw new Exception("Email already exists.");

        if (dto.Password != dto.ConfirmPassword)
            throw new Exception("Passwords do not match.");

        var user = new User
        {
            FullName = dto.FullName,
            Email = dto.Email,
            Password = BCrypt.Net.BCrypt.HashPassword(dto.Password),
            Phone = dto.Phone,
            Role = "Customer"
        };

        await _userRepository.CreateAsync(user);

        // Send welcome email asynchronously (fire and forget with timeout)
        var emailTask = _emailService.SendWelcomeEmailAsync(user.Email, user.FullName);
        try
        {
            await Task.WhenAny(emailTask, Task.Delay(5000));
        }
        catch (Exception ex)
        {
            // Log but don't fail the registration
            Console.WriteLine($"Email send task failed or timed out: {ex.Message}");
        }

        var token = GenerateJwtToken(user);
        return new AuthResponseDto
        {
            Token = token,
            User = _mapper.Map<UserInfoDto>(user)
        };
    }

    public async Task<AuthResponseDto> LoginAsync(LoginDto dto)
    {
        var user = await _userRepository.FindOneAsync(u => u.Email == dto.Email);
        if (user == null)
            throw new Exception("Invalid email or password.");

        if (!user.IsActive)
            throw new Exception("Account has been deactivated.");

        if (!BCrypt.Net.BCrypt.Verify(dto.Password, user.Password))
            throw new Exception("Invalid email or password.");

        var token = GenerateJwtToken(user);
        return new AuthResponseDto
        {
            Token = token,
            User = _mapper.Map<UserInfoDto>(user)
        };
    }

    public async Task<string> ForgotPasswordAsync(ForgotPasswordDto dto)
    {
        var user = await _userRepository.FindOneAsync(u => u.Email == dto.Email);
        if (user == null)
            throw new Exception("Email not found.");

        // Generate temporary password
        var tempPassword = GenerateRandomPassword();
        user.Password = BCrypt.Net.BCrypt.HashPassword(tempPassword);
        user.UpdatedAt = DateTime.UtcNow;
        await _userRepository.UpdateAsync(user.Id, user);

        // Send password reset email - wait with timeout, but propagate errors properly
        var emailTask = _emailService.SendPasswordResetEmailAsync(
            user.Email,
            user.FullName,
            tempPassword,
            $"https://phone-store.vercel.app/reset-password?email={user.Email}"
        );

        var completedTask = await Task.WhenAny(emailTask, Task.Delay(15000));
        if (completedTask == emailTask)
        {
            // Email task completed within timeout - re-await to propagate any exception
            await emailTask;
        }
        else
        {
            // Timeout - email is still sending in background, but password was already reset
            Console.WriteLine($"Email sending to {dto.Email} is taking longer than expected, continuing in background.");
        }

        return $"Password reset instructions have been sent to {dto.Email}. Please check your inbox.";
    }

    public async Task ChangePasswordAsync(string userId, ChangePasswordDto dto)
    {
        var user = await _userRepository.GetByIdAsync(userId);
        if (user == null)
            throw new Exception("User not found.");

        if (!BCrypt.Net.BCrypt.Verify(dto.CurrentPassword, user.Password))
            throw new Exception("Current password is incorrect.");

        if (dto.NewPassword != dto.ConfirmNewPassword)
            throw new Exception("New passwords do not match.");

        user.Password = BCrypt.Net.BCrypt.HashPassword(dto.NewPassword);
        user.UpdatedAt = DateTime.UtcNow;
        await _userRepository.UpdateAsync(user.Id, user);
    }

    private string GenerateJwtToken(User user)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(
            _configuration["Jwt:Secret"] ?? "PhoneStoreSecretKey2024VeryLongSecretKey123!"));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Name, user.FullName),
            new Claim(ClaimTypes.Role, user.Role)
        };

        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"] ?? "PhoneStoreAPI",
            audience: _configuration["Jwt:Audience"] ?? "PhoneStoreClient",
            claims: claims,
            expires: DateTime.UtcNow.AddDays(7),
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private string GenerateRandomPassword()
    {
        const string chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#$";
        var random = new Random();
        return new string(Enumerable.Repeat(chars, 10).Select(s => s[random.Next(s.Length)]).ToArray());
    }
}
