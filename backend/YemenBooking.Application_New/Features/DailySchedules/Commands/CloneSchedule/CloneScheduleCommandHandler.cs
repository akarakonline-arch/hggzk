using MediatR;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.DailySchedules.Commands.CloneSchedule;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.SearchAndFilters.Services;

namespace YemenBooking.Application.Features.DailySchedules.Commands.CloneSchedule;

public class CloneScheduleCommandHandler : IRequestHandler<CloneScheduleCommand, ResultDto<int>>
{
    private readonly IDailyUnitScheduleService _scheduleService;
    private readonly IUnitRepository _unitRepository;
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitIndexingService _indexingService;
    private readonly ILogger<CloneScheduleCommandHandler> _logger;

    public CloneScheduleCommandHandler(
        IDailyUnitScheduleService scheduleService,
        IUnitRepository unitRepository,
        ICurrentUserService currentUserService,
        IUnitIndexingService indexingService,
        ILogger<CloneScheduleCommandHandler> logger)
    {
        _scheduleService = scheduleService;
        _unitRepository = unitRepository;
        _currentUserService = currentUserService;
        _indexingService = indexingService;
        _logger = logger;
    }

    public async Task<ResultDto<int>> Handle(CloneScheduleCommand request, CancellationToken cancellationToken)
    {
        try
        {
            var sourceStart = request.SourceStartDate.Date;
            var sourceEnd = request.SourceEndDate.Date;

            if (sourceEnd < sourceStart)
            {
                return ResultDto<int>.Failure("تاريخ نهاية المصدر يجب أن لا يكون قبل تاريخ البداية");
            }

            var unit = await _unitRepository.GetByIdAsync(request.UnitId, cancellationToken);
            if (unit == null)
            {
                return ResultDto<int>.Failure("الوحدة غير موجودة");
            }

            var daysCount = (sourceEnd - sourceStart).Days + 1;
            var targetStart = request.TargetStartDate.Date;
            var targetEnd = targetStart.AddDays(daysCount - 1);

            var targetSchedules = await _scheduleService.GetScheduleForPeriodAsync(
                request.UnitId,
                targetStart,
                targetEnd,
                includeUnit: false,
                includeBooking: true);

            var forbiddenTargetDates = targetSchedules
                .Where(s => s.Status != "Available")
                .Select(s => s.Date.Date)
                .Distinct()
                .ToList();

            if (forbiddenTargetDates.Any())
            {
                var count = forbiddenTargetDates.Count;
                var message = $"لا يمكن نسخ الجدول إلى هذه الفترة لأن هناك {count} يوم/أيام غير متاحة (محجوزة أو محجوبة أو صيانة أو استخدام المالك) ضمن النطاق الهدف. يرجى تعديل الفترة أو تعديل حالة تلك الأيام أولاً.";
                return ResultDto<int>.Failure(message);
            }

            var sourceSchedules = await _scheduleService.GetScheduleForPeriodAsync(
                request.UnitId,
                sourceStart,
                sourceEnd,
                includeUnit: false,
                includeBooking: true);

            var sourceByDate = sourceSchedules.ToDictionary(s => s.Date.Date, s => s);
            var targetByDate = targetSchedules.ToDictionary(s => s.Date.Date, s => s);

            var currentUserId = _currentUserService.UserId.ToString();
            var recordsAffected = 0;

            for (var i = 0; i < daysCount; i++)
            {
                var sourceDate = sourceStart.AddDays(i);
                var targetDate = targetStart.AddDays(i);

                if (!sourceByDate.TryGetValue(sourceDate, out var sourceSchedule))
                {
                    continue;
                }

                var cloned = new DailyUnitSchedule
                {
                    Status = sourceSchedule.Status,
                    Reason = sourceSchedule.Reason,
                    Notes = sourceSchedule.Notes,
                    BookingId = sourceSchedule.BookingId,
                    PriceAmount = sourceSchedule.PriceAmount,
                    Currency = sourceSchedule.Currency,
                    PriceType = sourceSchedule.PriceType,
                    PricingTier = sourceSchedule.PricingTier,
                    PercentageChange = sourceSchedule.PercentageChange,
                    MinPrice = sourceSchedule.MinPrice,
                    MaxPrice = sourceSchedule.MaxPrice,
                    StartTime = sourceSchedule.StartTime,
                    EndTime = sourceSchedule.EndTime,
                    CreatedBy = currentUserId,
                    ModifiedBy = currentUserId,
                };

                if (sourceSchedule.Status == "Booked" || sourceSchedule.BookingId != null)
                {
                    cloned.Status = "Available";
                    cloned.BookingId = null;
                    cloned.Reason = null;
                }

                if (targetByDate.TryGetValue(targetDate, out var existingTarget))
                {
                    if (!request.Overwrite)
                    {
                        continue;
                    }
                }

                await _scheduleService.UpsertDailyScheduleAsync(
                    request.UnitId,
                    targetDate,
                    cloned);

                recordsAffected++;
            }

            var indexingSuccess = false;
            var indexingAttempts = 0;
            const int maxIndexingAttempts = 3;

            while (!indexingSuccess && indexingAttempts < maxIndexingAttempts)
            {
                try
                {
                    indexingAttempts++;
                    await _indexingService.OnDailyScheduleChangedAsync(request.UnitId, cancellationToken);
                    indexingSuccess = true;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "فشل تحديث فهرس الجدول اليومي للوحدة {UnitId} (محاولة {Attempt}/{Max})", request.UnitId, indexingAttempts, maxIndexingAttempts);

                    if (indexingAttempts < maxIndexingAttempts)
                    {
                        await Task.Delay(TimeSpan.FromSeconds(Math.Pow(2, indexingAttempts - 1)), cancellationToken);
                    }
                }
            }

            return ResultDto<int>.Ok(recordsAffected);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "حدث خطأ أثناء نسخ الجدول للوحدة {UnitId}", request.UnitId);
            return ResultDto<int>.Failure($"حدث خطأ: {ex.Message}");
        }
    }
}
