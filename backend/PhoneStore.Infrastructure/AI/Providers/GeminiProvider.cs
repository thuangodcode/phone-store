using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using PhoneStore.Application.DTOs.AI;
using PhoneStore.Application.Interfaces.AI;

namespace PhoneStore.Infrastructure.AI.Providers;

public class GeminiProvider : IAIProvider
{
    private readonly HttpClient _httpClient;
    private readonly string _apiKey;

    public GeminiProvider(HttpClient httpClient, IConfiguration configuration)
    {
        _httpClient = httpClient;
        _apiKey = configuration["Gemini:ApiKey"] ?? throw new ArgumentNullException("Gemini:ApiKey not found in configuration.");
    }

    public async Task<ChatMessageDto> GenerateResponseAsync(List<ChatMessageDto> history, IEnumerable<IAITool> availableTools)
    {
        var requestUrl = $"https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key={_apiKey}";

        var contents = new List<object>();
        var systemInstruction = "";

        // Separate system prompt from the rest
        var systemMessage = history.FirstOrDefault(m => m.Role.Equals("system", StringComparison.OrdinalIgnoreCase));
        if (systemMessage != null)
        {
            systemInstruction = systemMessage.Content;
        }

        foreach (var msg in history.Where(m => !m.Role.Equals("system", StringComparison.OrdinalIgnoreCase)))
        {
            var role = msg.Role.ToLower() == "assistant" || msg.Role.ToLower() == "model" ? "model" : "user";
            
            if (msg.Role.ToLower() == "tool")
            {
                // Gemini tool response format
                contents.Add(new
                {
                    role = "user",
                    parts = new[]
                    {
                        new
                        {
                            functionResponse = new
                            {
                                name = msg.ToolName,
                                response = new { result = msg.Content }
                            }
                        }
                    }
                });
                continue;
            }

            if (!string.IsNullOrEmpty(msg.ToolCallId))
            {
                 contents.Add(new
                {
                    role = "model",
                    parts = new[]
                    {
                        new
                        {
                            functionCall = new
                            {
                                name = msg.ToolName,
                                args = string.IsNullOrEmpty(msg.Content) ? new { } : JsonSerializer.Deserialize<object>(msg.Content)
                            }
                        }
                    }
                });
                continue;
            }

            contents.Add(new
            {
                role = role,
                parts = new[] { new { text = msg.Content } }
            });
        }

        var toolsArray = availableTools.Select(t => new
        {
            function_declarations = new[]
            {
                new
                {
                    name = t.Name,
                    description = t.Description,
                    parameters = JsonSerializer.Deserialize<object>(t.ParametersSchema)
                }
            }
        }).ToList();

        var requestBodyObj = new
        {
            systemInstruction = string.IsNullOrEmpty(systemInstruction) ? null : new
            {
                parts = new[] { new { text = systemInstruction } }
            },
            contents = contents,
            tools = toolsArray.Any() ? toolsArray : null,
            generationConfig = new
            {
                temperature = 0.2
            }
        };

        var jsonOptions = new JsonSerializerOptions { DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull };
        var jsonBody = JsonSerializer.Serialize(requestBodyObj, jsonOptions);
        
        var response = await _httpClient.PostAsync(requestUrl, new StringContent(jsonBody, Encoding.UTF8, "application/json"));
        var responseString = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
        {
            throw new Exception($"Gemini API error: {responseString}");
        }

        using var doc = JsonDocument.Parse(responseString);
        var root = doc.RootElement;
        
        var candidate = root.GetProperty("candidates")[0];
        var part = candidate.GetProperty("content").GetProperty("parts")[0];

        if (part.TryGetProperty("functionCall", out var functionCall))
        {
            var toolName = functionCall.GetProperty("name").GetString();
            var args = functionCall.TryGetProperty("args", out var argsElement) ? argsElement.GetRawText() : "{}";
            
            return new ChatMessageDto
            {
                Role = "assistant",
                Content = args,
                ToolName = toolName,
                ToolCallId = Guid.NewGuid().ToString() // Gemini doesn't use ToolCallId strictly, but we need it for tracking
            };
        }
        else
        {
            var text = part.GetProperty("text").GetString();
            return new ChatMessageDto
            {
                Role = "assistant",
                Content = text ?? string.Empty
            };
        }
    }
}
