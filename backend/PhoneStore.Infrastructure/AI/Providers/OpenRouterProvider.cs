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

public class OpenRouterProvider : IAIProvider
{
    private const string DefaultModel = "openai/gpt-4o-mini";

    private readonly HttpClient _httpClient;
    private readonly string _apiKey;
    private readonly string _model;
    private readonly ILogger<OpenRouterProvider> _logger;

    public OpenRouterProvider(HttpClient httpClient, IConfiguration configuration, ILogger<OpenRouterProvider> logger)
    {
        _httpClient = httpClient;
        _apiKey = configuration["OpenRouter:ApiKey"]?.Trim() ?? string.Empty;
        var configuredModel = configuration["OpenRouter:Model"];
        _model = string.IsNullOrWhiteSpace(configuredModel) ? DefaultModel : configuredModel.Trim();
        _logger = logger;
    }

    public async Task<ChatMessageDto> GenerateResponseAsync(List<ChatMessageDto> history, IEnumerable<IAITool> availableTools)
    {
        if (string.IsNullOrWhiteSpace(_apiKey))
        {
            throw new AIProviderException("Trợ lý AI chưa được cấu hình. Vui lòng liên hệ quản trị viên.", StatusCodes.Status503ServiceUnavailable);
        }

        var requestUrl = "https://openrouter.ai/api/v1/chat/completions";

        var messages = new List<object>();

        // Find system prompt and add it first
        var systemMessage = history.FirstOrDefault(m => m.Role.Equals("system", StringComparison.OrdinalIgnoreCase));
        if (systemMessage != null)
        {
            messages.Add(new { role = "system", content = systemMessage.Content });
        }

        foreach (var msg in history.Where(m => !m.Role.Equals("system", StringComparison.OrdinalIgnoreCase)))
        {
            var role = msg.Role.ToLower() == "assistant" || msg.Role.ToLower() == "model" ? "assistant" : msg.Role.ToLower();

            if (role == "tool")
            {
                messages.Add(new
                {
                    role = "tool",
                    tool_call_id = msg.ToolCallId,
                    content = msg.Content
                });
                continue;
            }

            if (role == "assistant" && !string.IsNullOrEmpty(msg.ToolName))
            {
                // Format for assistant's tool call
                messages.Add(new
                {
                    role = "assistant",
                    content = (string)null, 
                    tool_calls = new[]
                    {
                        new
                        {
                            id = msg.ToolCallId ?? Guid.NewGuid().ToString("N"), // openrouter sometimes requires ID
                            type = "function",
                            function = new
                            {
                                name = msg.ToolName,
                                arguments = msg.Content // The arguments are stored in Content in this app's architecture for tool calls
                            }
                        }
                    }
                });
                continue;
            }

            messages.Add(new
            {
                role = role,
                content = msg.Content
            });
        }

        object[] tools = null;
        if (availableTools != null && availableTools.Any())
        {
            tools = availableTools.Select(t => new
            {
                type = "function",
                function = new
                {
                    name = t.Name,
                    description = t.Description,
                    parameters = JsonSerializer.Deserialize<object>(t.ParametersSchema)
                }
            }).ToArray();
        }

        var requestBodyObj = new
        {
            model = _model,
            messages = messages,
            tools = tools,
            temperature = 0.2
        };

        var jsonOptions = new JsonSerializerOptions { DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull };
        var jsonBody = JsonSerializer.Serialize(requestBodyObj, jsonOptions);

        using var request = new HttpRequestMessage(HttpMethod.Post, requestUrl);
        request.Headers.Add("Authorization", $"Bearer {_apiKey}");
        request.Headers.Add("HTTP-Referer", "https://phone-store.vercel.app");
        request.Headers.Add("X-Title", "PhoneStore AI");
        request.Content = new StringContent(jsonBody, Encoding.UTF8, "application/json");

        HttpResponseMessage response = null;
        string responseString = null;
        int maxRetries = 3;
        int delayMs = 2000;

        for (int i = 0; i <= maxRetries; i++)
        {
            using var reqClone = await CloneHttpRequestMessageAsync(request);
            response = await _httpClient.SendAsync(reqClone);

            if (response.IsSuccessStatusCode)
            {
                responseString = await response.Content.ReadAsStringAsync();
                break;
            }

            if (i < maxRetries && (response.StatusCode == HttpStatusCode.TooManyRequests || response.StatusCode == HttpStatusCode.ServiceUnavailable || (int)response.StatusCode >= 500))
            {
                _logger.LogWarning("OpenRouter API request failed with status code {StatusCode}. Retrying in {Delay}ms... (Attempt {Attempt} of {MaxRetries})", (int)response.StatusCode, delayMs, i + 1, maxRetries);
                await Task.Delay(delayMs);
                delayMs *= 2;
                continue;
            }

            responseString = await response.Content.ReadAsStringAsync();
            _logger.LogWarning("OpenRouter API request failed with status code {StatusCode}. Response: {Response}", (int)response.StatusCode, responseString);
            throw CreateProviderException(response.StatusCode);
        }

        using var doc = JsonDocument.Parse(responseString);
        var root = doc.RootElement;

        if (!root.TryGetProperty("choices", out var choices) || choices.GetArrayLength() == 0)
        {
            _logger.LogWarning("OpenRouter API returned no choices.");
            throw new AIProviderException("Trợ lý AI không thể tạo phản hồi lúc này. Vui lòng thử lại sau.", StatusCodes.Status502BadGateway);
        }

        var firstChoice = choices[0];
        if (!firstChoice.TryGetProperty("message", out var message))
        {
            _logger.LogWarning("OpenRouter API returned a choice without a message.");
            throw new AIProviderException("Trợ lý AI không thể tạo phản hồi lúc này. Vui lòng thử lại sau.", StatusCodes.Status502BadGateway);
        }

        var content = message.TryGetProperty("content", out var c) && c.ValueKind == JsonValueKind.String ? c.GetString() : "";

        if (message.TryGetProperty("tool_calls", out var toolCalls) && toolCalls.ValueKind == JsonValueKind.Array && toolCalls.GetArrayLength() > 0)
        {
            var toolCall = toolCalls[0]; 
            var function = toolCall.GetProperty("function");
            var toolName = function.GetProperty("name").GetString();
            var arguments = function.TryGetProperty("arguments", out var args) ? args.GetString() : "{}";
            var toolCallId = toolCall.GetProperty("id").GetString();

            return new ChatMessageDto
            {
                Role = "assistant",
                Content = arguments,
                ToolName = toolName,
                ToolCallId = toolCallId
            };
        }

        return new ChatMessageDto
        {
            Role = "assistant",
            Content = content
        };
    }

    private async Task<HttpRequestMessage> CloneHttpRequestMessageAsync(HttpRequestMessage req)
    {
        var clone = new HttpRequestMessage(req.Method, req.RequestUri)
        {
            Version = req.Version
        };
        foreach (var header in req.Headers)
            clone.Headers.TryAddWithoutValidation(header.Key, header.Value);
            
        if (req.Content != null)
        {
            var contentString = await req.Content.ReadAsStringAsync();
            clone.Content = new StringContent(contentString, Encoding.UTF8, req.Content.Headers.ContentType?.MediaType ?? "application/json");
        }
        return clone;
    }

    private static AIProviderException CreateProviderException(HttpStatusCode statusCode)
    {
        return statusCode switch
        {
            HttpStatusCode.TooManyRequests => new AIProviderException(
                "Trợ lý AI đang nhận nhiều yêu cầu. Vui lòng thử lại sau ít phút.",
                StatusCodes.Status429TooManyRequests),
            HttpStatusCode.PaymentRequired => new AIProviderException(
                "Tài khoản OpenRouter của bạn đã hết tiền (402 Payment Required). Vui lòng nạp thêm credit để sử dụng.",
                StatusCodes.Status503ServiceUnavailable),
            HttpStatusCode.Unauthorized or HttpStatusCode.Forbidden => new AIProviderException(
                "Trợ lý AI tạm thời chưa sẵn sàng do lỗi xác thực. Vui lòng liên hệ quản trị viên.",
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
