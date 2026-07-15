using AutoMapper;
using PhoneStore.Application.DTOs.Auth;
using PhoneStore.Application.DTOs.Brand;
using PhoneStore.Application.DTOs.Cart;
using PhoneStore.Application.DTOs.Category;
using PhoneStore.Application.DTOs.Order;
using PhoneStore.Application.DTOs.Product;
using PhoneStore.Application.DTOs.Review;
using PhoneStore.Application.DTOs.User;
using PhoneStore.Application.DTOs.Voucher;
using PhoneStore.Domain.Entities;

namespace PhoneStore.Application.Mappings;

public class MappingProfile : Profile
{
    public MappingProfile()
    {
        // User
        CreateMap<User, UserInfoDto>();
        CreateMap<User, UserDto>();

        // Product
        CreateMap<Product, ProductDto>();
        CreateMap<CreateProductDto, Product>();
        CreateMap<ProductSpecification, ProductSpecDto>().ReverseMap();
        CreateMap<ProductStorageVariant, ProductStorageVariantDto>().ReverseMap();
        CreateMap<ProductColorVariant, ProductColorVariantDto>().ReverseMap();

        // Brand
        CreateMap<Brand, BrandDto>();
        CreateMap<CreateBrandDto, Brand>();

        // Category
        CreateMap<Category, CategoryDto>();
        CreateMap<CreateCategoryDto, Category>();

        // Order
        CreateMap<Order, OrderDto>();
        CreateMap<OrderItem, OrderItemDto>();
        CreateMap<OrderAuditLog, OrderAuditLogDto>();

        // Review
        CreateMap<Review, ReviewDto>();
        CreateMap<CreateReviewDto, Review>();

        // Voucher
        CreateMap<Voucher, VoucherDto>();
        CreateMap<CreateVoucherDto, Voucher>();
        // Review Reply
        CreateMap<ReviewReply, PhoneStore.Application.DTOs.Review.ReviewReplyDto>();
    }
}
