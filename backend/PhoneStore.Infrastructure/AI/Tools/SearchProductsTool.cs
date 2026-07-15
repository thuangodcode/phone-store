using System;
using System.Linq;
using System.Text.Json;
using System.Threading.Tasks;
using PhoneStore.Application.Interfaces;
using PhoneStore.Application.Interfaces.AI;

namespace PhoneStore.Infrastructure.AI.Tools;

public class SearchProductsTool : IAITool
{
    private readonly IProductService _productService;

    public SearchProductsTool(IProductService productService)
    {
        _productService = productService;
    }

    public string Name => "SearchProducts";

    public string Description => "Search for smartphone products in the database based on a keyword search query.";

    public string ParametersSchema => @"{
        ""type"": ""object"",
        ""properties"": {
            ""query"": {
                ""type"": ""string"",
                ""description"": ""The search keyword, such as 'iPhone 16' or 'Samsung Galaxy'""
            }
        },
        ""required"": [""query""]
    }";

    public async Task<string> ExecuteAsync(string arguments)
    {
        try
        {
            var args = JsonSerializer.Deserialize<SearchProductsArgs>(arguments);
            var query = args?.Query ?? string.Empty;

            var result = await _productService.GetProductsAsync(1, 5, false, query, string.Empty, string.Empty);
            
            if (result.TotalCount == 0 || result.Items == null || !result.Items.Any())
            {
                return JsonSerializer.Serialize(new { Message = "No products found." });
            }

            var simplifiedResults = result.Items.Select(p => new
            {
                p.Id,
                p.Name,
                p.Price,
                p.BrandId,
                p.CategoryId,
                InStock = p.Stock > 0
            });

            return JsonSerializer.Serialize(simplifiedResults);
        }
        catch (Exception ex)
        {
            return JsonSerializer.Serialize(new { Error = ex.Message });
        }
    }

    private class SearchProductsArgs
    {
        public string Query { get; set; } = string.Empty;
    }
}
