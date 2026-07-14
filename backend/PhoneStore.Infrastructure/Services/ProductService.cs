using AutoMapper;
using MongoDB.Driver;
using PhoneStore.Application.DTOs.Product;
using PhoneStore.Application.Interfaces;
using PhoneStore.Domain.Entities;
using PhoneStore.Domain.Interfaces;
using PhoneStore.Infrastructure.Data;

namespace PhoneStore.Infrastructure.Services;

public class ProductService : IProductService
{
    private readonly IRepository<Product> _productRepository;
    private readonly IRepository<Brand> _brandRepository;
    private readonly IRepository<Category> _categoryRepository;
    private readonly MongoDbContext _context;
    private readonly IMapper _mapper;

    public ProductService(
        IRepository<Product> productRepository,
        IRepository<Brand> brandRepository,
        IRepository<Category> categoryRepository,
        MongoDbContext context,
        IMapper mapper)
    {
        _productRepository = productRepository;
        _brandRepository = brandRepository;
        _categoryRepository = categoryRepository;
        _context = context;
        _mapper = mapper;
    }

    public async Task<PagedResultDto<ProductDto>> GetProductsAsync(ProductFilterDto filter)
    {
        var builder = Builders<Product>.Filter;
        var filters = new List<FilterDefinition<Product>> { builder.Eq(p => p.IsActive, true) };

        // Search by name
        if (!string.IsNullOrEmpty(filter.Search))
            filters.Add(builder.Regex(p => p.Name, new MongoDB.Bson.BsonRegularExpression(filter.Search, "i")));

        // Filter by brand
        if (!string.IsNullOrEmpty(filter.BrandId))
            filters.Add(builder.Eq(p => p.BrandId, filter.BrandId));

        // Filter by category
        if (!string.IsNullOrEmpty(filter.CategoryId))
            filters.Add(builder.Eq(p => p.CategoryId, filter.CategoryId));

        // Filter by price range
        if (filter.MinPrice.HasValue)
            filters.Add(builder.Gte(p => p.SalePrice, filter.MinPrice.Value));
        if (filter.MaxPrice.HasValue)
            filters.Add(builder.Lte(p => p.SalePrice, filter.MaxPrice.Value));

        // Filter by RAM
        if (!string.IsNullOrEmpty(filter.Ram))
            filters.Add(builder.Eq(p => p.Specifications.Ram, filter.Ram));

        // Filter by ROM
        if (!string.IsNullOrEmpty(filter.Rom))
            filters.Add(builder.Eq(p => p.Specifications.Rom, filter.Rom));

        var combinedFilter = builder.And(filters);

        // Sorting
        var sortBuilder = Builders<Product>.Sort;
        SortDefinition<Product> sort = filter.SortBy switch
        {
            "price_asc" => sortBuilder.Ascending(p => p.SalePrice),
            "price_desc" => sortBuilder.Descending(p => p.SalePrice),
            "bestseller" => sortBuilder.Descending(p => p.Sold),
            "rating" => sortBuilder.Descending(p => p.AverageRating),
            _ => sortBuilder.Descending(p => p.CreatedAt) // newest
        };

        var totalCount = await _context.Products.CountDocumentsAsync(combinedFilter);
        var products = await _context.Products
            .Find(combinedFilter)
            .Sort(sort)
            .Skip((filter.Page - 1) * filter.PageSize)
            .Limit(filter.PageSize)
            .ToListAsync();

        var productDtos = _mapper.Map<List<ProductDto>>(products);

        // Populate brand and category names
        await PopulateProductDetails(productDtos, products);

        return new PagedResultDto<ProductDto>
        {
            Items = productDtos,
            TotalCount = (int)totalCount,
            Page = filter.Page,
            PageSize = filter.PageSize
        };
    }

    public async Task<ProductDto> GetProductByIdAsync(string id)
    {
        var product = await _productRepository.GetByIdAsync(id);
        if (product == null)
            throw new Exception("Product not found.");

        var dto = _mapper.Map<ProductDto>(product);
        await PopulateProductDetails(new List<ProductDto> { dto }, new List<Product> { product });
        return dto;
    }

    public async Task<ProductDto> CreateProductAsync(CreateProductDto createDto)
    {
        var product = _mapper.Map<Product>(createDto);
        product.CreatedAt = DateTime.UtcNow;
        product.UpdatedAt = DateTime.UtcNow;

        await _productRepository.CreateAsync(product);
        return _mapper.Map<ProductDto>(product);
    }

    public async Task<ProductDto> UpdateProductAsync(string id, UpdateProductDto updateDto)
    {
        var product = await _productRepository.GetByIdAsync(id);
        if (product == null)
            throw new Exception("Product not found.");

        product.Name = updateDto.Name;
        product.Description = updateDto.Description;
        product.Price = updateDto.Price;
        product.SalePrice = updateDto.SalePrice;
        product.BrandId = updateDto.BrandId;
        product.CategoryId = updateDto.CategoryId;
        product.Images = updateDto.Images;
        product.Specifications = _mapper.Map<ProductSpecification>(updateDto.Specifications);
        product.Stock = updateDto.Stock;
        product.IsActive = updateDto.IsActive;
        product.UpdatedAt = DateTime.UtcNow;

        await _productRepository.UpdateAsync(id, product);
        return _mapper.Map<ProductDto>(product);
    }

    public async Task DeleteProductAsync(string id)
    {
        var product = await _productRepository.GetByIdAsync(id);
        if (product == null)
            throw new Exception("Product not found.");

        await _productRepository.DeleteAsync(id);
    }

    public async Task<List<ProductDto>> GetRelatedProductsAsync(string productId, int count = 4)
    {
        var product = await _productRepository.GetByIdAsync(productId);
        if (product == null) return new List<ProductDto>();

        var related = await _context.Products
            .Find(p => p.BrandId == product.BrandId && p.Id != productId && p.IsActive)
            .Limit(count)
            .ToListAsync();

        var dtos = _mapper.Map<List<ProductDto>>(related);
        await PopulateProductDetails(dtos, related);
        return dtos;
    }

    private async Task PopulateProductDetails(List<ProductDto> dtos, List<Product> products)
    {
        var brandIds = products.Select(p => p.BrandId).Distinct().ToList();
        var categoryIds = products.Select(p => p.CategoryId).Distinct().ToList();

        var brands = (await _brandRepository.FindAsync(b => brandIds.Contains(b.Id))).ToList();
        var categories = (await _categoryRepository.FindAsync(c => categoryIds.Contains(c.Id))).ToList();

        foreach (var dto in dtos)
        {
            var product = products.First(p => p.Id == dto.Id);
            dto.BrandName = brands.FirstOrDefault(b => b.Id == product.BrandId)?.Name ?? "";
            dto.CategoryName = categories.FirstOrDefault(c => c.Id == product.CategoryId)?.Name ?? "";
        }
    }
}
