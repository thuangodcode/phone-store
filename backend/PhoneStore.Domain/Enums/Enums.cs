namespace PhoneStore.Domain.Enums;

public static class OrderStatus
{
    public const string Pending = "Pending";
    public const string Confirmed = "Confirmed";
    public const string Shipping = "Shipping";
    public const string Delivered = "Delivered";
    public const string Cancelled = "Cancelled";

    public static readonly string[] All = { Pending, Confirmed, Shipping, Delivered, Cancelled };

    public static bool IsValid(string status) => All.Contains(status);
}

public static class UserRole
{
    public const string Admin = "Admin";
    public const string Staff = "Staff";
    public const string Customer = "Customer";

    public static readonly string[] All = { Admin, Staff, Customer };
}

public static class DiscountType
{
    public const string Percentage = "Percentage";
    public const string Fixed = "Fixed";
}
