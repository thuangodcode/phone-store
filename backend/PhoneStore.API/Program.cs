using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using PhoneStore.Application.Interfaces;
using PhoneStore.Application.Mappings;
using PhoneStore.Domain.Interfaces;
using PhoneStore.Infrastructure.Data;
using PhoneStore.Infrastructure.Repositories;
using PhoneStore.Infrastructure.Services;
using PhoneStore.API.Middlewares;
using PhoneStore.API.Hubs;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddControllers();
builder.Services.AddSignalR();
builder.Services.AddHttpClient();

// Configure MongoDB Settings
var mongoDbSettings = new MongoDbSettings();
builder.Configuration.GetSection("MongoDbSettings").Bind(mongoDbSettings);
builder.Services.AddSingleton(mongoDbSettings);
builder.Services.AddSingleton<MongoDbContext>();

// Register AutoMapper
builder.Services.AddAutoMapper(typeof(MappingProfile));

// Register Repositories
builder.Services.AddScoped(typeof(IRepository<>), typeof(MongoRepository<>));
builder.Services.AddScoped(sp => 
{
    var context = sp.GetRequiredService<MongoDbContext>();
    return context.Users;
});
builder.Services.AddScoped(sp => sp.GetRequiredService<MongoDbContext>().Products);
builder.Services.AddScoped(sp => sp.GetRequiredService<MongoDbContext>().Brands);
builder.Services.AddScoped(sp => sp.GetRequiredService<MongoDbContext>().Categories);
builder.Services.AddScoped(sp => sp.GetRequiredService<MongoDbContext>().Carts);
builder.Services.AddScoped(sp => sp.GetRequiredService<MongoDbContext>().Orders);
builder.Services.AddScoped(sp => sp.GetRequiredService<MongoDbContext>().Reviews);
builder.Services.AddScoped(sp => sp.GetRequiredService<MongoDbContext>().Vouchers);
builder.Services.AddScoped(sp => sp.GetRequiredService<MongoDbContext>().Wishlists);
builder.Services.AddScoped(sp => sp.GetRequiredService<MongoDbContext>().Articles);
builder.Services.AddScoped(sp => sp.GetRequiredService<MongoDbContext>().ChatMessages);
builder.Services.AddScoped(sp => sp.GetRequiredService<MongoDbContext>().ChatSessions);
builder.Services.AddScoped(sp => sp.GetRequiredService<MongoDbContext>().Banners);

// Register Services
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IProductService, ProductService>();
builder.Services.AddScoped<IBrandService, BrandService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<ICartService, CartService>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IReviewService, ReviewService>();
builder.Services.AddScoped<IVoucherService, VoucherService>();
builder.Services.AddScoped<IWishlistService, WishlistService>();
builder.Services.AddScoped<IArticleService, ArticleService>();
builder.Services.AddScoped<IDashboardService, DashboardService>();
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddScoped<IBannerService, BannerService>();
builder.Services.AddSingleton<IPayOSService, PayOSService>();

// Register AI Services
builder.Services.AddHttpClient<PhoneStore.Application.Interfaces.AI.IAIProvider, PhoneStore.Infrastructure.AI.Providers.GeminiProvider>();
builder.Services.AddSingleton<PhoneStore.Application.Interfaces.AI.IAIMemoryService, PhoneStore.Infrastructure.AI.Memory.InMemoryChatContext>();
builder.Services.AddScoped<PhoneStore.Application.Interfaces.AI.IToolRegistry, PhoneStore.Infrastructure.AI.Tools.ToolRegistry>();
builder.Services.AddScoped<PhoneStore.Application.Interfaces.AI.IAIAgentService, PhoneStore.Infrastructure.AI.Agent.AIAgentService>();
builder.Services.AddTransient<PhoneStore.Infrastructure.AI.Tools.SearchProductsTool>();
builder.Services.AddTransient<PhoneStore.Infrastructure.AI.Tools.GetRevenueAnalyticsTool>();
// Register Data Seeder
builder.Services.AddScoped<DataSeeder>();

// Configure JWT Authentication
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Secret"] ?? ""))
        };
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken = context.Request.Query["access_token"];
                var path = context.HttpContext.Request.Path;
                if (!string.IsNullOrEmpty(accessToken) &&
                    (path.StartsWithSegments("/chatHub") || path.StartsWithSegments("/reviewHub")))
                {
                    context.Token = accessToken;
                }
                return Task.CompletedTask;
            }
        };
    });

// Configure CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("CorsPolicy", policy =>
    {
        policy.SetIsOriginAllowed(origin => true)
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

// Configure Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "PhoneStore API", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme. Example: \"Authorization: Bearer {token}\"",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement()
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                },
                Scheme = "oauth2",
                Name = "Bearer",
                In = ParameterLocation.Header,
            },
            new List<string>()
        }
    });
});

var app = builder.Build();

// Execute Data Seeder
using (var scope = app.Services.CreateScope())
{
    var seeder = scope.ServiceProvider.GetRequiredService<DataSeeder>();
    seeder.SeedAsync().Wait();
}

// Enable Swagger in all environments for Render deployment
app.UseSwagger();
app.UseSwaggerUI();

app.UseMiddleware<ExceptionMiddleware>();

app.UseHttpsRedirection();

app.UseRouting();
app.UseCors("CorsPolicy");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<ReviewHub>("/reviewHub");
app.MapHub<ChatHub>("/chatHub");

app.Run();
