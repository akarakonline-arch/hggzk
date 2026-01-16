namespace YemenBooking.Infrastructure.Repositories;

using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;

/// <summary>
/// مستودع الجدول اليومي الموحد للوحدات
/// Daily Unit Schedule Repository Implementation
/// </summary>
public class DailyUnitScheduleRepository : BaseRepository<DailyUnitSchedule>, IDailyUnitScheduleRepository
{
    public DailyUnitScheduleRepository(YemenBookingDbContext context) : base(context)
    {
    }

    /// <summary>
    /// الحصول على الجداول اليومية لوحدة في نطاق تاريخي
    /// </summary>
    public async Task<IEnumerable<DailyUnitSchedule>> GetByUnitAndDateRangeAsync(
        Guid unitId, 
        DateTime startDate, 
        DateTime endDate)
    {
        // تحويل التواريخ إلى Date فقط (بدون وقت)
        var start = startDate.Date;
        var end = endDate.Date;

        return await _context.DailyUnitSchedules
            .Where(s => s.UnitId == unitId && s.Date >= start && s.Date <= end)
            .Include(s => s.Booking)
            .OrderBy(s => s.Date)
            .ToListAsync();
    }

    /// <summary>
    /// الحصول على جدول يومي محدد لوحدة في تاريخ معين
    /// </summary>
    public async Task<DailyUnitSchedule?> GetByUnitAndDateAsync(Guid unitId, DateTime date)
    {
        var dateOnly = date.Date;
        
        return await _context.DailyUnitSchedules
            .FirstOrDefaultAsync(s => s.UnitId == unitId && s.Date == dateOnly);
    }

    /// <summary>
    /// إدراج مجموعة من الجداول اليومية دفعة واحدة
    /// </summary>
    public async Task BulkInsertAsync(IEnumerable<DailyUnitSchedule> schedules)
    {
        if (schedules == null || !schedules.Any())
            return;

        await _context.DailyUnitSchedules.AddRangeAsync(schedules);
        await _context.SaveChangesAsync();
    }

    /// <summary>
    /// تحديث مجموعة من الجداول اليومية دفعة واحدة
    /// </summary>
    public async Task BulkUpdateAsync(IEnumerable<DailyUnitSchedule> schedules)
    {
        if (schedules == null || !schedules.Any())
            return;

        _context.DailyUnitSchedules.UpdateRange(schedules);
        await _context.SaveChangesAsync();
    }

    /// <summary>
    /// حذف الجداول اليومية لوحدة في نطاق تاريخي
    /// </summary>
    public async Task DeleteRangeAsync(Guid unitId, DateTime startDate, DateTime endDate)
    {
        var start = startDate.Date;
        var end = endDate.Date;

        var schedulesToDelete = await _context.DailyUnitSchedules
            .Where(s => s.UnitId == unitId && s.Date >= start && s.Date <= end)
            .ToListAsync();

        if (schedulesToDelete.Any())
        {
            _context.DailyUnitSchedules.RemoveRange(schedulesToDelete);
            await _context.SaveChangesAsync();
        }
    }

    /// <summary>
    /// الحصول على الأيام المتاحة لوحدة في نطاق تاريخي
    /// </summary>
    public async Task<IEnumerable<DailyUnitSchedule>> GetAvailableDaysAsync(
        Guid unitId, 
        DateTime startDate, 
        DateTime endDate)
    {
        var start = startDate.Date;
        var end = endDate.Date;

        return await _context.DailyUnitSchedules
            .Where(s => s.UnitId == unitId 
                     && s.Date >= start 
                     && s.Date <= end
                     && s.Status == "Available")
            .OrderBy(s => s.Date)
            .ToListAsync();
    }

    /// <summary>
    /// الحصول على الأيام المحجوزة لوحدة في نطاق تاريخي
    /// </summary>
    public async Task<IEnumerable<DailyUnitSchedule>> GetBookedDaysAsync(
        Guid unitId, 
        DateTime startDate, 
        DateTime endDate)
    {
        var start = startDate.Date;
        var end = endDate.Date;

        return await _context.DailyUnitSchedules
            .Where(s => s.UnitId == unitId 
                     && s.Date >= start 
                     && s.Date <= end
                     && s.Status == "Booked")
            .OrderBy(s => s.Date)
            .Include(s => s.Booking)
            .ToListAsync();
    }

    /// <summary>
    /// التحقق من توفر وحدة في نطاق تاريخي
    /// </summary>
    public async Task<bool> IsUnitAvailableAsync(Guid unitId, DateTime startDate, DateTime endDate)
    {
        var start = startDate.Date;
        var end = endDate.Date;

        // حساب عدد الأيام المطلوبة
        var totalDays = (end - start).Days + 1;

        // حساب عدد الأيام المتاحة
        var availableDays = await _context.DailyUnitSchedules
            .CountAsync(s => s.UnitId == unitId 
                          && s.Date >= start 
                          && s.Date <= end
                          && s.Status == "Available");

        // إذا لم توجد سجلات، نفترض أن الوحدة متاحة (يمكن تغيير هذا المنطق حسب الحاجة)
        if (availableDays == 0)
        {
            var hasAnyRecords = await _context.DailyUnitSchedules
                .AnyAsync(s => s.UnitId == unitId && s.Date >= start && s.Date <= end);
            
            return !hasAnyRecords; // متاح إذا لم توجد سجلات على الإطلاق
        }

        return availableDays == totalDays;
    }

    /// <summary>
    /// الحصول على الأسعار لوحدة في نطاق تاريخي
    /// </summary>
    public async Task<IEnumerable<DailyUnitSchedule>> GetPricingForPeriodAsync(
        Guid unitId, 
        DateTime startDate, 
        DateTime endDate)
    {
        var start = startDate.Date;
        var end = endDate.Date;

        return await _context.DailyUnitSchedules
            .Where(s => s.UnitId == unitId 
                     && s.Date >= start 
                     && s.Date <= end
                     && s.PriceAmount.HasValue)
            .OrderBy(s => s.Date)
            .ToListAsync();
    }

    /// <summary>
    /// حذف جميع الجداول اليومية لوحدة معينة
    /// </summary>
    public async Task DeleteAllByUnitAsync(Guid unitId)
    {
        var schedulesToDelete = await _context.DailyUnitSchedules
            .Where(s => s.UnitId == unitId)
            .ToListAsync();

        if (schedulesToDelete.Any())
        {
            _context.DailyUnitSchedules.RemoveRange(schedulesToDelete);
            await _context.SaveChangesAsync();
        }
    }

    /// <summary>
    /// الحصول على عدد الأيام المتاحة لوحدة في نطاق تاريخي
    /// </summary>
    public async Task<int> CountAvailableDaysAsync(Guid unitId, DateTime startDate, DateTime endDate)
    {
        var start = startDate.Date;
        var end = endDate.Date;

        return await _context.DailyUnitSchedules
            .CountAsync(s => s.UnitId == unitId 
                          && s.Date >= start 
                          && s.Date <= end
                          && s.Status == "Available");
    }

    /// <summary>
    /// الحصول على الجداول اليومية حسب معرف الحجز
    /// </summary>
    public async Task<IEnumerable<DailyUnitSchedule>> GetByBookingIdAsync(Guid bookingId)
    {
        return await _context.DailyUnitSchedules
            .Where(s => s.BookingId == bookingId)
            .OrderBy(s => s.Date)
            .ToListAsync();
    }

    /// <summary>
    /// إضافة جدول يومي
    /// </summary>
    public new async Task AddAsync(DailyUnitSchedule schedule)
    {
        await _context.DailyUnitSchedules.AddAsync(schedule);
    }

    /// <summary>
    /// تحديث جدول يومي
    /// </summary>
    public new async Task UpdateAsync(DailyUnitSchedule schedule)
    {
        _context.DailyUnitSchedules.Update(schedule);
        await Task.CompletedTask;
    }

    /// <summary>
    /// حفظ التغييرات
    /// </summary>
    public async Task SaveChangesAsync()
    {
        await _context.SaveChangesAsync();
    }

    /// <summary>
    /// إدراج مجموعة من الجداول اليومية دفعة واحدة
    /// </summary>
    public async Task BulkCreateAsync(IEnumerable<DailyUnitSchedule> schedules)
    {
        if (schedules == null || !schedules.Any())
            return;

        await _context.DailyUnitSchedules.AddRangeAsync(schedules);
        await _context.SaveChangesAsync();
    }
}
