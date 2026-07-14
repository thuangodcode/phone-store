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

    private void AddAuditLog(Order order, string staffId, string staffName, string action, string details, string? oldValue, string? newValue)
    {
        var log = new OrderAuditLog
        {
            OrderId = order.Id,
            StaffId = staffId,
            StaffName = staffName,
            Action = action,
            Details = details,
            OldValue = oldValue,
            NewValue = newValue,
            Timestamp = DateTime.UtcNow
        };
        order.AuditLogs.Add(log);
        // Also save to audit logs collection
        _context.OrderAuditLogs.InsertOne(log);
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
            if (!string.IsNullOrEmpty(cartItem.Storage))
            {
                var storageVariant = product.StorageVariants.FirstOrDefault(v => v.Storage == cartItem.Storage);
                if (storageVariant != null)
                {
                    price = storageVariant.SalePrice > 0 ? storageVariant.SalePrice : storageVariant.Price;
                }
            }

            var image = product.Images.FirstOrDefault() ?? string.Empty;
            if (!string.IsNullOrEmpty(cartItem.Color))
            {
                var colorVariant = product.ColorVariants.FirstOrDefault(v => v.Name == cartItem.Color);
                if (colorVariant != null)
                {
                    price += colorVariant.PriceModifier;
                    if (!string.IsNullOrEmpty(colorVariant.ImageUrl))
                        image = colorVariant.ImageUrl;
                }
            }

            orderItems.Add(new OrderItem
            {
                ProductId = product.Id,
                ProductName = product.Name,
                ProductImage = image,
                Quantity = cartItem.Quantity,
                Price = price,
                Storage = cartItem.Storage,
                Color = cartItem.Color
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

    public async Task<PagedResultDto<OrderDto>> GetOrdersAsync(string? userId, int page, int pageSize, string? search = null, string? status = null, string? paymentStatus = null)
    {
        var builder = Builders<Order>.Filter;
        var filter = builder.Empty;

        if (userId != null)
        {
            filter &= builder.Eq(o => o.UserId, userId);
        }

        if (!string.IsNullOrEmpty(status))
        {
            filter &= builder.Eq(o => o.Status, status);
        }

        if (!string.IsNullOrEmpty(paymentStatus))
        {
            filter &= builder.Eq(o => o.PaymentStatus, paymentStatus);
        }

        if (!string.IsNullOrEmpty(search))
        {
            // Search by order code (if it's numeric) or receiver name
            if (long.TryParse(search, out long orderCode))
            {
                filter &= builder.Eq(o => o.OrderCode, orderCode);
            }
            else
            {
                filter &= builder.Regex(o => o.ReceiverName, new MongoDB.Bson.BsonRegularExpression(search, "i"));
            }
        }

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

    public async Task<OrderDto> UpdateOrderStatusAsync(string id, UpdateOrderStatusDto dto, string staffId, string staffName)
    {
        var order = await _orderRepository.GetByIdAsync(id);
        if (order == null)
            throw new Exception("Order not found.");

        if (!OrderStatus.IsValid(dto.Status))
            throw new Exception("Invalid order status.");

        var oldStatus = order.Status;
        order.Status = dto.Status;
        order.StaffId = staffId;
        order.StaffName = staffName;
        order.UpdatedAt = DateTime.UtcNow;

        // Add audit log
        AddAuditLog(order, staffId, staffName, "UpdatedStatus",
            $"{staffName} đã cập nhật trạng thái đơn hàng #{order.OrderCode} từ '{oldStatus}' sang '{dto.Status}'",
            oldStatus, dto.Status);

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

        var oldStatus = order.Status;
        order.Status = OrderStatus.Cancelled;
        order.UpdatedAt = DateTime.UtcNow;

        await _orderRepository.UpdateAsync(id, order);

        return await MapOrderToDto(order);
    }

    public async Task UpdatePaymentStatusByOrderCodeAsync(long orderCode, string paymentStatus, string? staffId = null, string? staffName = null)
    {
        var order = await _context.Orders.Find(o => o.OrderCode == orderCode).FirstOrDefaultAsync();
        if (order != null)
        {
            var oldPaymentStatus = order.PaymentStatus;
            order.PaymentStatus = paymentStatus;
            
            // If Paid via PayOS, we can auto-confirm the order if it's still Pending
            if (paymentStatus == "Paid" && order.Status == OrderStatus.Pending)
            {
                order.Status = OrderStatus.Confirmed;
            }

            if (!string.IsNullOrEmpty(staffId) && !string.IsNullOrEmpty(staffName))
            {
                order.StaffId = staffId;
                order.StaffName = staffName;
                // Add audit log for payment collection
                AddAuditLog(order, staffId, staffName, "UpdatedPaymentStatus",
                    $"{staffName} đã thu tiền đơn hàng #{orderCode}, số tiền: {order.FinalAmount:n0}đ, trạng thái thanh toán: {paymentStatus}",
                    oldPaymentStatus, paymentStatus);
            }

            order.UpdatedAt = DateTime.UtcNow;
            await _orderRepository.UpdateAsync(order.Id, order);
        }
    }

    public async Task<OrderDto> UpdatePaymentStatusAsync(string orderId, string paymentStatus, string staffId, string staffName)
    {
        var order = await _orderRepository.GetByIdAsync(orderId);
        if (order == null)
            throw new Exception("Order not found.");

        var oldPaymentStatus = order.PaymentStatus;
        order.PaymentStatus = paymentStatus;
        order.StaffId = staffId;
        order.StaffName = staffName;
        order.UpdatedAt = DateTime.UtcNow;

        // Add audit log
        AddAuditLog(order, staffId, staffName, "UpdatedPaymentStatus",
            $"{staffName} đã cập nhật trạng thái thanh toán đơn hàng #{order.OrderCode} từ '{oldPaymentStatus}' sang '{paymentStatus}', số tiền: {order.FinalAmount:n0}đ",
            oldPaymentStatus, paymentStatus);

        await _orderRepository.UpdateAsync(orderId, order);

        return await MapOrderToDto(order);
    }

    private async Task<OrderDto> MapOrderToDto(Order order)
    {
        var dto = _mapper.Map<OrderDto>(order);
        var user = await _userRepository.GetByIdAsync(order.UserId);
        dto.UserName = user?.FullName ?? "Unknown";
        return dto;
    }
}
