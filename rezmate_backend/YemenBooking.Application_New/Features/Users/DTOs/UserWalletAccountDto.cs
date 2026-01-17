using System;
using YemenBooking.Core.Enums;

namespace YemenBooking.Application.Features.Users.DTOs;

public class UserWalletAccountDto
{
    public Guid Id { get; set; }

    public PaymentMethodEnum WalletType { get; set; }

    public string AccountNumber { get; set; } = string.Empty;

    public string? AccountName { get; set; }

    public bool IsDefault { get; set; }
}

public class UserWalletAccountRequestDto
{
    public PaymentMethodEnum WalletType { get; set; }

    public string AccountNumber { get; set; } = string.Empty;

    public string? AccountName { get; set; }

    public bool IsDefault { get; set; }
}
