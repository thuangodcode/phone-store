namespace PhoneStore.Infrastructure.Data;

public class EmailSettings
{
    public string ResendApiKey { get; set; } = string.Empty;
    public string SenderEmail { get; set; } = "onboarding@resend.dev";
    public string SenderName { get; set; } = "PhoneStore";
}
