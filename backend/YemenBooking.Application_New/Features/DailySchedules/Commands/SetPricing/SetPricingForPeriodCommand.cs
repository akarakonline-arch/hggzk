using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.DailySchedules.Commands.SetPricing;

public class SetPricingForPeriodCommand : IRequest<ResultDto<int>>
{
    public Guid UnitId { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public decimal PriceAmount { get; set; }
    public string Currency { get; set; } = string.Empty;
    public string? PriceType { get; set; }
    public string? PricingTier { get; set; }
    public decimal? PercentageChange { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
    public bool OverwriteExisting { get; set; }
}
