namespace PhoneStore.Application.DTOs.Order;

public class OrderAuditLogDto
{
    public string Id { get; set; } = null!;
    public string OrderId { get; set; } = null!;
    public string StaffId { get; set; } = null!;
    public string StaffName { get; set; } = null!;
    public string Action { get; set; } = null!;
    public string Details { get; set; } = null!;
    public DateTime Timestamp { get; set; }
    public string? OldValue { get; set; }
    public string? NewValue { get; set; }
}
