namespace YemenBooking.Infrastructure.Services;

using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// خدمة الجدول اليومي الموحد للوحدات
/// Daily Unit Schedule Service Implementation
/// </summary>
public class DailyUnitScheduleService : IDailyUnitScheduleService
{
    private readonly IDailyUnitScheduleRepository _scheduleRepository;
    private readonly ILogger<DailyUnitScheduleService> _logger;

    public DailyUnitScheduleService(
        IDailyUnitScheduleRepository scheduleRepository,
        ILogger<DailyUnitScheduleService> logger)
    {
        _scheduleRepository = scheduleRepository;
        _logger = logger;
    }

    /// <summary>
    /// تعيين أسعار لفترة زمنية - يتم تحويلها إلى سجلات يومية
    /// </summary>
    public async Task<int> SetPricingForPeriodAsync(
        Guid unitId,
        DateTime startDate,
        DateTime endDate,
        decimal priceAmount,
        string currency,
        string? priceType = null,
        string? pricingTier = null,
        decimal? percentageChange = null,
        decimal? minPrice = null,
        decimal? maxPrice = null,
        bool overwriteExisting = false,
        string? createdBy = null)
    {
        try
        {
            var start = startDate.Date;
            var end = endDate.Date;

            // الحصول على السجلات الموجودة
            var existingSchedules = (await _scheduleRepository.GetByUnitAndDateRangeAsync(unitId, start, end))
                .ToDictionary(s => s.Date);

            var schedulesToCreate = new List<DailyUnitSchedule>();
            var schedulesToUpdate = new List<DailyUnitSchedule>();

            // إنشاء سجلات يومية للفترة
            for (var date = start; date <= end; date = date.AddDays(1))
            {
                if (existingSchedules.TryGetValue(date, out var existingSchedule))
                {
                    // تحديث السجل الموجود
                    if (overwriteExisting || !existingSchedule.PriceAmount.HasValue)
                    {
                        existingSchedule.PriceAmount = priceAmount;
                        existingSchedule.Currency = currency;
                        existingSchedule.PriceType = priceType;
                        existingSchedule.PricingTier = pricingTier;
                        existingSchedule.PercentageChange = percentageChange;
                        existingSchedule.MinPrice = minPrice;
                        existingSchedule.MaxPrice = maxPrice;
                        existingSchedule.ModifiedBy = createdBy;
                        existingSchedule.UpdatedAt = DateTime.UtcNow;
                        
                        schedulesToUpdate.Add(existingSchedule);
                    }
                }
                else
                {
                    // إنشاء سجل جديد
                    var newSchedule = new DailyUnitSchedule
                    {
                        Id = Guid.NewGuid(),
                        UnitId = unitId,
                        Date = date,
                        Status = "Available", // الحالة الافتراضية
                        PriceAmount = priceAmount,
                        Currency = currency,
                        PriceType = priceType,
                        PricingTier = pricingTier,
                        PercentageChange = percentageChange,
                        MinPrice = minPrice,
                        MaxPrice = maxPrice,
                        CreatedBy = createdBy,
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow
                    };

                    schedulesToCreate.Add(newSchedule);
                }
            }

            // حفظ التغييرات
            if (schedulesToCreate.Any())
            {
                await _scheduleRepository.BulkInsertAsync(schedulesToCreate);
            }

            if (schedulesToUpdate.Any())
            {
                await _scheduleRepository.BulkUpdateAsync(schedulesToUpdate);
            }

            _logger.LogInformation(
                "Set pricing for unit {UnitId} from {StartDate} to {EndDate}. Created: {Created}, Updated: {Updated}",
                unitId, start, end, schedulesToCreate.Count, schedulesToUpdate.Count);

            return schedulesToCreate.Count + schedulesToUpdate.Count;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error setting pricing for unit {UnitId}", unitId);
            throw;
        }
    }

    /// <summary>
    /// تعيين حالة الإتاحة لفترة زمنية - يتم تحويلها إلى سجلات يومية
    /// </summary>
    public async Task<int> SetAvailabilityForPeriodAsync(
        Guid unitId,
        DateTime startDate,
        DateTime endDate,
        string status,
        string? reason = null,
        string? notes = null,
        Guid? bookingId = null,
        bool overwriteExisting = false,
        string? createdBy = null)
    {
        try
        {
            var start = startDate.Date;
            var end = endDate.Date;

            var existingSchedules = (await _scheduleRepository.GetByUnitAndDateRangeAsync(unitId, start, end))
                .ToDictionary(s => s.Date);

            var schedulesToCreate = new List<DailyUnitSchedule>();
            var schedulesToUpdate = new List<DailyUnitSchedule>();

            for (var date = start; date <= end; date = date.AddDays(1))
            {
                if (existingSchedules.TryGetValue(date, out var existingSchedule))
                {
                    if (overwriteExisting)
                    {
                        existingSchedule.Status = status;
                        existingSchedule.Reason = reason;
                        existingSchedule.Notes = notes;
                        existingSchedule.BookingId = bookingId;
                        existingSchedule.ModifiedBy = createdBy;
                        existingSchedule.UpdatedAt = DateTime.UtcNow;

                        schedulesToUpdate.Add(existingSchedule);
                    }
                }
                else
                {
                    var newSchedule = new DailyUnitSchedule
                    {
                        Id = Guid.NewGuid(),
                        UnitId = unitId,
                        Date = date,
                        Status = status,
                        Reason = reason,
                        Notes = notes,
                        BookingId = bookingId,
                        CreatedBy = createdBy,
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow
                    };

                    schedulesToCreate.Add(newSchedule);
                }
            }

            if (schedulesToCreate.Any())
            {
                await _scheduleRepository.BulkInsertAsync(schedulesToCreate);
            }

            if (schedulesToUpdate.Any())
            {
                await _scheduleRepository.BulkUpdateAsync(schedulesToUpdate);
            }

            _logger.LogInformation(
                "Set availability for unit {UnitId} from {StartDate} to {EndDate} as {Status}. Created: {Created}, Updated: {Updated}",
                unitId, start, end, status, schedulesToCreate.Count, schedulesToUpdate.Count);

            return schedulesToCreate.Count + schedulesToUpdate.Count;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error setting availability for unit {UnitId}", unitId);
            throw;
        }
    }

    /// <summary>
    /// الحصول على الجدول اليومي لوحدة في فترة زمنية
    /// </summary>
    public async Task<IEnumerable<DailyUnitSchedule>> GetScheduleForPeriodAsync(
        Guid unitId,
        DateTime startDate,
        DateTime endDate,
        bool includeUnit = false,
        bool includeBooking = false)
    {
        return await _scheduleRepository.GetByUnitAndDateRangeAsync(unitId, startDate.Date, endDate.Date);
    }

    /// <summary>
    /// التحقق من توفر وحدة لفترة زمنية
    /// </summary>
    public async Task<AvailabilityCheckResult> CheckAvailabilityAsync(
        Guid unitId,
        DateTime startDate,
        DateTime endDate,
        Guid? excludeBookingId = null)
    {
        var start = startDate.Date;
        var end = endDate.Date;
        var totalDays = (end - start).Days + 1;

        var schedules = await _scheduleRepository.GetByUnitAndDateRangeAsync(unitId, start, end);
        var schedulesDict = schedules.ToDictionary(s => s.Date);

        var unavailableDates = new List<DateTime>();
        var availableDays = 0;

        for (var date = start; date <= end; date = date.AddDays(1))
        {
            if (schedulesDict.TryGetValue(date, out var schedule))
            {
                // متاح إذا كان اليوم متاح أو كان محجوزاً لنفس الحجز المستثنى
                if (schedule.Status == "Available" || (excludeBookingId != null && schedule.BookingId == excludeBookingId))
                {
                    availableDays++;
                }
                else
                {
                    unavailableDates.Add(date);
                }
            }
            else
            {
                // إذا لم يوجد سجل، نفترض أنه متاح
                availableDays++;
            }
        }

        var isAvailable = availableDays == totalDays;
        var unavailableDays = totalDays - availableDays;

        return new AvailabilityCheckResult
        {
            IsAvailable = isAvailable,
            TotalDays = totalDays,
            AvailableDays = availableDays,
            UnavailableDays = unavailableDays,
            UnavailableDates = unavailableDates,
            Message = isAvailable 
                ? "الوحدة متاحة للفترة المحددة" 
                : $"الوحدة غير متاحة في {unavailableDays} يوم/أيام"
        };
    }

    /// <summary>
    /// حساب السعر الإجمالي لفترة زمنية
    /// </summary>
    public async Task<PricingCalculationResult> CalculatePriceForPeriodAsync(
        Guid unitId,
        DateTime startDate,
        DateTime endDate,
        decimal basePriceAmount,
        string baseCurrency)
    {
        var start = startDate.Date;
        var end = endDate.Date;
        var totalDays = (end - start).Days + 1;

        var schedules = await _scheduleRepository.GetByUnitAndDateRangeAsync(unitId, start, end);
        var schedulesDict = schedules.ToDictionary(s => s.Date);

        decimal totalPrice = 0;
        var daysWithCustomPricing = 0;
        var dailyPrices = new List<DailyPriceInfo>();

        for (var date = start; date <= end; date = date.AddDays(1))
        {
            decimal dayPrice;
            string? priceType = null;
            bool isCustomPrice;

            if (schedulesDict.TryGetValue(date, out var schedule) && schedule.PriceAmount.HasValue)
            {
                dayPrice = schedule.PriceAmount.Value;
                priceType = schedule.PriceType;
                isCustomPrice = true;
                daysWithCustomPricing++;
            }
            else
            {
                dayPrice = basePriceAmount;
                isCustomPrice = false;
            }

            totalPrice += dayPrice;
            dailyPrices.Add(new DailyPriceInfo
            {
                Date = date,
                Price = dayPrice,
                PriceType = priceType,
                IsCustomPrice = isCustomPrice
            });
        }

        var daysWithBasePrice = totalDays - daysWithCustomPricing;
        var averagePerDay = totalDays > 0 ? totalPrice / totalDays : 0;

        return new PricingCalculationResult
        {
            TotalPrice = totalPrice,
            Currency = baseCurrency,
            TotalDays = totalDays,
            DaysWithCustomPricing = daysWithCustomPricing,
            DaysWithBasePrice = daysWithBasePrice,
            AveragePerDay = averagePerDay,
            DailyPrices = dailyPrices
        };
    }

    /// <summary>
    /// حذف جميع السجلات لوحدة في فترة زمنية
    /// </summary>
    public async Task DeleteScheduleForPeriodAsync(Guid unitId, DateTime startDate, DateTime endDate)
    {
        await _scheduleRepository.DeleteRangeAsync(unitId, startDate.Date, endDate.Date);
        _logger.LogInformation("Deleted schedule for unit {UnitId} from {StartDate} to {EndDate}", 
            unitId, startDate.Date, endDate.Date);
    }

    /// <summary>
    /// تحديث سجل يومي معين
    /// </summary>
    public async Task<DailyUnitSchedule?> UpdateDailyScheduleAsync(
        Guid scheduleId,
        decimal? priceAmount = null,
        string? status = null,
        string? reason = null,
        string? notes = null,
        string? modifiedBy = null)
    {
        var schedule = await _scheduleRepository.GetByIdAsync(scheduleId);
        if (schedule == null)
        {
            _logger.LogWarning("Schedule {ScheduleId} not found", scheduleId);
            return null;
        }

        if (priceAmount.HasValue)
            schedule.PriceAmount = priceAmount;

        if (!string.IsNullOrEmpty(status))
            schedule.Status = status;

        if (reason != null)
            schedule.Reason = reason;

        if (notes != null)
            schedule.Notes = notes;

        schedule.ModifiedBy = modifiedBy;
        schedule.UpdatedAt = DateTime.UtcNow;

        await _scheduleRepository.UpdateAsync(schedule);

        _logger.LogInformation("Updated schedule {ScheduleId} for unit {UnitId} on {Date}",
            scheduleId, schedule.UnitId, schedule.Date);

        return schedule;
    }

    /// <summary>
    /// إنشاء أو تحديث جدول يومي لتاريخ محدد
    /// </summary>
    public async Task<DailyUnitSchedule> UpsertDailyScheduleAsync(
        Guid unitId,
        DateTime date,
        DailyUnitSchedule schedule)
    {
        var dateOnly = date.Date;
        var existing = await _scheduleRepository.GetByUnitAndDateAsync(unitId, dateOnly);

        if (existing != null)
        {
            // تحديث السجل الموجود
            existing.Status = schedule.Status;
            existing.PriceAmount = schedule.PriceAmount;
            existing.Currency = schedule.Currency;
            existing.PriceType = schedule.PriceType;
            existing.PricingTier = schedule.PricingTier;
            existing.PercentageChange = schedule.PercentageChange;
            existing.MinPrice = schedule.MinPrice;
            existing.MaxPrice = schedule.MaxPrice;
            existing.Reason = schedule.Reason;
            existing.Notes = schedule.Notes;
            existing.BookingId = schedule.BookingId;
            existing.ModifiedBy = schedule.ModifiedBy;
            existing.UpdatedAt = DateTime.UtcNow;

            await _scheduleRepository.UpdateAsync(existing);
            return existing;
        }
        else
        {
            // إنشاء سجل جديد
            schedule.Id = Guid.NewGuid();
            schedule.UnitId = unitId;
            schedule.Date = dateOnly;
            schedule.CreatedAt = DateTime.UtcNow;
            schedule.UpdatedAt = DateTime.UtcNow;

            await _scheduleRepository.AddAsync(schedule);
            return schedule;
        }
    }
}
