using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using MimeKit;
using PhoneStore.Application.Interfaces;
using PhoneStore.Infrastructure.Data;

namespace PhoneStore.Infrastructure.Services;

public class EmailService : IEmailService
{
    private readonly EmailSettings _emailSettings;
    private readonly ILogger<EmailService> _logger;
    private const int EmailTimeoutSeconds = 20;

    public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
    {
        _emailSettings = new EmailSettings();
        configuration.GetSection("EmailSettings").Bind(_emailSettings);
        _logger = logger;
    }

    public async Task SendPasswordResetEmailAsync(string recipientEmail, string recipientName, string resetToken, string resetLink)
    {
        if (string.IsNullOrWhiteSpace(_emailSettings.SenderEmail) || string.IsNullOrWhiteSpace(_emailSettings.SenderPassword))
        {
            _logger.LogWarning("Email service is not configured. Cannot send password reset email.");
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

        await SendEmailAsyncInternal(recipientEmail, recipientName, subject, htmlBody);
        _logger.LogInformation("Password reset email sent to {RecipientEmail}", recipientEmail);
    }

    public async Task SendWelcomeEmailAsync(string recipientEmail, string recipientName)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(_emailSettings.SenderEmail) || string.IsNullOrWhiteSpace(_emailSettings.SenderPassword))
            {
                _logger.LogWarning("Email service is not configured. Skipping welcome email.");
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

            await SendEmailAsyncInternal(recipientEmail, recipientName, subject, htmlBody);
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
            if (string.IsNullOrWhiteSpace(_emailSettings.SenderEmail) || string.IsNullOrWhiteSpace(_emailSettings.SenderPassword))
            {
                _logger.LogWarning("Email service is not configured. Skipping order confirmation email.");
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

            await SendEmailAsyncInternal(recipientEmail, recipientName, subject, htmlBody);
            _logger.LogInformation("Order confirmation email sent to {RecipientEmail}", recipientEmail);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send order confirmation email to {RecipientEmail}", recipientEmail);
        }
    }

    private async Task SendEmailAsyncInternal(string recipientEmail, string recipientName, string subject, string htmlBody)
    {
        _logger.LogInformation("Attempting to send email to {RecipientEmail} via {SmtpServer}:{SmtpPort}",
            recipientEmail, _emailSettings.SmtpServer, _emailSettings.SmtpPort);

        using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(EmailTimeoutSeconds));

        try
        {
            var message = new MimeMessage();
            message.From.Add(new MailboxAddress(_emailSettings.SenderName, _emailSettings.SenderEmail));
            message.To.Add(new MailboxAddress(recipientName, recipientEmail));
            message.Subject = subject;
            message.Body = new TextPart("html") { Text = htmlBody };

            using var client = new SmtpClient();
            
            _logger.LogInformation("Connecting to SMTP server...");
            await client.ConnectAsync(
                _emailSettings.SmtpServer, 
                _emailSettings.SmtpPort, 
                SecureSocketOptions.StartTls, 
                cts.Token
            );

            _logger.LogInformation("Authenticating with SMTP server...");
            await client.AuthenticateAsync(
                _emailSettings.SenderEmail, 
                _emailSettings.SenderPassword, 
                cts.Token
            );

            _logger.LogInformation("Sending email...");
            await client.SendAsync(message, cts.Token);
            await client.DisconnectAsync(true, cts.Token);

            _logger.LogInformation("Email successfully sent to {RecipientEmail}", recipientEmail);
        }
        catch (OperationCanceledException)
        {
            _logger.LogError("Email sending to {RecipientEmail} timed out after {Timeout}s", 
                recipientEmail, EmailTimeoutSeconds);
            throw new Exception($"Email sending timed out after {EmailTimeoutSeconds} seconds. Please try again.");
        }
        catch (MailKit.Security.AuthenticationException authEx)
        {
            _logger.LogError(authEx, "SMTP authentication failed for {SenderEmail}. App Password may be invalid or expired.", 
                _emailSettings.SenderEmail);
            throw new Exception("Email authentication failed. The App Password may be invalid or expired.");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send email to {RecipientEmail}: {ErrorType} - {ErrorMessage}", 
                recipientEmail, ex.GetType().Name, ex.Message);
            throw new Exception($"Failed to send email: {ex.Message}");
        }
    }
}
