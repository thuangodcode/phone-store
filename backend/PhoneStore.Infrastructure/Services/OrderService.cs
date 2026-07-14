using AutoMapper;
using MongoDB.Driver;
using PhoneStore.Application.DTOs.Order;
using PhoneStore.Application.DTOs.Product;
using PhoneStore.Application.Interfaces;
using PhoneStore.Domain.Entities;
using PhoneStore.Domain.Enums;
using PhoneStore.Domain.Interfaces;
using PhoneStore.Infrastructure.Data;

namespace PhoneStore.Infrastructure.Services;

public class OrderService : IOrderService
{
    private readonly IRepository<Order> _orderRepository;
    private readonly IRepository<Cart> _cartRepository;
    private readonly IRepository<Product> _productRepository;
    private readonly IRepository<User> _userRepository;
    private readonly IVoucherService _voucherService;
    private readonly MongoDbContext _context;
    private readonly IMapper _mapper;

    public OrderService(
        IRepository<Order> orderRepository,
        IRepository<Cart> cartRepository,
        IRepository<Product> productRepository,
        IRepository<User> userRepository,
        IVoucherService voucherService,
        MongoDbContext context,
        IMapper mapper)
    {
        _orderRepository = orderRepository;
        _cartRepository = cartRepository;
        _productRepository = productRepository;
        _userRepository = userRepository;
        _voucherService = voucherService;
        _context = context;
        _mapper = mapper;
    }

    public async Task<OrderDto> CreateOrderAsync(string userId, CreateOrderDto dto)
    {
        var cart = await _cartRepository.FindOneAsync(c => c.UserId == userId);
        if (cart == null || !cart.Items.Any())
            throw new Exception("Cart is empty.");

        var orderItems = new List<OrderItem>();
        decimal totalAmount = 0;

        foreach (var cartItem in cart.Items)
        {
            var product = await _productRepository.GetByIdAsync(cartItem.ProductId);
            if (product == null)
                throw new Exception($"Product not found.");

            if (product.Stock < cartItem.Quantity)
                throw new Exception($"Not enough stock for {product.Name}.");

            var price = product.SalePrice > 0 ? product.SalePrice : product.Price;

            orderItems.Add(new OrderItem
            {
                ProductId = product.Id,
                ProductName = product.Name,
                ProductImage = product.Images.FirstOrDefault() ?? string.Empty,
                Quantity = cartItem.Quantity,
                Price = price
            });

            totalAmount += price * cartItem.Quantity;

            // Update stock and sold count
            product.Stock -= cartItem.Quantity;
            product.Sold += cartItem.Quantity;
            product.UpdatedAt = DateTime.UtcNow;
            await _productRepository.UpdateAsync(product.Id, product);
        }

        // Calculate discount
        decimal discountAmount = 0;
        if (!string.IsNullOrEmpty(dto.VoucherCode))
        {
            discountAmount = await _voucherService.CalculateDiscountAsync(dto.VoucherCode, totalAmount);
        }

        var order = new Order
        {
            UserId = userId,
            Items = orderItems,
            TotalAmount = totalAmount,
            DiscountAmount = discountAmount,
            FinalAmount = totalAmount - discountAmount,
            VoucherCode = dto.VoucherCode,
            ShippingAddress = dto.ShippingAddress,
            Phone = dto.Phone,
            ReceiverName = dto.ReceiverName,
            PaymentMethod = dto.PaymentMethod,
            Note = dto.Note,
            Status = OrderStatus.Pending,
            PaymentStatus = "Unpaid",
            OrderCode = long.Parse(DateTime.Now.ToString("yyMMddHHmmss") + new Random().Next(10, 99).ToString()),
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        await _orderRepository.CreateAsync(order);

        // Clear cart
        cart.Items.Clear();
        cart.UpdatedAt = DateTime.UtcNow;
        await _cartRepository.UpdateAsync(cart.Id, cart);

        return await MapOrderToDto(order);
    }

    public async Task<PagedResultDto<OrderDto>> GetOrdersAsync(string? userId, int page, int pageSize)
    {
        var builder = Builders<Order>.Filter;
        var filter = userId != null
            ? builder.Eq(o => o.UserId, userId)
            : builder.Empty;

        var totalCount = await _context.Orders.CountDocumentsAsync(filter);
        var orders = await _context.Orders
            .Find(filter)
            .SortByDescending(o => o.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Limit(pageSize)
            .ToListAsync();

        var orderDtos = new List<OrderDto>();
        foreach (var order in orders)
        {
            orderDtos.Add(await MapOrderToDto(order));
        }

        return new PagedResultDto<OrderDto>
        {
            Items = orderDtos,
            TotalCount = (int)totalCount,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<OrderDto> GetOrderByIdAsync(string id, string? userId = null)
    {
        var order = await _orderRepository.GetByIdAsync(id);
        if (order == null)
            throw new Exception("Order not found.");

        if (userId != null && order.UserId != userId)
            throw new Exception("Access denied.");

        return await MapOrderToDto(order);
    }

    public async Task<OrderDto> UpdateOrderStatusAsync(string id, UpdateOrderStatusDto dto)
    {
        var order = await _orderRepository.GetByIdAsync(id);
        if (order == null)
            throw new Exception("Order not found.");

        if (!OrderStatus.IsValid(dto.Status))
            throw new Exception("Invalid order status.");

        order.Status = dto.Status;
        order.UpdatedAt = DateTime.UtcNow;
        await _orderRepository.UpdateAsync(id, order);

        return await MapOrderToDto(order);
    }

    public async Task<OrderDto> CancelOrderAsync(string id, string userId)
    {
        var order = await _orderRepository.GetByIdAsync(id);
        if (order == null)
            throw new Exception("Order not found.");

        if (order.UserId != userId)
            throw new Exception("Access denied.");

        if (order.Status != OrderStatus.Pending)
            throw new Exception("Only pending orders can be cancelled.");

        // Restore stock
        foreach (var item in order.Items)
        {
            var product = await _productRepository.GetByIdAsync(item.ProductId);
            if (product != null)
            {
                product.Stock += item.Quantity;
                product.Sold -= item.Quantity;
                product.UpdatedAt = DateTime.UtcNow;
                await _productRepository.UpdateAsync(product.Id, product);
            }
        }

        order.Status = OrderStatus.Cancelled;
        order.UpdatedAt = DateTime.UtcNow;
        await _orderRepository.UpdateAsync(id, order);

        return await MapOrderToDto(order);
    }

    public async Task UpdatePaymentStatusByOrderCodeAsync(long orderCode, string paymentStatus)
    {
        var order = await _context.Orders.Find(o => o.OrderCode == orderCode).FirstOrDefaultAsync();
        if (order != null)
        {
            order.PaymentStatus = paymentStatus;
            
            // If Paid via PayOS, we can auto-confirm the order if it's still Pending
            if (paymentStatus == "Paid" && order.Status == OrderStatus.Pending)
            {
                order.Status = OrderStatus.Confirmed;
            }

            order.UpdatedAt = DateTime.UtcNow;
            await _orderRepository.UpdateAsync(order.Id, order);
        }
    }

    private async Task<OrderDto> MapOrderToDto(Order order)
    {
        var dto = _mapper.Map<OrderDto>(order);
        var user = await _userRepository.GetByIdAsync(order.UserId);
        dto.UserName = user?.FullName ?? "Unknown";
        return dto;
    }
}
