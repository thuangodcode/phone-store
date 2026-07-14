namespace PhoneStore.Application.DTOs.Category;

public class CategoryDto
{
    public string Id { get; set; } = null!;
    public string Name { get; set; } = null!;
    public string Description { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreateCategoryDto
{
    public string Name { get; set; } = null!;
    public string Description { get; set; } = string.Empty;
}

public class UpdateCategoryDto
{
    public string Name { get; set; } = null!;
    public string Description { get; set; } = string.Empty;
    public bool IsActive { get; set; }
}
