using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using PhoneStore.Application.Interfaces;
using PhoneStore.Infrastructure.Data;

namespace PhoneStore.Infrastructure.Services;

public class EmailService : IEmailService
{
    private readonly EmailSettings _emailSettings;
    private readonly ILogger<EmailService> _logger;
    private const int EmailTimeoutSeconds = 15;

    public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
    {
        _emailSettings = new EmailSettings();
        configuration.GetSection("EmailSettings").Bind(_emailSettings);
        _logger = logger;
    }

    public async Task SendPasswordResetEmailAsync(string recipientEmail, string recipientName, string resetToken, string resetLink)
    {
        try
        {
            // Validate settings
            if (string.IsNullOrEmpty(_emailSettings.SenderEmail))
            {
                _logger.LogWarning("Email service not configured. Skipping password reset email.");
                return;
            }

            var subject = "PhoneStore - Password Reset Request";
            var htmlBody = $@"
            <html>
                <body style='font-family: Arial, sans-serif; line-height: 1.6; color: #333;'>
                    <div style='max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 8px;'>
                        <h2 style='color: #0066cc; text-align: center;'>Password Reset Request</h2>
                        
                        <p>Hello <strong>{recipientName}</strong>,</p>
                        
                        <p>We received a request to reset your password for your PhoneStore account. Click the button below to reset your password:</p>
                        
                        <div style='text-align: center; margin: 30px 0;'>
                            <a href='{resetLink}' style='display: inline-block; background-color: #0066cc; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; font-weight: bold;'>
                                Reset Password
                            </a>
                        </div>
                        
                        <p>Or copy and paste this link in your browser:</p>
                        <p style='background-color: #f5f5f5; padding: 10px; border-radius: 5px; word-break: break-all;'>{resetLink}</p>
                        
                        <p><strong>Security Notice:</strong></p>
                        <ul>
                            <li>This link will expire in 24 hours</li>
                            <li>If you didn't request this, please ignore this email</li>
                            <li>Never share this link with anyone</li>
                        </ul>
                        
                        <hr style='border: none; border-top: 1px solid #ddd; margin: 30px 0;'>
                        
                        <p style='font-size: 12px; color: #666; text-align: center;'>
                            © 2024 PhoneStore. All rights reserved.<br>
                            If you have any questions, contact us at support@phonestore.com
                        </p>
                    </div>
                </body>
            </html>";

            await SendEmailAsyncInternal(recipientEmail, recipientName, subject, htmlBody);
            _logger.LogInformation($"Password reset email sent to {recipientEmail}");
        }
        catch (Exception ex)
        {
            _logger.LogError($"Failed to send password reset email to {recipientEmail}: {ex.Message}");
            // Don't throw - we want the forgot password flow to succeed even if email fails
        }
    }

    public async Task SendWelcomeEmailAsync(string recipientEmail, string recipientName)
    {
        try
        {
            // Validate settings
            if (string.IsNullOrEmpty(_emailSettings.SenderEmail))
            {
                _logger.LogWarning("Email service not configured. Skipping welcome email.");
                return;
            }

            var subject = "Welcome to PhoneStore!";
            var htmlBody = $@"
            <html>
                <body style='font-family: Arial, sans-serif; line-height: 1.6; color: #333;'>
                    <div style='max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 8px;'>
                        <h2 style='color: #0066cc; text-align: center;'>Welcome to PhoneStore!</h2>
                        
                        <p>Hello <strong>{recipientName}</strong>,</p>
                        
                        <p>Thank you for registering with PhoneStore! We're excited to have you as part of our community.</p>
                        
                        <p>With your account, you can:</p>
                        <ul>
                            <li>Browse our latest phone collection</li>
                            <li>Save your favorite items</li>
                            <li>Track your orders</li>
                            <li>Get exclusive deals and offers</li>
                        </ul>
                        
                        <div style='text-align: center; margin: 30px 0;'>
                            <a href='https://phone-store.vercel.app' style='display: inline-block; background-color: #0066cc; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; font-weight: bold;'>
                                Start Shopping
                            </a>
                        </div>
                        
                        <hr style='border: none; border-top: 1px solid #ddd; margin: 30px 0;'>
                        
                        <p style='font-size: 12px; color: #666; text-align: center;'>
                            © 2024 PhoneStore. All rights reserved.
                        </p>
                    </div>
                </body>
            </html>";

            await SendEmailAsyncInternal(recipientEmail, recipientName, subject, htmlBody);
            _logger.LogInformation($"Welcome email sent to {recipientEmail}");
        }
        catch (Exception ex)
        {
            _logger.LogError($"Failed to send welcome email to {recipientEmail}: {ex.Message}");
            // Don't throw - we want the registration to succeed even if email fails
        }
    }

    public async Task SendOrderConfirmationEmailAsync(string recipientEmail, string recipientName, string orderId)
    {
        try
        {
            // Validate settings
            if (string.IsNullOrEmpty(_emailSettings.SenderEmail))
            {
                _logger.LogWarning("Email service not configured. Skipping order confirmation email.");
                return;
            }

            var subject = $"PhoneStore - Order Confirmation #{orderId}";
            var htmlBody = $@"
            <html>
                <body style='font-family: Arial, sans-serif; line-height: 1.6; color: #333;'>
                    <div style='max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 8px;'>
                        <h2 style='color: #0066cc; text-align: center;'>Order Confirmation</h2>
                        
                        <p>Hello <strong>{recipientName}</strong>,</p>
                        
                        <p>Thank you for your order! We've received it and are preparing to ship your items.</p>
                        
                        <p><strong>Order ID:</strong> {orderId}</p>
                        
                        <p>You can track your order status anytime by logging into your PhoneStore account.</p>
                        
                        <div style='text-align: center; margin: 30px 0;'>
                            <a href='https://phone-store.vercel.app/orders' style='display: inline-block; background-color: #0066cc; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; font-weight: bold;'>
                                Track Order
                            </a>
                        </div>
                        
                        <p>If you have any questions about your order, please don't hesitate to contact us.</p>
                        
                        <hr style='border: none; border-top: 1px solid #ddd; margin: 30px 0;'>
                        
                        <p style='font-size: 12px; color: #666; text-align: center;'>
                            © 2024 PhoneStore. All rights reserved.<br>
                            support@phonestore.com
                        </p>
                    </div>
                </body>
            </html>";

            await SendEmailAsyncInternal(recipientEmail, recipientName, subject, htmlBody);
            _logger.LogInformation($"Order confirmation email sent to {recipientEmail}");
        }
        catch (Exception ex)
        {
            _logger.LogError($"Failed to send order confirmation email to {recipientEmail}: {ex.Message}");
            // Don't throw - we want the order to succeed even if email fails
        }
    }

    private async Task SendEmailAsyncInternal(string recipientEmail, string recipientName, string subject, string htmlBody)
    {
        // Use Task.Run to prevent blocking the thread
        await Task.Run(async () =>
        {
            using (var smtpClient = new SmtpClient(_emailSettings.SmtpServer, _emailSettings.SmtpPort))
            {
                smtpClient.Credentials = new NetworkCredential(_emailSettings.SenderEmail, _emailSettings.SenderPassword);
                smtpClient.EnableSsl = _emailSettings.EnableSsl;
                smtpClient.Timeout = EmailTimeoutSeconds * 1000; // Set timeout in milliseconds

                using (var mailMessage = new MailMessage())
                {
                    mailMessage.From = new MailAddress(_emailSettings.SenderEmail, _emailSettings.SenderName);
                    mailMessage.To.Add(new MailAddress(recipientEmail, recipientName));
                    mailMessage.Subject = subject;
                    mailMessage.Body = htmlBody;
                    mailMessage.IsBodyHtml = true;

                    try
                    {
                        await smtpClient.SendMailAsync(mailMessage);
                    }
                    catch (SmtpException smtpEx)
                    {
                        _logger.LogError($"SMTP Error: {smtpEx.Message} (Status: {smtpEx.StatusCode})");
                        throw;
                    }
                }
            }
        });
    }
}
                        </p>
                    </div>
                </body>
            </html>";

            await SendEmailAsync(recipientEmail, recipientName, subject, htmlBody);
        }
        catch (Exception ex)
        {
            throw new Exception($"Failed to send welcome email: {ex.Message}", ex);
        }
    }

    public async Task SendOrderConfirmationEmailAsync(string recipientEmail, string recipientName, string orderId)
    {
        try
        {
            var subject = $"PhoneStore - Order Confirmation #{orderId}";
            var htmlBody = $@"
            <html>
                <body style='font-family: Arial, sans-serif; line-height: 1.6; color: #333;'>
                    <div style='max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #ddd; border-radius: 8px;'>
                        <h2 style='color: #0066cc; text-align: center;'>Order Confirmation</h2>
                        
                        <p>Hello <strong>{recipientName}</strong>,</p>
                        
                        <p>Thank you for your order! We've received it and are preparing to ship your items.</p>
                        
                        <p><strong>Order ID:</strong> {orderId}</p>
                        
                        <p>You can track your order status anytime by logging into your PhoneStore account.</p>
                        
                        <div style='text-align: center; margin: 30px 0;'>
                            <a href='https://phone-store.vercel.app/orders' style='display: inline-block; background-color: #0066cc; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; font-weight: bold;'>
                                Track Order
                            </a>
                        </div>
                        
                        <p>If you have any questions about your order, please don't hesitate to contact us.</p>
                        
                        <hr style='border: none; border-top: 1px solid #ddd; margin: 30px 0;'>
                        
                        <p style='font-size: 12px; color: #666; text-align: center;'>
                            © 2024 PhoneStore. All rights reserved.<br>
                            support@phonestore.com
                        </p>
                    </div>
                </body>
            </html>";

            await SendEmailAsync(recipientEmail, recipientName, subject, htmlBody);
        }
        catch (Exception ex)
        {
            throw new Exception($"Failed to send order confirmation email: {ex.Message}", ex);
        }
    }

    private async Task SendEmailAsync(string recipientEmail, string recipientName, string subject, string htmlBody)
    {
        using (var smtpClient = new SmtpClient(_emailSettings.SmtpServer, _emailSettings.SmtpPort))
        {
            smtpClient.Credentials = new NetworkCredential(_emailSettings.SenderEmail, _emailSettings.SenderPassword);
            smtpClient.EnableSsl = _emailSettings.EnableSsl;

            var mailMessage = new MailMessage
            {
                From = new MailAddress(_emailSettings.SenderEmail, _emailSettings.SenderName),
                Subject = subject,
                Body = htmlBody,
                IsBodyHtml = true
            };

            mailMessage.To.Add(new MailAddress(recipientEmail, recipientName));

            await smtpClient.SendMailAsync(mailMessage);
        }
    }
}
