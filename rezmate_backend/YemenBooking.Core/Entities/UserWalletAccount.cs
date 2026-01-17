using System;
using System.ComponentModel.DataAnnotations;
using YemenBooking.Core.Enums;

namespace YemenBooking.Core.Entities;

[Display(Name = "حساب محفظة المستخدم")]
public class UserWalletAccount : BaseEntity<Guid>
{
    public Guid UserId { get; set; }

    public PaymentMethodEnum WalletType { get; set; }

    public string AccountNumber { get; set; } = string.Empty;

    public string? AccountName { get; set; }

    public bool IsDefault { get; set; } = false;

    public virtual User User { get; set; } = null!;
}
