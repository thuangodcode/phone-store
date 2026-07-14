using Microsoft.Extensions.Configuration;
using PhoneStore.Application.Interfaces;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;

namespace PhoneStore.Infrastructure.Services;

public class PayOSService : IPayOSService
{
    private readonly string _clientId;
    private readonly string _apiKey;
    private readonly string _checksumKey;
    private readonly HttpClient _httpClient;

    public PayOSService(IConfiguration configuration)
    {
        _clientId = configuration["PayOS:ClientId"] ?? "";
        _apiKey = configuration["PayOS:ApiKey"] ?? "";
        _checksumKey = configuration["PayOS:ChecksumKey"] ?? "";
        _httpClient = new HttpClient();
        _httpClient.BaseAddress = new Uri("https://api-merchant.payos.vn");
        _httpClient.DefaultRequestHeaders.Add("x-client-id", _clientId);
        _httpClient.DefaultRequestHeaders.Add("x-api-key", _apiKey);
    }

    public async Task<CreatePaymentResult> CreatePaymentLink(long orderCode, int amount, string description, string returnUrl, string cancelUrl)
    {
        var dataStr = $"amount={amount}&cancelUrl={cancelUrl}&description={description}&orderCode={orderCode}&returnUrl={returnUrl}";
        var signature = CreateSignature(dataStr, _checksumKey);

        var requestBody = new
        {
            orderCode = orderCode,
            amount = amount,
            description = description,
            cancelUrl = cancelUrl,
            returnUrl = returnUrl,
            signature = signature
        };

        var content = new StringContent(JsonSerializer.Serialize(requestBody), Encoding.UTF8, "application/json");
        var response = await _httpClient.PostAsync("/v2/payment-requests", content);
        
        if (!response.IsSuccessStatusCode)
        {
            var errorContent = await response.Content.ReadAsStringAsync();
            throw new Exception($"PayOS API Error: {errorContent}");
        }

        var jsonResponse = await response.Content.ReadAsStringAsync();
        using var document = JsonDocument.Parse(jsonResponse);
        
        var checkoutUrl = document.RootElement.GetProperty("data").GetProperty("checkoutUrl").GetString();

        return new CreatePaymentResult
        {
            checkoutUrl = checkoutUrl ?? ""
        };
    }

    public WebhookType VerifyPaymentWebhookData(WebhookType webhookType)
    {
        // Simple verification for now. In a real app, verify webhook signature using ChecksumKey.
        return webhookType;
    }

    public async Task<string> GetPaymentStatus(long orderCode)
    {
        var response = await _httpClient.GetAsync($"/v2/payment-requests/{orderCode}");
        if (!response.IsSuccessStatusCode)
        {
            return "PENDING";
        }
        var jsonResponse = await response.Content.ReadAsStringAsync();
        using var document = JsonDocument.Parse(jsonResponse);
        var status = document.RootElement.GetProperty("data").GetProperty("status").GetString();
        return status ?? "PENDING";
    }

    private string CreateSignature(string data, string key)
    {
        var keyBytes = Encoding.UTF8.GetBytes(key);
        var dataBytes = Encoding.UTF8.GetBytes(data);

        using var hmac = new HMACSHA256(keyBytes);
        var hashBytes = hmac.ComputeHash(dataBytes);

        return BitConverter.ToString(hashBytes).Replace("-", "").ToLower();
    }
}
