using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.Units;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Units.Queries.CheckAvailability;

public class CheckAvailabilityQueryHandler : IRequestHandler<CheckAvailabilityQuery, ResultDto<CheckAvailabilityResponse>>
{
    private readonly IDailyUnitScheduleRepository _scheduleRepository;
    private readonly IUnitRepository _unitRepository;
    private readonly ICurrentUserService _currentUserService;
    private readonly ILogger<CheckAvailabilityQueryHandler> _logger;

    public CheckAvailabilityQueryHandler(
        IDailyUnitScheduleRepository scheduleRepository,
        IUnitRepository unitRepository,
        ILogger<CheckAvailabilityQueryHandler> logger,
        ICurrentUserService currentUserService)
    {
        _scheduleRepository = scheduleRepository;
        _unitRepository = unitRepository;
        _logger = logger;
        _currentUserService = currentUserService;
    }

    public async Task<ResultDto<CheckAvailabilityResponse>> Handle(CheckAvailabilityQuery request, CancellationToken cancellationToken)
    {
        try
        {
            var response = new CheckAvailabilityResponse
            {
                Messages = new List<string>(),
                BlockedPeriods = new List<BlockedPeriodDto>(),
                AvailablePeriods = new List<AvailablePeriodDto>()
            };

            // Normalize incoming dates from user's local time to UTC
            var checkInUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.CheckIn);
            var checkOutUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.CheckOut);

            // التحقق من صحة التواريخ
            if (checkInUtc >= checkOutUtc)
            {
                response.IsAvailable = false;
                response.Status = "Invalid";
                response.Messages.Add("تاريخ المغادرة يجب أن يكون بعد تاريخ الوصول");
                return ResultDto<CheckAvailabilityResponse>.Ok(response);
            }

            // التحقق من أن التاريخ ليس في الماضي
            var userNowLocal = await _currentUserService.ConvertFromUtcToUserLocalAsync(DateTime.UtcNow);
            if ((await _currentUserService.ConvertFromUtcToUserLocalAsync(checkInUtc)).Date < userNowLocal.Date)
            {
                response.IsAvailable = false;
                response.Status = "PastDate";
                response.Messages.Add("لا يمكن الحجز في تاريخ سابق");
                return ResultDto<CheckAvailabilityResponse>.Ok(response);
            }

            // جلب معلومات الوحدة
            var unit = await _unitRepository.GetByIdWithIncludesAsync(request.UnitId, u => u.UnitType);            
            if (unit == null)
            {
                response.IsAvailable = false;
                response.Status = "UnitNotFound";
                response.Messages.Add("الوحدة غير موجودة");
                return ResultDto<CheckAvailabilityResponse>.Ok(response);
            }

            // التحقق من حالة الوحدة
            if (!unit.IsActive)
            {
                response.IsAvailable = false;
                response.Status = "UnitNotAvailable";
                response.Messages.Add("الوحدة غير متاحة حالياً");
                return ResultDto<CheckAvailabilityResponse>.Ok(response);
            }

            // التحقق من السعة
            if (request.Adults.HasValue && unit.AdultsCapacity.HasValue && request.Adults.Value > unit.AdultsCapacity.Value)
            {
                response.IsAvailable = false;
                response.Status = "CapacityExceeded";
                response.Messages.Add($"عدد البالغين يتجاوز السعة القصوى ({unit.AdultsCapacity} بالغ)");
                return ResultDto<CheckAvailabilityResponse>.Ok(response);
            }

            if (request.Children.HasValue && unit.ChildrenCapacity.HasValue && request.Children.Value > unit.ChildrenCapacity.Value)
            {
                response.IsAvailable = false;
                response.Status = "CapacityExceeded";
                response.Messages.Add($"عدد الأطفال يتجاوز السعة القصوى ({unit.ChildrenCapacity} طفل)");
                return ResultDto<CheckAvailabilityResponse>.Ok(response);
            }

            // التحقق من نوع الوحدة (أيام متعددة أم لا)
            if (unit.UnitType != null && !unit.UnitType.IsMultiDays)
            {
                if ((request.CheckOut - request.CheckIn).Days > 1)
                {
                    response.IsAvailable = false;
                    response.Status = "SingleDayOnly";
                    response.Messages.Add("هذا النوع من الوحدات لا يدعم الحجز لأكثر من يوم واحد");
                    return ResultDto<CheckAvailabilityResponse>.Ok(response);
                }
            }

            // جلب الجداول اليومية في الفترة المطلوبة
            var schedules = await _scheduleRepository.GetByUnitAndDateRangeAsync(
                request.UnitId,
                checkInUtc,
                checkOutUtc);

            // التحقق من وجود أيام محجوزة أو محظورة
            var blockedSchedules = schedules
                .Where(s => s.Status != "Available" && s.Status != "Free")
                .ToList();

            if (blockedSchedules.Any())
            {
                response.IsAvailable = false;
                response.Status = "HasBlockedPeriods";
                response.BlockedPeriods = blockedSchedules.Select(s => new BlockedPeriodDto
                {
                    StartDate = s.Date,
                    EndDate = s.Date.AddDays(1),
                    Status = s.Status,
                    Reason = s.Reason,
                    Notes = s.Notes
                }).ToList();

                // إيجاد الفترات المتاحة البديلة
                await FindAlternativeAvailablePeriods(response, request.UnitId, checkInUtc, checkOutUtc);
                
                response.Messages.Add("توجد فترات غير متاحة في التواريخ المحددة");
            }
            else
            {
                response.IsAvailable = true;
                response.Status = YemenBooking.Core.Enums.AvailabilityStatus.Available;
                response.Messages.Add("الوحدة متاحة للحجز في التواريخ المحددة");
            }

            // إضافة تفاصيل الوحدة
            response.Details = new AvailabilityDetailsDto
            {
                UnitId = unit.Id,
                UnitName = unit.Name,
                UnitType = unit.UnitType?.Name,
                MaxAdults = unit.AdultsCapacity ?? 0,
                MaxChildren = unit.ChildrenCapacity ?? 0,
                TotalNights = (checkOutUtc - checkInUtc).Days,
                IsMultiDays = unit.UnitType?.IsMultiDays ?? true,
                IsRequiredToDetermineTheHour = unit.UnitType?.IsRequiredToDetermineTheHour ?? false
            };

            // حساب التسعير إذا طُلب ذلك
            if (request.IncludePricing && response.IsAvailable)
            {
                // الحصول على الجداول اليومية مع الأسعار
                var pricingSchedules = await _scheduleRepository.GetPricingForPeriodAsync(
                    request.UnitId,
                    checkInUtc,
                    checkOutUtc);

                var totalPrice = pricingSchedules.Sum(s => s.PriceAmount ?? 0);
                var currency = pricingSchedules.FirstOrDefault()?.Currency ?? "YER";

                response.PricingSummary = new PricingSummaryDto
                {
                    TotalPrice = totalPrice,
                    AverageNightlyPrice = totalPrice / response.Details.TotalNights,
                    Currency = currency,
                    DailyPrices = pricingSchedules.Select(s => new DailyPriceDto
                    {
                        Date = s.Date,
                        Price = s.PriceAmount ?? 0,
                        PriceType = s.PriceType ?? "Base"
                    }).ToList()
                };
            }

            // Convert all outgoing DateTimes to user's local time
            foreach (var bp in response.BlockedPeriods)
            {
                bp.StartDate = await _currentUserService.ConvertFromUtcToUserLocalAsync(bp.StartDate);
                bp.EndDate = await _currentUserService.ConvertFromUtcToUserLocalAsync(bp.EndDate);
            }
            foreach (var ap in response.AvailablePeriods)
            {
                ap.StartDate = await _currentUserService.ConvertFromUtcToUserLocalAsync(ap.StartDate);
                ap.EndDate = await _currentUserService.ConvertFromUtcToUserLocalAsync(ap.EndDate);
            }
            foreach (var d in response.PricingSummary?.DailyPrices ?? new List<DailyPriceDto>())
            {
                d.Date = await _currentUserService.ConvertFromUtcToUserLocalAsync(d.Date);
            }

            return ResultDto<CheckAvailabilityResponse>.Ok(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"خطأ في التحقق من إتاحة الوحدة {request.UnitId}");
            return ResultDto<CheckAvailabilityResponse>.Failure($"حدث خطأ في التحقق من الإتاحة: {ex.Message}");
        }
    }

    private async Task FindAlternativeAvailablePeriods(
        CheckAvailabilityResponse response, 
        Guid unitId, 
        DateTime preferredCheckIn, 
        DateTime preferredCheckOut)
    {
        var duration = (preferredCheckOut - preferredCheckIn).Days;
        
        // البحث عن فترات متاحة قبل وبعد التواريخ المطلوبة
        var searchStart = preferredCheckIn.AddDays(-30);
        var searchEnd = preferredCheckOut.AddDays(30);
        
        var allSchedules = await _scheduleRepository.GetByUnitAndDateRangeAsync(
            unitId,
            searchStart,
            searchEnd);

        // إيجاد فترات متاحة بنفس المدة
        var currentStart = searchStart;
        while (currentStart < searchEnd)
        {
            var currentEnd = currentStart.AddDays(duration);
            var isAvailable = await _scheduleRepository.IsUnitAvailableAsync(
                unitId,
                currentStart,
                currentEnd);

            if (isAvailable && currentStart != preferredCheckIn)
            {
                response.AvailablePeriods.Add(new AvailablePeriodDto
                {
                    StartDate = currentStart,
                    EndDate = currentEnd
                });
                
                if (response.AvailablePeriods.Count >= 3) // عرض 3 بدائل كحد أقصى
                    break;
            }
            
            currentStart = currentStart.AddDays(1);
        }
    }
}