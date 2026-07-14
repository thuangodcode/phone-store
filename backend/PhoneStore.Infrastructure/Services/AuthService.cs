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

    public AuthService(IRepository<User> userRepository, IMapper mapper, IConfiguration configuration)
    {
        _userRepository = userRepository;
        _mapper = mapper;
        _configuration = configuration;
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

        // Simulated: In production, send email with reset link
        var tempPassword = GenerateRandomPassword();
        user.Password = BCrypt.Net.BCrypt.HashPassword(tempPassword);
        user.UpdatedAt = DateTime.UtcNow;
        await _userRepository.UpdateAsync(user.Id, user);

        // Simulated response - in production this would be sent via email
        return $"A new password has been sent to {dto.Email}. (Simulated: {tempPassword})";
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
