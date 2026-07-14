namespace PhoneStore.Application.DTOs.User;

public class UserDto
{
    public string Id { get; set; } = null!;
    public string FullName { get; set; } = null!;
    public string Email { get; set; } = null!;
    public string Phone { get; set; } = string.Empty;
    public string Role { get; set; } = null!;
    public string Address { get; set; } = string.Empty;
    public string Avatar { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class UpdateProfileDto
{
    public string FullName { get; set; } = null!;
    public string Phone { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;
    public string Avatar { get; set; } = string.Empty;
}
