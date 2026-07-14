namespace PhoneStore.Application.Interfaces;

public interface IEmailService
{
    Task SendPasswordResetEmailAsync(string recipientEmail, string recipientName, string resetToken, string resetLink);
    Task SendWelcomeEmailAsync(string recipientEmail, string recipientName);
    Task SendOrderConfirmationEmailAsync(string recipientEmail, string recipientName, string orderId);
}
