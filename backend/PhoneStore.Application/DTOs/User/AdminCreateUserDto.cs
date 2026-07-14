using System.ComponentModel.DataAnnotations;

namespace PhoneStore.Application.DTOs.User;

public class AdminCreateUserDto
{
    [Required]
    public string FullName { get; set; } = string.Empty;

    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    public string Password { get; set; } = string.Empty;

    public string Phone { get; set; } = string.Empty;
    public string Address { get; set; } = string.Empty;

    [Required]
    public string Role { get; set; } = "User"; // Admin, Staff, User
}
