namespace PhoneStore.Infrastructure.Data;

public class EmailSettings
{
    public string SmtpServer { get; set; } = string.Empty;
    public int SmtpPort { get; set; } = 465;
    public string SenderEmail { get; set; } = string.Empty;
    public string SenderPassword { get; set; } = string.Empty;
    public string SenderName { get; set; } = "PhoneStore";
    public bool EnableSsl { get; set; } = true;
}
