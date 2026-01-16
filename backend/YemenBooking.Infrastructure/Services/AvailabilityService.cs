using System.Linq;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.Units.Services;
using YemenBooking.Application.Features.Units.DTOs;
using YemenBooking.Application.Features.Units.Commands.BulkOperations;
using YemenBooking.Core.Interfaces.Repositories;
using Microsoft.Extensions.Logging;

namespace YemenBooking.Infrastructure.Services;

public class AvailabilityService : IAvailabilityService
{
    private readonly IDailyUnitScheduleRepository _scheduleRepository;
    private readonly IUnitRepository _unitRepository;
    private readonly ILogger<AvailabilityService> _logger;

    // Constructor with logger (preferred)
    public AvailabilityService(
        IDailyUnitScheduleRepository scheduleRepository,
        IUnitRepository unitRepository,
        ILogger<AvailabilityService> logger)
    {
        _scheduleRepository = scheduleRepository;
        _unitRepository = unitRepository;
        _logger = logger;
    }

    // Constructor without logger (for backward compatibility)
    public AvailabilityService(
        IDailyUnitScheduleRepository scheduleRepository,
        IUnitRepository unitRepository)
    {
        _scheduleRepository = scheduleRepository;
        _unitRepository = unitRepository;
        _logger = null!; // Will be null, so we need to check before logging
    }

    public async Task<bool> CheckAvailabilityAsync(Guid unitId, DateTime checkIn, DateTime checkOut, Guid? excludeBookingId = null)
    {
        _logger?.LogDebug("التحقق من توفر الوحدة {UnitId} من {CheckIn} إلى {CheckOut}، استثناء الحجز: {ExcludeBookingId}", 
            unitId, checkIn, checkOut, excludeBookingId);
        
        // Check if unit exists and is active
        var unit = await _unitRepository.GetByIdAsync(unitId);
        if (unit == null)
        {
            _logger?.LogWarning("الوحدة {UnitId} غير موجودة", unitId);
            return false;
        }

        var schedules = await _scheduleRepository.GetByUnitAndDateRangeAsync(
            unitId,
            checkIn.Date,
            checkOut.Date.AddDays(-1));

        bool isAvailable;
        if (schedules == null || !schedules.Any())
        {
            isAvailable = true;
        }
        else if (excludeBookingId.HasValue)
        {
            // اعتبار أيام الحجز الحالي متاحة، مع الاستمرار في منع التداخل مع حجوزات أو حالات أخرى
            isAvailable = schedules.All(s =>
                s.Status == "Available" ||
                (s.Status == "Booked" && s.BookingId == excludeBookingId));
        }
        else
        {
            isAvailable = schedules.All(s => s.Status == "Available");
        }
        
        _logger?.LogInformation("نتيجة التحقق من توفر الوحدة {UnitId}: {IsAvailable}", unitId, isAvailable);
        
        return isAvailable;
    }

    public async Task BlockForBookingAsync(Guid unitId, Guid bookingId, DateTime checkIn, DateTime checkOut)
    {
        // تم استبدال UnitAvailability بـ DailyUnitSchedule
        // يتم الآن إنشاء سجلات يومية للفترة المطلوبة
        var currentDate = checkIn.Date;
        while (currentDate < checkOut.Date)
        {
            var schedule = await _scheduleRepository.GetByUnitAndDateAsync(unitId, currentDate);
            if (schedule == null)
            {
                schedule = new DailyUnitSchedule
                {
                    Id = Guid.NewGuid(),
                    UnitId = unitId,
                    Date = currentDate,
                    Status = "Booked",
                    BookingId = bookingId,
                    Reason = "Customer Booking",
                    CreatedAt = DateTime.UtcNow
                };
                await _scheduleRepository.AddAsync(schedule);
            }
            else if (schedule.Status == "Available")
            {
                schedule.Status = "Booked";
                schedule.BookingId = bookingId;
                schedule.Reason = "Customer Booking";
                schedule.UpdatedAt = DateTime.UtcNow;
                await _scheduleRepository.UpdateAsync(schedule);
            }
            
            currentDate = currentDate.AddDays(1);
        }
        
        await _scheduleRepository.SaveChangesAsync();
    }

    public async Task ReleaseBookingAsync(Guid bookingId)
    {
        // تحديث جميع السجلات المرتبطة بهذا الحجز
        var schedules = await _scheduleRepository.GetByBookingIdAsync(bookingId);
        
        foreach (var schedule in schedules)
        {
            schedule.Status = "Available";
            schedule.BookingId = null;
            schedule.Reason = null;
            schedule.UpdatedAt = DateTime.UtcNow;
            await _scheduleRepository.UpdateAsync(schedule);
        }
        
        await _scheduleRepository.SaveChangesAsync();
    }

    public async Task<Dictionary<DateTime, string>> GetMonthlyCalendarAsync(Guid unitId, int year, int month)
    {
        var startDate = new DateTime(year, month, 1);
        var endDate = startDate.AddMonths(1).AddDays(-1);
        
        var schedules = await _scheduleRepository.GetByUnitAndDateRangeAsync(unitId, startDate, endDate);
        
        var calendar = new Dictionary<DateTime, string>();
        var currentDate = startDate;
        while (currentDate <= endDate)
        {
            var schedule = schedules?.FirstOrDefault(s => s.Date.Date == currentDate.Date);
            calendar[currentDate] = schedule?.Status ?? "Available";
            currentDate = currentDate.AddDays(1);
        }
        
        return calendar;
    }

    public async Task ApplyBulkAvailabilityAsync(Guid unitId, List<AvailabilityPeriodDto> periods)
    {
        var schedules = new List<DailyUnitSchedule>();

        foreach (var period in periods)
        {
            // حذف السجلات الموجودة في هذا النطاق إذا لزم الأمر
            if (period.OverwriteExisting)
            {
                await _scheduleRepository.DeleteRangeAsync(unitId, period.StartDate, period.EndDate);
            }

            // إنشاء سجلات يومية للفترة
            var currentDate = period.StartDate.Date;
            while (currentDate <= period.EndDate.Date)
            {
                var schedule = new DailyUnitSchedule
                {
                    Id = Guid.NewGuid(),
                    UnitId = unitId,
                    Date = currentDate,
                    Status = period.Status,
                    Reason = period.Reason,
                    Notes = period.Notes,
                    CreatedAt = DateTime.UtcNow
                };

                schedules.Add(schedule);
                currentDate = currentDate.AddDays(1);
            }
        }

        // حفظ الدفعة مرة واحدة
        await _scheduleRepository.BulkCreateAsync(schedules);
    }
    
    public async Task<IEnumerable<Guid>> GetAvailableUnitsInPropertyAsync(Guid propertyId, DateTime checkIn, DateTime checkOut, int guestCount, CancellationToken cancellationToken = default)
    {
        var units = await _unitRepository.GetUnitsByPropertyAsync(propertyId, cancellationToken);
        var available = new List<Guid>();
        foreach (var unit in units)
        {
            // من أجل محرك البحث والفلترة، نعتبر الوحدة غير متاحة فقط إذا كانت الأيام محجوزة
            // بحجوزات مؤكدة/مكتملة/CheckedIn أو أيام Blocked حقيقية.
            var schedules = await _scheduleRepository.GetByUnitAndDateRangeAsync(unit.Id, checkIn.Date, checkOut.Date.AddDays(-1));

            if (schedules == null || !schedules.Any())
            {
                // لا توجد سجلات في DailyUnitSchedule للفترة - نعتبر الوحدة متاحة في البحث
                available.Add(unit.Id);
                continue;
            }

            var hasBlockingDay = schedules.Any(s =>
                s.Status == "Blocked" ||
                (s.Status == "Booked" &&
                 (
                     s.BookingId == null ||
                     s.Booking == null ||
                     s.Booking.Status is BookingStatus.Confirmed or BookingStatus.Completed or BookingStatus.CheckedIn
                 ))
            );

            if (!hasBlockingDay)
            {
                available.Add(unit.Id);
            }
        }
        return available;
    }
}