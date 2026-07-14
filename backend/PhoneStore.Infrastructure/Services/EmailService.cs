using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using PhoneStore.Application.Interfaces;
using PhoneStore.Infrastructure.Data;

namespace PhoneStore.Infrastructure.Services;

public class EmailService : IEmailService
{
    private readonly EmailSettings _emailSettings;
    private readonly ILogger<EmailService> _logger;
    private readonly IHttpClientFactory _httpClientFactory;
    private const string ResendApiUrl = "https://api.resend.com/emails";

    public EmailService(IConfiguration configuration, ILogger<EmailService> logger, IHttpClientFactory httpClientFactory)
    {
        _emailSettings = new EmailSettings();
        configuration.GetSection("EmailSettings").Bind(_emailSettings);
        _logger = logger;
        _httpClientFactory = httpClientFactory;
    }

    public async Task SendPasswordResetEmailAsync(string recipientEmail, string recipientName, string resetToken, string resetLink)
    {
        if (string.IsNullOrWhiteSpace(_emailSettings.ResendApiKey))
        {
            _logger.LogWarning("Resend API key is not configured. Cannot send password reset email.");
            throw new Exception("Email service is not configured. Please contact support.");
        }

        var subject = "PhoneStore - Password Reset Request";
        var htmlBody = $@"
        <html>
            <body style='font-family: Arial, sans-serif; line-height: 1.6; color: #333;'>
                <div style='max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 8px;'>
                    <h2 style='color: #0066cc; text-align: center;'>Password Reset Request</h2>
                    <p>Hello <strong>{recipientName}</strong>,</p>
                    <p>We received a request to reset your password. Your new temporary password is:</p>
                    <div style='text-align: center; margin: 20px 0;'>
                        <span style='display: inline-block; background-color: #f5f5f5; padding: 12px 24px; font-size: 18px; font-weight: bold; letter-spacing: 2px; border-radius: 5px; border: 1px solid #ddd;'>{resetToken}</span>
                    </div>
                    <p>Please use this password to log in and change your password immediately.</p>
                    <p><strong>Security Notice:</strong> If you did not request this, please ignore this email.</p>
                    <hr style='border: none; border-top: 1px solid #ddd; margin: 30px 0;'>
                    <p style='font-size: 12px; color: #666; text-align: center;'>© 2024 PhoneStore. All rights reserved.</p>
                </div>
            </body>
        </html>";

        await SendEmailViaResendAsync(recipientEmail, subject, htmlBody);
        _logger.LogInformation("Password reset email sent to {RecipientEmail}", recipientEmail);
    }

    public async Task SendWelcomeEmailAsync(string recipientEmail, string recipientName)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(_emailSettings.ResendApiKey))
            {
                _logger.LogWarning("Resend API key is not configured. Skipping welcome email.");
                return;
            }

            var subject = "Welcome to PhoneStore!";
            var htmlBody = $@"
            <html>
                <body style='font-family: Arial, sans-serif; line-height: 1.6; color: #333;'>
                    <div style='max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 8px;'>
                        <h2 style='color: #0066cc; text-align: center;'>Welcome to PhoneStore!</h2>
                        <p>Hello <strong>{recipientName}</strong>,</p>
                        <p>Thank you for registering with PhoneStore. We are excited to have you here.</p>
                        <div style='text-align: center; margin: 30px 0;'>
                            <a href='https://phone-store.vercel.app' style='display: inline-block; background-color: #0066cc; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; font-weight: bold;'>
                                Start Shopping
                            </a>
                        </div>
                        <hr style='border: none; border-top: 1px solid #ddd; margin: 30px 0;'>
                        <p style='font-size: 12px; color: #666; text-align: center;'>© 2024 PhoneStore. All rights reserved.</p>
                    </div>
                </body>
            </html>";

            await SendEmailViaResendAsync(recipientEmail, subject, htmlBody);
            _logger.LogInformation("Welcome email sent to {RecipientEmail}", recipientEmail);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send welcome email to {RecipientEmail}", recipientEmail);
        }
    }

    public async Task SendOrderConfirmationEmailAsync(string recipientEmail, string recipientName, string orderId)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(_emailSettings.ResendApiKey))
            {
                _logger.LogWarning("Resend API key is not configured. Skipping order confirmation email.");
                return;
            }

            var subject = $"PhoneStore - Order Confirmation #{orderId}";
            var htmlBody = $@"
            <html>
                <body style='font-family: Arial, sans-serif; line-height: 1.6; color: #333;'>
                    <div style='max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 8px;'>
                        <h2 style='color: #0066cc; text-align: center;'>Order Confirmation</h2>
                        <p>Hello <strong>{recipientName}</strong>,</p>
                        <p>Thank you for your order. We have received it and are preparing to ship it.</p>
                        <p><strong>Order ID:</strong> {orderId}</p>
                        <hr style='border: none; border-top: 1px solid #ddd; margin: 30px 0;'>
                        <p style='font-size: 12px; color: #666; text-align: center;'>© 2024 PhoneStore. All rights reserved.</p>
                    </div>
                </body>
            </html>";

            await SendEmailViaResendAsync(recipientEmail, subject, htmlBody);
            _logger.LogInformation("Order confirmation email sent to {RecipientEmail}", recipientEmail);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send order confirmation email to {RecipientEmail}", recipientEmail);
        }
    }

    private async Task SendEmailViaResendAsync(string recipientEmail, string subject, string htmlBody)
    {
        _logger.LogInformation("Sending email to {RecipientEmail} via Resend API...", recipientEmail);

        var client = _httpClientFactory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _emailSettings.ResendApiKey);
        client.Timeout = TimeSpan.FromSeconds(15);

        var senderAddress = !string.IsNullOrWhiteSpace(_emailSettings.SenderEmail) 
            ? $"{_emailSettings.SenderName} <{_emailSettings.SenderEmail}>" 
            : $"PhoneStore <onboarding@resend.dev>";

        var payload = new
        {
            from = senderAddress,
            to = new[] { recipientEmail },
            subject = subject,
            html = htmlBody
        };

        var jsonContent = new StringContent(
            JsonSerializer.Serialize(payload),
            Encoding.UTF8,
            "application/json"
        );

        try
        {
            var response = await client.PostAsync(ResendApiUrl, jsonContent);
            var responseBody = await response.Content.ReadAsStringAsync();

            if (response.IsSuccessStatusCode)
            {
                _logger.LogInformation("Email successfully sent to {RecipientEmail}. Response: {Response}", 
                    recipientEmail, responseBody);
            }
            else
            {
                _logger.LogError("Resend API error for {RecipientEmail}. Status: {StatusCode}, Response: {Response}", 
                    recipientEmail, response.StatusCode, responseBody);
                throw new Exception($"Failed to send email. Resend API returned {response.StatusCode}: {responseBody}");
            }
        }
        catch (TaskCanceledException)
        {
            _logger.LogError("Email sending to {RecipientEmail} via Resend API timed out", recipientEmail);
            throw new Exception("Email sending timed out. Please try again.");
        }
        catch (HttpRequestException httpEx)
        {
            _logger.LogError(httpEx, "HTTP error sending email to {RecipientEmail} via Resend API", recipientEmail);
            throw new Exception($"Failed to send email: {httpEx.Message}");
        }
    }
}
