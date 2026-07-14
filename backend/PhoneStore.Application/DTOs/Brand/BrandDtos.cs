namespace PhoneStore.Application.DTOs.Brand;

public class BrandDto
{
    public string Id { get; set; } = null!;
    public string Name { get; set; } = null!;
    public string Logo { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreateBrandDto
{
    public string Name { get; set; } = null!;
    public string Logo { get; set; } = string.Empty;
}

public class UpdateBrandDto
{
    public string Name { get; set; } = null!;
    public string Logo { get; set; } = string.Empty;
    public bool IsActive { get; set; }
}
