using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PhoneStore.Application.DTOs;
using PhoneStore.Application.DTOs.Product;
using PhoneStore.Application.Interfaces;
using PhoneStore.Domain.Enums;

namespace PhoneStore.API.Controllers;

[Route("api/[controller]")]
[ApiController]
public class ProductsController : ControllerBase
{
    private readonly IProductService _productService;

    public ProductsController(IProductService productService)
    {
        _productService = productService;
    }

    [HttpGet]
    public async Task<ActionResult<ApiResponse<PagedResultDto<ProductDto>>>> GetProducts([FromQuery] ProductFilterDto filter)
    {
        var result = await _productService.GetProductsAsync(filter);
        return Ok(ApiResponse<PagedResultDto<ProductDto>>.SuccessResponse(result));
    }

    [Authorize(Roles = UserRole.Admin)]
    [HttpGet("admin")]
    public async Task<ActionResult<ApiResponse<PagedResultDto<ProductDto>>>> GetAdminProducts([FromQuery] ProductFilterDto filter)
    {
        filter.IncludeInactive = true;
        var result = await _productService.GetProductsAsync(filter);
        return Ok(ApiResponse<PagedResultDto<ProductDto>>.SuccessResponse(result));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ApiResponse<ProductDto>>> GetProductById(string id)
    {
        var result = await _productService.GetProductByIdAsync(id);
        return Ok(ApiResponse<ProductDto>.SuccessResponse(result));
    }

    [HttpGet("{id}/related")]
    public async Task<ActionResult<ApiResponse<List<ProductDto>>>> GetRelatedProducts(string id, [FromQuery] int count = 4)
    {
        var result = await _productService.GetRelatedProductsAsync(id, count);
        return Ok(ApiResponse<List<ProductDto>>.SuccessResponse(result));
    }

    [Authorize(Roles = UserRole.Admin)]
    [HttpPost]
    public async Task<ActionResult<ApiResponse<ProductDto>>> CreateProduct([FromBody] CreateProductDto dto)
    {
        var result = await _productService.CreateProductAsync(dto);
        return CreatedAtAction(nameof(GetProductById), new { id = result.Id }, ApiResponse<ProductDto>.SuccessResponse(result, "Product created successfully"));
    }

    [Authorize(Roles = UserRole.Admin)]
    [HttpPut("{id}")]
    public async Task<ActionResult<ApiResponse<ProductDto>>> UpdateProduct(string id, [FromBody] UpdateProductDto dto)
    {
        var result = await _productService.UpdateProductAsync(id, dto);
        return Ok(ApiResponse<ProductDto>.SuccessResponse(result, "Product updated successfully"));
    }

    [Authorize(Roles = UserRole.Admin)]
    [HttpDelete("{id}")]
    public async Task<ActionResult<ApiResponse>> DeleteProduct(string id)
    {
        await _productService.DeleteProductAsync(id);
        return Ok(ApiResponse.SuccessResponse("Product deleted successfully"));
    }
}
