using AutoMapper;
using PhoneStore.Application.DTOs.User;
using PhoneStore.Application.Interfaces;
using PhoneStore.Domain.Entities;
using PhoneStore.Domain.Interfaces;

namespace PhoneStore.Infrastructure.Services;

public class UserService : IUserService
{
    private readonly IRepository<User> _userRepository;
    private readonly IMapper _mapper;

    public UserService(IRepository<User> userRepository, IMapper mapper)
    {
        _userRepository = userRepository;
        _mapper = mapper;
    }

    public async Task<List<UserDto>> GetAllUsersAsync()
    {
        var users = await _userRepository.GetAllAsync();
        return _mapper.Map<List<UserDto>>(users);
    }

    public async Task<UserDto> GetUserByIdAsync(string id)
    {
        var user = await _userRepository.GetByIdAsync(id);
        if (user == null)
            throw new Exception("User not found.");
        return _mapper.Map<UserDto>(user);
    }

    public async Task<UserDto> AdminCreateUserAsync(AdminCreateUserDto dto)
    {
        var existingUser = await _userRepository.FindOneAsync(u => u.Email == dto.Email);
        if (existingUser != null)
            throw new Exception("Email already exists.");

        var user = new User
        {
            FullName = dto.FullName,
            Email = dto.Email,
            Password = BCrypt.Net.BCrypt.HashPassword(dto.Password),
            Phone = dto.Phone,
            Address = dto.Address,
            Role = dto.Role,
            IsActive = true
        };

        await _userRepository.CreateAsync(user);
        return _mapper.Map<UserDto>(user);
    }

    public async Task<UserDto> UpdateProfileAsync(string id, UpdateProfileDto dto)
    {
        var user = await _userRepository.GetByIdAsync(id);
        if (user == null)
            throw new Exception("User not found.");

        user.FullName = dto.FullName;
        user.Phone = dto.Phone;
        user.Address = dto.Address;
        user.Avatar = dto.Avatar;
        user.UpdatedAt = DateTime.UtcNow;

        await _userRepository.UpdateAsync(id, user);
        return _mapper.Map<UserDto>(user);
    }

    public async Task DeleteUserAsync(string id)
    {
        var user = await _userRepository.GetByIdAsync(id);
        if (user == null)
            throw new Exception("User not found.");
        await _userRepository.DeleteAsync(id);
    }

    public async Task<UserDto> ToggleUserStatusAsync(string id)
    {
        var user = await _userRepository.GetByIdAsync(id);
        if (user == null)
            throw new Exception("User not found.");

        user.IsActive = !user.IsActive;
        user.UpdatedAt = DateTime.UtcNow;

        await _userRepository.UpdateAsync(id, user);
        return _mapper.Map<UserDto>(user);
    }
}
