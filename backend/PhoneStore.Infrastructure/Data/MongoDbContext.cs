using MongoDB.Driver;
using PhoneStore.Domain.Entities;
using Microsoft.Extensions.Options;

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
    public IMongoCollection<Article> Articles => _database.GetCollection<Article>("articles");
    public IMongoCollection<ChatMessage> ChatMessages => _database.GetCollection<ChatMessage>("chat_messages");
    public IMongoCollection<ChatSession> ChatSessions => _database.GetCollection<ChatSession>("chat_sessions");
    public IMongoCollection<AIChatMessage> AIChatMessages => _database.GetCollection<AIChatMessage>("ai_chat_messages");
    public IMongoCollection<AIChatSession> AIChatSessions => _database.GetCollection<AIChatSession>("ai_chat_sessions");
    public IMongoCollection<OrderAuditLog> OrderAuditLogs => _database.GetCollection<OrderAuditLog>("order_audit_logs");
    public IMongoCollection<Banner> Banners => _database.GetCollection<Banner>("banners");
    public IMongoCollection<AILog> AILogs => _database.GetCollection<AILog>("ai_logs");
}
