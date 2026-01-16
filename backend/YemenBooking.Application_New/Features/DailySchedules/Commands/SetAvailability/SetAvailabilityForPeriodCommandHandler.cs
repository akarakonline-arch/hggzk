using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Interfaces.Repositories;
using System.Linq;

namespace YemenBooking.Application.Features.DailySchedules.Commands.SetAvailability;

public class SetAvailabilityForPeriodCommandHandler : IRequestHandler<SetAvailabilityForPeriodCommand, ResultDto<int>>
{
    private readonly IDailyUnitScheduleService _scheduleService;
    private readonly IUnitRepository _unitRepository;
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitIndexingService _indexingService;
    private readonly ILogger<SetAvailabilityForPeriodCommandHandler> _logger;

    public SetAvailabilityForPeriodCommandHandler(
        IDailyUnitScheduleService scheduleService,
        IUnitRepository unitRepository,
        ICurrentUserService currentUserService,
        IUnitIndexingService indexingService,
        ILogger<SetAvailabilityForPeriodCommandHandler> logger)
    {
        _scheduleService = scheduleService;
        _unitRepository = unitRepository;
        _currentUserService = currentUserService;
        _indexingService = indexingService;
        _logger = logger;
    }

    public async Task<ResultDto<int>> Handle(SetAvailabilityForPeriodCommand request, CancellationToken cancellationToken)
    {
        try
        {
            var localStart = new DateTime(request.StartDate.Year, request.StartDate.Month, request.StartDate.Day, 12, 0, 0);
            var localEnd = new DateTime(request.EndDate.Year, request.EndDate.Month, request.EndDate.Day, 23, 59, 59, 999);
            var startUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(localStart);
            var endUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(localEnd);

            if (endUtc < startUtc)
                return ResultDto<int>.Failure("تاريخ النهاية يجب أن لا يكون قبل تاريخ البداية");

            var unit = await _unitRepository.GetByIdAsync(request.UnitId, cancellationToken);
            if (unit == null)
                return ResultDto<int>.Failure("الوحدة غير موجودة");

            // منع تعديل الأيام المحجوزة ضمن الفترة المحددة
            var existingSchedules = await _scheduleService.GetScheduleForPeriodAsync(
                request.UnitId,
                localStart,
                localEnd,
                includeUnit: false,
                includeBooking: true);

            var bookedDates = existingSchedules
                .Where(s => s.Status == "Booked" || s.BookingId != null)
                .Select(s => s.Date.Date)
                .Distinct()
                .ToList();

            if (bookedDates.Any())
            {
                var bookedCount = bookedDates.Count;
                var message = $"لا يمكن تحديث الإتاحة لهذه الفترة لأن هناك {bookedCount} يوم/أيام محجوزة ضمن النطاق. يرجى تعديل الفترة أو إلغاء الحجوزات أولاً.";
                return ResultDto<int>.Failure(message);
            }

            var currentUser = _currentUserService.UserId;

            var recordsAffected = await _scheduleService.SetAvailabilityForPeriodAsync(
                request.UnitId,
                startUtc,
                endUtc,
                request.Status,
                request.Reason,
                request.Notes,
                request.BookingId,
                request.OverwriteExisting,
                currentUser.ToString());

            var indexingSuccess = false;
            var indexingAttempts = 0;
            const int maxIndexingAttempts = 3;

            while (!indexingSuccess && indexingAttempts < maxIndexingAttempts)
            {
                try
                {
                    indexingAttempts++;
                    await _indexingService.OnAvailabilityChangedAsync(request.UnitId, cancellationToken);
                    indexingSuccess = true;
                    _logger.LogInformation("✅ تم تحديث فهرس الإتاحة بنجاح للوحدة {UnitId} (محاولة {Attempt}/{Max})",
                        request.UnitId, indexingAttempts, maxIndexingAttempts);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "⚠️ فشلت محاولة {Attempt}/{Max} لتحديث فهرس الإتاحة للوحدة {UnitId}",
                        indexingAttempts, maxIndexingAttempts, request.UnitId);

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
            _logger.LogError(ex, "حدث خطأ أثناء تعيين الإتاحة للوحدة {UnitId}", request.UnitId);
            return ResultDto<int>.Failure($"حدث خطأ: {ex.Message}");
        }
    }
}
