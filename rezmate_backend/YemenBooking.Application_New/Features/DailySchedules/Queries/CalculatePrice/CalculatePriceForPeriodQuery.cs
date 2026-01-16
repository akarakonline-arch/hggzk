using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.DailySchedules.Queries.CalculatePrice;

public class CalculatePriceForPeriodQuery : IRequest<ResultDto<PricingCalculationResultDto>>
{
    public Guid UnitId { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public decimal BasePriceAmount { get; set; }
    public string BaseCurrency { get; set; } = string.Empty;
}

public class PricingCalculationResultDto
{
    public decimal TotalPrice { get; set; }
    public string Currency { get; set; } = string.Empty;
    public int TotalDays { get; set; }
    public int DaysWithCustomPricing { get; set; }
    public int DaysWithBasePrice { get; set; }
    public decimal AveragePerDay { get; set; }
    public List<DailyPriceInfoDto> DailyPrices { get; set; } = new();
}

public class DailyPriceInfoDto
{
    public DateTime Date { get; set; }
    public decimal Price { get; set; }
    public string? PriceType { get; set; }
    public bool IsCustomPrice { get; set; }
}
