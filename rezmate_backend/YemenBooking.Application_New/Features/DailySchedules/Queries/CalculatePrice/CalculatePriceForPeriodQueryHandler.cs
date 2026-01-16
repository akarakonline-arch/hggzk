using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Application.Features.DailySchedules.Queries.CalculatePrice;

public class CalculatePriceForPeriodQueryHandler : IRequestHandler<CalculatePriceForPeriodQuery, ResultDto<PricingCalculationResultDto>>
{
    private readonly IDailyUnitScheduleService _scheduleService;
    private readonly ICurrentUserService _currentUserService;
    private readonly ILogger<CalculatePriceForPeriodQueryHandler> _logger;

    public CalculatePriceForPeriodQueryHandler(
        IDailyUnitScheduleService scheduleService,
        ICurrentUserService currentUserService,
        ILogger<CalculatePriceForPeriodQueryHandler> logger)
    {
        _scheduleService = scheduleService;
        _currentUserService = currentUserService;
        _logger = logger;
    }

    public async Task<ResultDto<PricingCalculationResultDto>> Handle(CalculatePriceForPeriodQuery request, CancellationToken cancellationToken)
    {
        try
        {
            var localStart = new DateTime(request.StartDate.Year, request.StartDate.Month, request.StartDate.Day, 0, 0, 0);
            var localEnd = new DateTime(request.EndDate.Year, request.EndDate.Month, request.EndDate.Day, 23, 59, 59, 999);
            var startUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(localStart);
            var endUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(localEnd);

            var result = await _scheduleService.CalculatePriceForPeriodAsync(
                request.UnitId,
                startUtc,
                endUtc,
                request.BasePriceAmount,
                request.BaseCurrency);

            var dto = new PricingCalculationResultDto
            {
                TotalPrice = result.TotalPrice,
                Currency = result.Currency,
                TotalDays = result.TotalDays,
                DaysWithCustomPricing = result.DaysWithCustomPricing,
                DaysWithBasePrice = result.DaysWithBasePrice,
                AveragePerDay = result.AveragePerDay,
                DailyPrices = result.DailyPrices.Select(dp => new DailyPriceInfoDto
                {
                    Date = dp.Date,
                    Price = dp.Price,
                    PriceType = dp.PriceType,
                    IsCustomPrice = dp.IsCustomPrice
                }).ToList()
            };

            return ResultDto<PricingCalculationResultDto>.Ok(dto);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "حدث خطأ أثناء حساب السعر للوحدة {UnitId}", request.UnitId);
            return ResultDto<PricingCalculationResultDto>.Failure($"حدث خطأ: {ex.Message}");
        }
    }
}
