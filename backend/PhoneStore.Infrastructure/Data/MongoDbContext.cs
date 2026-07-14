using MongoDB.Driver;
using PhoneStore.Domain.Entities;

namespace PhoneStore.Infrastructure.Data;

public class MongoDbContext
{
    private readonly IMongoDatabase _database;

    public MongoDbContext(MongoDbSettings settings)
    {
        var client = new MongoClient(settings.ConnectionString);
        _database = client.GetDatabase(settings.DatabaseName);
    }

    public IMongoCollection<User> Users => _database.GetCollection<User>("users");
    public IMongoCollection<Product> Products => _database.GetCollection<Product>("products");
    public IMongoCollection<Brand> Brands => _database.GetCollection<Brand>("brands");
    public IMongoCollection<Category> Categories => _database.GetCollection<Category>("categories");
    public IMongoCollection<Cart> Carts => _database.GetCollection<Cart>("carts");
    public IMongoCollection<Order> Orders => _database.GetCollection<Order>("orders");
    public IMongoCollection<Review> Reviews => _database.GetCollection<Review>("reviews");
    public IMongoCollection<Voucher> Vouchers => _database.GetCollection<Voucher>("vouchers");
    public IMongoCollection<Wishlist> Wishlists => _database.GetCollection<Wishlist>("wishlists");
}
