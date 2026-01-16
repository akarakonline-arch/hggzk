using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Application.Features.DailySchedules.Queries.CheckAvailability;

public class CheckUnitAvailabilityQueryHandler : IRequestHandler<CheckUnitAvailabilityQuery, ResultDto<AvailabilityCheckResultDto>>
{
    private readonly IDailyUnitScheduleService _scheduleService;
    private readonly ICurrentUserService _currentUserService;
    private readonly ILogger<CheckUnitAvailabilityQueryHandler> _logger;

    public CheckUnitAvailabilityQueryHandler(
        IDailyUnitScheduleService scheduleService,
        ICurrentUserService currentUserService,
        ILogger<CheckUnitAvailabilityQueryHandler> logger)
    {
        _scheduleService = scheduleService;
        _currentUserService = currentUserService;
        _logger = logger;
    }

    public async Task<ResultDto<AvailabilityCheckResultDto>> Handle(CheckUnitAvailabilityQuery request, CancellationToken cancellationToken)
    {
        try
        {
            // تحويل فترة الحجز إلى فترة ليالي فعلية [StartDate, EndDate)
            var localStart = new DateTime(request.StartDate.Year, request.StartDate.Month, request.StartDate.Day, 0, 0, 0);
            var lastNight = request.EndDate.AddDays(-1);
            var localEnd = new DateTime(lastNight.Year, lastNight.Month, lastNight.Day, 23, 59, 59, 999);
            var startUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(localStart);
            var endUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(localEnd);

            // فحص التوفر بناءً على الجداول اليومية
            var availabilityResult = await _scheduleService.CheckAvailabilityAsync(
                request.UnitId,
                startUtc,
                endUtc,
                request.ExcludeBookingId);

            // حساب السعر للفترة نفسها باستخدام خدمة الجدول اليومي
            PricingCalculationResult? pricingResult = null;
            try
            {
                pricingResult = await _scheduleService.CalculatePriceForPeriodAsync(
                    request.UnitId,
                    startUtc,
                    endUtc,
                    0m,
                    "YER");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "حدث خطأ أثناء حساب السعر للوحدة {UnitId} في استعلام التوفر", request.UnitId);
            }

            decimal? totalPrice = null;
            decimal? pricePerNight = null;
            string? currency = null;

            if (pricingResult != null && pricingResult.TotalDays > 0 && pricingResult.TotalPrice > 0)
            {
                totalPrice = pricingResult.TotalPrice;
                currency = pricingResult.Currency;
                pricePerNight = pricingResult.TotalPrice / pricingResult.TotalDays;
            }

            var dto = new AvailabilityCheckResultDto
            {
                IsAvailable = availabilityResult.IsAvailable,
                TotalDays = availabilityResult.TotalDays,
                AvailableDays = availabilityResult.AvailableDays,
                UnavailableDays = availabilityResult.UnavailableDays,
                UnavailableDates = availabilityResult.UnavailableDates,
                Message = availabilityResult.Message,
                TotalPrice = totalPrice,
                PricePerNight = pricePerNight,
                Currency = currency
            };

            return ResultDto<AvailabilityCheckResultDto>.Ok(dto);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "حدث خطأ أثناء فحص توفر الوحدة {UnitId}", request.UnitId);
            return ResultDto<AvailabilityCheckResultDto>.Failure($"حدث خطأ: {ex.Message}");
        }
    }
}
