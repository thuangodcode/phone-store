using System;
using System.Text.Json;
using System.Threading.Tasks;
using MongoDB.Bson;
using MongoDB.Driver;
using PhoneStore.Application.Interfaces.AI;
using PhoneStore.Infrastructure.Data;

namespace PhoneStore.Infrastructure.AI.Tools;

public class DatabaseQueryTool : IAITool
{
    private readonly MongoDbContext _context;

    public DatabaseQueryTool(MongoDbContext context)
    {
        _context = context;
    }

    public string Name => "QueryDatabase";
    public string Description => "Reads and extracts data from a specific MongoDB collection. Allows filtering and sorting.";
    public string ParametersSchema => @"{
        ""type"": ""object"",
        ""properties"": {
            ""collectionName"": {
                ""type"": ""string"",
                ""description"": ""The name of the MongoDB collection to query (e.g., 'users', 'products', 'orders', 'vouchers').""
            },
            ""filterJson"": {
                ""type"": ""string"",
                ""description"": ""Optional. A valid JSON string representing the MongoDB filter query (e.g., '{ \""status\"": \""Pending\"" }'). Leave empty to fetch all.""
            },
            ""sortJson"": {
                ""type"": ""string"",
                ""description"": ""Optional. A valid JSON string representing the MongoDB sort definition (e.g., '{ \""createdAt\"": -1 }').""
            },
            ""limit"": {
                ""type"": ""number"",
                ""description"": ""Optional. The maximum number of documents to return (default 20, max 50).""
            }
        },
        ""required"": [""collectionName""]
    }";

    public async Task<string> ExecuteAsync(string arguments)
    {
        try
        {
            using var document = JsonDocument.Parse(arguments);
            var root = document.RootElement;
            var collectionName = root.GetProperty("collectionName").GetString() ?? "";

            if (string.IsNullOrWhiteSpace(collectionName))
                return "Error: collectionName is required.";

            var filterJson = root.TryGetProperty("filterJson", out var filterProp) ? filterProp.GetString() : null;
            var sortJson = root.TryGetProperty("sortJson", out var sortProp) ? sortProp.GetString() : null;
            var limitProp = root.TryGetProperty("limit", out var lp) ? lp.GetInt32() : 20;
            var limit = Math.Min(limitProp, 50);

            var collection = _context.Database.GetCollection<BsonDocument>(collectionName);
            
            FilterDefinition<BsonDocument> filter = Builders<BsonDocument>.Filter.Empty;
            if (!string.IsNullOrWhiteSpace(filterJson) && filterJson != "{}")
            {
                filter = BsonDocument.Parse(filterJson);
            }

            var query = collection.Find(filter);

            if (!string.IsNullOrWhiteSpace(sortJson) && sortJson != "{}")
            {
                query = query.Sort(BsonDocument.Parse(sortJson));
            }

            var results = await query.Limit(limit).ToListAsync();
            
            var jsonArray = new BsonArray(results);
            return jsonArray.ToJson(new MongoDB.Bson.IO.JsonWriterSettings { Indent = true });
        }
        catch (Exception ex)
        {
            return $""Error executing query: {ex.Message}"";
        }
    }
}
