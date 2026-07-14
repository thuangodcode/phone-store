namespace PhoneStore.Application.DTOs.Product;

public class ProductDto
{
    public string Id { get; set; } = null!;
    public string Name { get; set; } = null!;
    public string Description { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public decimal SalePrice { get; set; }
    public string BrandId { get; set; } = null!;
    public string BrandName { get; set; } = string.Empty;
    public string CategoryId { get; set; } = null!;
    public string CategoryName { get; set; } = string.Empty;
    public List<string> Images { get; set; } = new();
    public ProductSpecDto Specifications { get; set; } = new();
    public int Stock { get; set; }
    public int Sold { get; set; }
    public double AverageRating { get; set; }
    public int TotalReviews { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class ProductSpecDto
{
    public string Ram { get; set; } = string.Empty;
    public string Rom { get; set; } = string.Empty;
    public string ScreenSize { get; set; } = string.Empty;
    public string Battery { get; set; } = string.Empty;
    public string Cpu { get; set; } = string.Empty;
    public string Os { get; set; } = string.Empty;
    public string Color { get; set; } = string.Empty;
}

public class CreateProductDto
{
    public string Name { get; set; } = null!;
    public string Description { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public decimal SalePrice { get; set; }
    public string BrandId { get; set; } = null!;
    public string CategoryId { get; set; } = null!;
    public List<string> Images { get; set; } = new();
    public ProductSpecDto Specifications { get; set; } = new();
    public int Stock { get; set; }
}

public class UpdateProductDto
{
    public string Name { get; set; } = null!;
    public string Description { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public decimal SalePrice { get; set; }
    public string BrandId { get; set; } = null!;
    public string CategoryId { get; set; } = null!;
    public List<string> Images { get; set; } = new();
    public ProductSpecDto Specifications { get; set; } = new();
    public int Stock { get; set; }
    public bool IsActive { get; set; }
}

public class ProductFilterDto
{
    public string? Search { get; set; }
    public string? BrandId { get; set; }
    public string? CategoryId { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
    public string? Ram { get; set; }
    public string? Rom { get; set; }
    public string? SortBy { get; set; } // price_asc, price_desc, newest, bestseller, rating
    public bool IncludeInactive { get; set; } = false;
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 12;
}

public class PagedResultDto<T>
{
    public List<T> Items { get; set; } = new();
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages => (int)Math.Ceiling((double)TotalCount / PageSize);
}
