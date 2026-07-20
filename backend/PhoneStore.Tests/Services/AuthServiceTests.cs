using System;
using System.Threading.Tasks;
using AutoMapper;
using Microsoft.Extensions.Configuration;
using Moq;
using PhoneStore.Application.DTOs.Auth;
using PhoneStore.Application.Interfaces;
using PhoneStore.Domain.Entities;
using PhoneStore.Domain.Interfaces;
using PhoneStore.Infrastructure.Services;
using Xunit;
using System.Linq.Expressions;

namespace PhoneStore.Tests.Services
{
    public class AuthServiceTests
    {
        private readonly Mock<IRepository<User>> _mockUserRepository;
        private readonly Mock<IMapper> _mockMapper;
        private readonly Mock<IConfiguration> _mockConfiguration;
        private readonly Mock<IEmailService> _mockEmailService;
        private readonly AuthService _authService;

        public AuthServiceTests()
        {
            _mockUserRepository = new Mock<IRepository<User>>();
            _mockMapper = new Mock<IMapper>();
            _mockConfiguration = new Mock<IConfiguration>();
            _mockEmailService = new Mock<IEmailService>();

            // Mock IConfiguration for JWT settings
            _mockConfiguration.Setup(c => c["Jwt:Secret"]).Returns("SuperSecretKey123!@#$VeryLongKeyForTesting");
            _mockConfiguration.Setup(c => c["Jwt:Issuer"]).Returns("TestIssuer");
            _mockConfiguration.Setup(c => c["Jwt:Audience"]).Returns("TestAudience");
            _mockConfiguration.Setup(c => c["Jwt:ExpiresInDays"]).Returns("1");

            _authService = new AuthService(
                _mockUserRepository.Object,
                _mockMapper.Object,
                _mockConfiguration.Object,
                _mockEmailService.Object);
        }

        [Fact]
        public async Task RegisterAsync_EmailAlreadyExists_ThrowsException()
        {
            // Arrange
            var dto = new RegisterDto { Email = "test@test.com", Password = "123", ConfirmPassword = "123" };
            _mockUserRepository.Setup(r => r.FindOneAsync(It.IsAny<Expression<Func<User, bool>>>()))
                .ReturnsAsync(new User { Email = "test@test.com" });

            // Act & Assert
            var ex = await Assert.ThrowsAsync<Exception>(() => _authService.RegisterAsync(dto));
            Assert.Equal("Email already exists.", ex.Message);
        }

        [Fact]
        public async Task RegisterAsync_PasswordMismatch_ThrowsException()
        {
            // Arrange
            var dto = new RegisterDto { Email = "test@test.com", Password = "123", ConfirmPassword = "456" };
            _mockUserRepository.Setup(r => r.FindOneAsync(It.IsAny<Expression<Func<User, bool>>>()))
                .ReturnsAsync((User)null!);

            // Act & Assert
            var ex = await Assert.ThrowsAsync<Exception>(() => _authService.RegisterAsync(dto));
            Assert.Equal("Passwords do not match.", ex.Message);
        }

        [Fact]
        public async Task RegisterAsync_ValidDto_CreatesUserAndReturnsToken()
        {
            // Arrange
            var dto = new RegisterDto 
            { 
                Email = "new@test.com", 
                Password = "123", 
                ConfirmPassword = "123", 
                FullName = "New User" 
            };

            _mockUserRepository.Setup(r => r.FindOneAsync(It.IsAny<Expression<Func<User, bool>>>()))
                .ReturnsAsync((User)null!); // Email does not exist

            _mockUserRepository.Setup(r => r.CreateAsync(It.IsAny<User>()))
                .Callback<User>(u => {
                    u.Id = "123456789012345678901234";
                    u.Role = "Customer";
                })
                .Returns(Task.CompletedTask);

            _mockEmailService.Setup(e => e.SendWelcomeEmailAsync(It.IsAny<string>(), It.IsAny<string>()))
                .Returns(Task.CompletedTask);

            _mockMapper.Setup(m => m.Map<UserInfoDto>(It.IsAny<User>()))
                .Returns(new UserInfoDto { Email = "new@test.com", FullName = "New User" });

            // Act
            var result = await _authService.RegisterAsync(dto);

            // Assert
            Assert.NotNull(result);
            Assert.NotEmpty(result.Token);
            Assert.Equal("new@test.com", result.User.Email);
            _mockUserRepository.Verify(r => r.CreateAsync(It.IsAny<User>()), Times.Once);
        }

        [Fact]
        public async Task LoginAsync_UserNotFound_ThrowsException()
        {
            // Arrange
            var dto = new LoginDto { Email = "nonexistent@test.com", Password = "123" };
            _mockUserRepository.Setup(r => r.FindOneAsync(It.IsAny<Expression<Func<User, bool>>>()))
                .ReturnsAsync((User)null!);

            // Act & Assert
            var ex = await Assert.ThrowsAsync<Exception>(() => _authService.LoginAsync(dto));
            Assert.Equal("Invalid email or password.", ex.Message);
        }

        [Fact]
        public async Task LoginAsync_ValidCredentials_ReturnsToken()
        {
            // Arrange
            var password = "password123";
            var hashedPassword = BCrypt.Net.BCrypt.HashPassword(password);
            
            var user = new User 
            { 
                Id = "123456789012345678901234",
                FullName = "Test User",
                Role = "Customer",
                Email = "test@test.com", 
                Password = hashedPassword, 
                IsActive = true 
            };
            
            var dto = new LoginDto { Email = "test@test.com", Password = password };

            _mockUserRepository.Setup(r => r.FindOneAsync(It.IsAny<Expression<Func<User, bool>>>()))
                .ReturnsAsync(user);

            _mockMapper.Setup(m => m.Map<UserInfoDto>(It.IsAny<User>()))
                .Returns(new UserInfoDto { Email = "test@test.com" });

            // Act
            var result = await _authService.LoginAsync(dto);

            // Assert
            Assert.NotNull(result);
            Assert.NotEmpty(result.Token);
            Assert.Equal("test@test.com", result.User.Email);
        }
    }
}
