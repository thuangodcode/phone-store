using PhoneStore.Application.DTOs.Product;

namespace PhoneStore.Application.Interfaces;

public interface IProductService
{
    Task<PagedResultDto<ProductDto>> GetProductsAsync(ProductFilterDto filter);
    Task<ProductDto> GetProductByIdAsync(string id);
    Task<ProductDto> CreateProductAsync(CreateProductDto dto);
    Task<ProductDto> UpdateProductAsync(string id, UpdateProductDto dto);
    Task DeleteProductAsync(string id);
    Task<List<ProductDto>> GetRelatedProductsAsync(string productId, int count = 4);
}
