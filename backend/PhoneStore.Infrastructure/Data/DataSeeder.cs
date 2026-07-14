using BCrypt.Net;

namespace PhoneStore.Infrastructure.Data;

public class DataSeeder
{
    private readonly MongoDbContext _context;

    public DataSeeder(MongoDbContext context)
    {
        _context = context;
    }

    public async Task SeedAsync()
    {
        // Seed Admin user if not exists
        var adminExists = await _context.Users.Find(u => u.Role == "Admin").AnyAsync();
        if (!adminExists)
        {
            var admin = new Domain.Entities.User
            {
                FullName = "System Admin",
                Email = "admin@phonestore.com",
                Password = BCrypt.Net.BCrypt.HashPassword("Admin@123"),
                Role = "Admin",
                Phone = "0123456789",
                Address = "Ho Chi Minh City, Vietnam",
                IsActive = true
            };
            await _context.Users.InsertOneAsync(admin);
        }

        // Seed Brands
        var brandCount = await _context.Brands.CountDocumentsAsync(_ => true);
        if (brandCount == 0)
        {
            var brands = new List<Domain.Entities.Brand>
            {
                new() { Name = "Apple", Logo = "https://upload.wikimedia.org/wikipedia/commons/f/fa/Apple_logo_black.svg" },
                new() { Name = "Samsung", Logo = "https://upload.wikimedia.org/wikipedia/commons/2/24/Samsung_Logo.svg" },
                new() { Name = "Xiaomi", Logo = "https://upload.wikimedia.org/wikipedia/commons/a/ae/Xiaomi_logo_%282021-%29.svg" },
                new() { Name = "OPPO", Logo = "https://upload.wikimedia.org/wikipedia/commons/0/0a/OPPO_LOGO_2019.svg" },
                new() { Name = "Vivo", Logo = "https://upload.wikimedia.org/wikipedia/commons/1/10/Vivo_logo_2019.svg" },
                new() { Name = "Realme", Logo = "https://upload.wikimedia.org/wikipedia/commons/9/91/Realme_logo.svg" }
            };
            await _context.Brands.InsertManyAsync(brands);
        }

        // Seed Categories
        var categoryCount = await _context.Categories.CountDocumentsAsync(_ => true);
        if (categoryCount == 0)
        {
            var categories = new List<Domain.Entities.Category>
            {
                new() { Name = "Flagship", Description = "High-end premium smartphones" },
                new() { Name = "Mid-range", Description = "Mid-range smartphones with great value" },
                new() { Name = "Budget", Description = "Affordable smartphones for everyone" },
                new() { Name = "Gaming", Description = "Gaming-focused smartphones" }
            };
            await _context.Categories.InsertManyAsync(categories);
        }

        // Seed Products
        var productCount = await _context.Products.CountDocumentsAsync(_ => true);
        if (productCount == 0)
        {
            var brands = await _context.Brands.Find(_ => true).ToListAsync();
            var categories = await _context.Categories.Find(_ => true).ToListAsync();

            var apple = brands.First(b => b.Name == "Apple");
            var samsung = brands.First(b => b.Name == "Samsung");
            var xiaomi = brands.First(b => b.Name == "Xiaomi");
            var oppo = brands.First(b => b.Name == "OPPO");

            var flagship = categories.First(c => c.Name == "Flagship");
            var midrange = categories.First(c => c.Name == "Mid-range");
            var budget = categories.First(c => c.Name == "Budget");
            var gaming = categories.First(c => c.Name == "Gaming");

            var products = new List<Domain.Entities.Product>
            {
                new()
                {
                    Name = "iPhone 16 Pro Max",
                    Description = "The most advanced iPhone ever with A18 Pro chip, 48MP camera system, and titanium design.",
                    Price = 34990000,
                    SalePrice = 32990000,
                    BrandId = apple.Id,
                    CategoryId = flagship.Id,
                    Images = new List<string>
                    {
                        "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-16-pro-max.png"
                    },
                    Specifications = new Domain.Entities.ProductSpecification
                    {
                        Ram = "8GB", Rom = "256GB", ScreenSize = "6.9 inch",
                        Battery = "4685 mAh", Cpu = "Apple A18 Pro", Os = "iOS 18", Color = "Desert Titanium"
                    },
                    Stock = 50, Sold = 120, AverageRating = 4.8, TotalReviews = 45
                },
                new()
                {
                    Name = "iPhone 16 Pro",
                    Description = "Pro-level performance with A18 Pro chip and advanced camera system.",
                    Price = 28990000,
                    SalePrice = 27490000,
                    BrandId = apple.Id,
                    CategoryId = flagship.Id,
                    Images = new List<string>
                    {
                        "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/i/p/iphone-16-pro_1_.png"
                    },
                    Specifications = new Domain.Entities.ProductSpecification
                    {
                        Ram = "8GB", Rom = "256GB", ScreenSize = "6.3 inch",
                        Battery = "3582 mAh", Cpu = "Apple A18 Pro", Os = "iOS 18", Color = "Natural Titanium"
                    },
                    Stock = 35, Sold = 85, AverageRating = 4.7, TotalReviews = 32
                },
                new()
                {
                    Name = "Samsung Galaxy S24 Ultra",
                    Description = "Galaxy AI powered flagship with S Pen, titanium frame and 200MP camera.",
                    Price = 33990000,
                    SalePrice = 29990000,
                    BrandId = samsung.Id,
                    CategoryId = flagship.Id,
                    Images = new List<string>
                    {
                        "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/s/s/ss-s24-ultra-702.png"
                    },
                    Specifications = new Domain.Entities.ProductSpecification
                    {
                        Ram = "12GB", Rom = "256GB", ScreenSize = "6.8 inch",
                        Battery = "5000 mAh", Cpu = "Snapdragon 8 Gen 3", Os = "Android 14", Color = "Titanium Gray"
                    },
                    Stock = 40, Sold = 95, AverageRating = 4.6, TotalReviews = 38
                },
                new()
                {
                    Name = "Samsung Galaxy Z Fold6",
                    Description = "The ultimate foldable experience with Galaxy AI and enhanced multitasking.",
                    Price = 45990000,
                    SalePrice = 41990000,
                    BrandId = samsung.Id,
                    CategoryId = flagship.Id,
                    Images = new List<string>
                    {
                        "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/s/a/samsung-galaxy-z-fold-6.png"
                    },
                    Specifications = new Domain.Entities.ProductSpecification
                    {
                        Ram = "12GB", Rom = "256GB", ScreenSize = "7.6 inch",
                        Battery = "4400 mAh", Cpu = "Snapdragon 8 Gen 3", Os = "Android 14", Color = "Silver Shadow"
                    },
                    Stock = 20, Sold = 30, AverageRating = 4.5, TotalReviews = 15
                },
                new()
                {
                    Name = "Xiaomi 14 Ultra",
                    Description = "Leica camera system with Snapdragon 8 Gen 3 processor.",
                    Price = 23990000,
                    SalePrice = 21990000,
                    BrandId = xiaomi.Id,
                    CategoryId = flagship.Id,
                    Images = new List<string>
                    {
                        "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/x/i/xiaomi-14-ultra_1_.png"
                    },
                    Specifications = new Domain.Entities.ProductSpecification
                    {
                        Ram = "16GB", Rom = "512GB", ScreenSize = "6.73 inch",
                        Battery = "5000 mAh", Cpu = "Snapdragon 8 Gen 3", Os = "Android 14", Color = "Black"
                    },
                    Stock = 25, Sold = 45, AverageRating = 4.5, TotalReviews = 20
                },
                new()
                {
                    Name = "OPPO Find X7 Ultra",
                    Description = "Dual periscope camera system and Dimensity 9300 chipset.",
                    Price = 22990000,
                    SalePrice = 19990000,
                    BrandId = oppo.Id,
                    CategoryId = flagship.Id,
                    Images = new List<string>
                    {
                        "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/o/p/oppo-find-x7-ultra.png"
                    },
                    Specifications = new Domain.Entities.ProductSpecification
                    {
                        Ram = "16GB", Rom = "256GB", ScreenSize = "6.82 inch",
                        Battery = "5000 mAh", Cpu = "Dimensity 9300", Os = "Android 14", Color = "Sepia Brown"
                    },
                    Stock = 30, Sold = 35, AverageRating = 4.4, TotalReviews = 18
                },
                new()
                {
                    Name = "Samsung Galaxy A55 5G",
                    Description = "Premium mid-range with Super AMOLED display and water resistance.",
                    Price = 10490000,
                    SalePrice = 9290000,
                    BrandId = samsung.Id,
                    CategoryId = midrange.Id,
                    Images = new List<string>
                    {
                        "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/s/a/samsung-galaxy-a55-5g.png"
                    },
                    Specifications = new Domain.Entities.ProductSpecification
                    {
                        Ram = "8GB", Rom = "128GB", ScreenSize = "6.6 inch",
                        Battery = "5000 mAh", Cpu = "Exynos 1480", Os = "Android 14", Color = "Awesome Iceblue"
                    },
                    Stock = 60, Sold = 150, AverageRating = 4.3, TotalReviews = 55
                },
                new()
                {
                    Name = "Xiaomi Redmi Note 13 Pro",
                    Description = "200MP camera, 120Hz AMOLED display, great value mid-range phone.",
                    Price = 7990000,
                    SalePrice = 6990000,
                    BrandId = xiaomi.Id,
                    CategoryId = midrange.Id,
                    Images = new List<string>
                    {
                        "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/x/i/xiaomi-redmi-note-13-pro.png"
                    },
                    Specifications = new Domain.Entities.ProductSpecification
                    {
                        Ram = "8GB", Rom = "128GB", ScreenSize = "6.67 inch",
                        Battery = "5100 mAh", Cpu = "Snapdragon 7s Gen 2", Os = "Android 14", Color = "Midnight Black"
                    },
                    Stock = 80, Sold = 200, AverageRating = 4.4, TotalReviews = 78
                },
                new()
                {
                    Name = "OPPO A58",
                    Description = "Stylish budget phone with 33W fast charging and 5000mAh battery.",
                    Price = 4990000,
                    SalePrice = 4490000,
                    BrandId = oppo.Id,
                    CategoryId = budget.Id,
                    Images = new List<string>
                    {
                        "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/o/p/oppo-a58-4g.png"
                    },
                    Specifications = new Domain.Entities.ProductSpecification
                    {
                        Ram = "6GB", Rom = "128GB", ScreenSize = "6.72 inch",
                        Battery = "5000 mAh", Cpu = "Helio G85", Os = "Android 13", Color = "Glowing Black"
                    },
                    Stock = 100, Sold = 300, AverageRating = 4.2, TotalReviews = 90
                },
                new()
                {
                    Name = "Xiaomi Redmi Note 13",
                    Description = "Budget-friendly phone with 108MP camera and 120Hz AMOLED display.",
                    Price = 4990000,
                    SalePrice = 4490000,
                    BrandId = xiaomi.Id,
                    CategoryId = budget.Id,
                    Images = new List<string>
                    {
                        "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/x/i/xiaomi-redmi-note-13.png"
                    },
                    Specifications = new Domain.Entities.ProductSpecification
                    {
                        Ram = "6GB", Rom = "128GB", ScreenSize = "6.67 inch",
                        Battery = "5000 mAh", Cpu = "Snapdragon 685", Os = "Android 13", Color = "Mint Green"
                    },
                    Stock = 90, Sold = 250, AverageRating = 4.3, TotalReviews = 85
                }
            };
            await _context.Products.InsertManyAsync(products);
        }

        // Seed Vouchers
        var voucherCount = await _context.Vouchers.CountDocumentsAsync(_ => true);
        if (voucherCount == 0)
        {
            var vouchers = new List<Domain.Entities.Voucher>
            {
                new()
                {
                    Code = "WELCOME10",
                    Description = "Welcome discount 10% for new customers",
                    DiscountType = "Percentage",
                    DiscountValue = 10,
                    MinOrderAmount = 5000000,
                    MaxDiscount = 2000000,
                    Quantity = 100,
                    Used = 0,
                    StartDate = DateTime.UtcNow,
                    EndDate = DateTime.UtcNow.AddMonths(3)
                },
                new()
                {
                    Code = "SAVE500K",
                    Description = "Fixed discount 500,000 VND",
                    DiscountType = "Fixed",
                    DiscountValue = 500000,
                    MinOrderAmount = 10000000,
                    MaxDiscount = 500000,
                    Quantity = 50,
                    Used = 0,
                    StartDate = DateTime.UtcNow,
                    EndDate = DateTime.UtcNow.AddMonths(1)
                },
                new()
                {
                    Code = "SUMMER2024",
                    Description = "Summer sale 15% off",
                    DiscountType = "Percentage",
                    DiscountValue = 15,
                    MinOrderAmount = 8000000,
                    MaxDiscount = 3000000,
                    Quantity = 200,
                    Used = 0,
                    StartDate = DateTime.UtcNow,
                    EndDate = DateTime.UtcNow.AddMonths(2)
                }
            };
            await _context.Vouchers.InsertManyAsync(vouchers);
        }
    }
}
