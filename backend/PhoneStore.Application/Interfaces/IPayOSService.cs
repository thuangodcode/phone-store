namespace PhoneStore.Application.Interfaces;

public class CreatePaymentResult
{
    public string checkoutUrl { get; set; } = string.Empty;
}

public class WebhookType
{
    public string code { get; set; } = string.Empty;
    public bool success { get; set; }
    public long orderCode { get; set; }
}

public interface IPayOSService
{
    Task<CreatePaymentResult> CreatePaymentLink(long orderCode, int amount, string description, string returnUrl, string cancelUrl);
    WebhookType VerifyPaymentWebhookData(WebhookType webhookType);
}
