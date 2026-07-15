using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using PhoneStore.Application.DTOs.AI;
using PhoneStore.Application.Exceptions;
using PhoneStore.Application.Interfaces.AI;

namespace PhoneStore.Infrastructure.AI.Providers;

public class GeminiProvider : IAIProvider
{
    private const string DefaultModel = "gemini-2.5-flash";

    private readonly HttpClient _httpClient;
    private readonly string _apiKey;
    private readonly string _model;
    private readonly ILogger<GeminiProvider> _logger;

    public GeminiProvider(HttpClient httpClient, IConfiguration configuration, ILogger<GeminiProvider> logger)
    {
        _httpClient = httpClient;
        _apiKey = configuration["Gemini:ApiKey"]?.Trim() ?? string.Empty;
        var configuredModel = configuration["Gemini:Model"];
        _model = string.IsNullOrWhiteSpace(configuredModel) ? DefaultModel : configuredModel.Trim();
        _logger = logger;
    }

    public async Task<ChatMessageDto> GenerateResponseAsync(List<ChatMessageDto> history, IEnumerable<IAITool> availableTools)
    {
        if (string.IsNullOrWhiteSpace(_apiKey))
        {
            throw new AIProviderException("Trợ lý AI chưa được cấu hình. Vui lòng liên hệ quản trị viên.", StatusCodes.Status503ServiceUnavailable);
        }

        var requestUrl = $"https://generativelanguage.googleapis.com/v1beta/models/{Uri.EscapeDataString(_model)}:generateContent?key={Uri.EscapeDataString(_apiKey)}";

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
                                id = msg.ToolCallId,
                                response = new { result = msg.Content }
                            }
                        }
                    }
                });
                continue;
            }

            if (msg.Role.Equals("assistant", StringComparison.OrdinalIgnoreCase) &&
                !string.IsNullOrEmpty(msg.ToolName))
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
                                args = string.IsNullOrEmpty(msg.Content) ? new { } : JsonSerializer.Deserialize<object>(msg.Content),
                                id = msg.ToolCallId
                            },
                            thoughtSignature = msg.ThoughtSignature
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

        var toolDeclarations = availableTools.Select(t => new
        {
            name = t.Name,
            description = t.Description,
            parameters = JsonSerializer.Deserialize<object>(t.ParametersSchema)
        }).ToArray();

        var requestBodyObj = new
        {
            systemInstruction = string.IsNullOrEmpty(systemInstruction) ? null : new
            {
                parts = new[] { new { text = systemInstruction } }
            },
            contents = contents,
            tools = toolDeclarations.Length == 0
                ? null
                : new[] { new { functionDeclarations = toolDeclarations } },
            generationConfig = new
            {
                temperature = 0.2
            }
        };

        var jsonOptions = new JsonSerializerOptions { DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull };
        var jsonBody = JsonSerializer.Serialize(requestBodyObj, jsonOptions);
        
        using var response = await _httpClient.PostAsync(requestUrl, new StringContent(jsonBody, Encoding.UTF8, "application/json"));
        var responseString = await response.Content.ReadAsStringAsync();

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogWarning("Gemini API request failed with status code {StatusCode}.", (int)response.StatusCode);
            throw CreateProviderException(response.StatusCode);
        }

        using var doc = JsonDocument.Parse(responseString);
        var root = doc.RootElement;

        if (!root.TryGetProperty("candidates", out var candidates) || candidates.GetArrayLength() == 0)
        {
            _logger.LogWarning("Gemini API returned no candidates.");
            throw new AIProviderException("Trợ lý AI không thể tạo phản hồi lúc này. Vui lòng thử lại sau.", StatusCodes.Status502BadGateway);
        }

        if (!candidates[0].TryGetProperty("content", out var content) ||
            !content.TryGetProperty("parts", out var parts) ||
            parts.GetArrayLength() == 0)
        {
            _logger.LogWarning("Gemini API returned a candidate without content.");
            throw new AIProviderException("Trợ lý AI không thể tạo phản hồi lúc này. Vui lòng thử lại sau.", StatusCodes.Status502BadGateway);
        }

        var functionCallPart = parts.EnumerateArray()
            .FirstOrDefault(item => item.TryGetProperty("functionCall", out _));

        if (functionCallPart.ValueKind != JsonValueKind.Undefined &&
            functionCallPart.TryGetProperty("functionCall", out var functionCall))
        {
            var toolName = functionCall.GetProperty("name").GetString();
            var args = functionCall.TryGetProperty("args", out var argsElement) ? argsElement.GetRawText() : "{}";
            
            return new ChatMessageDto
            {
                Role = "assistant",
                Content = args,
                ToolName = toolName,
                ToolCallId = functionCall.TryGetProperty("id", out var id) ? id.GetString() : null,
                ThoughtSignature = functionCallPart.TryGetProperty("thoughtSignature", out var thoughtSignature) ? thoughtSignature.GetString() : null
            };
        }
        else
        {
            var text = string.Join(string.Empty, parts.EnumerateArray()
                .Where(item => item.TryGetProperty("text", out _))
                .Select(item => item.GetProperty("text").GetString()));

            return new ChatMessageDto
            {
                Role = "assistant",
                Content = text
            };
        }
    }

    private static AIProviderException CreateProviderException(HttpStatusCode statusCode)
    {
        return statusCode switch
        {
            HttpStatusCode.TooManyRequests => new AIProviderException(
                "Trợ lý AI đang nhận nhiều yêu cầu. Vui lòng thử lại sau ít phút.",
                StatusCodes.Status429TooManyRequests),
            HttpStatusCode.Unauthorized or HttpStatusCode.Forbidden => new AIProviderException(
                "Trợ lý AI tạm thời chưa sẵn sàng. Vui lòng liên hệ quản trị viên.",
                StatusCodes.Status503ServiceUnavailable),
            HttpStatusCode.NotFound => new AIProviderException(
                "Mô hình AI hiện không khả dụng. Vui lòng liên hệ quản trị viên.",
                StatusCodes.Status503ServiceUnavailable),
            _ => new AIProviderException(
                "Trợ lý AI tạm thời không thể phản hồi. Vui lòng thử lại sau.",
                StatusCodes.Status502BadGateway)
        };
    }
}
