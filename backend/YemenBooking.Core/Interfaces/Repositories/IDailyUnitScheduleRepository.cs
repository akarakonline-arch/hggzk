namespace YemenBooking.Core.Interfaces.Repositories;

using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using YemenBooking.Core.Entities;

/// <summary>
/// واجهة مستودع الجدول اليومي الموحد للوحدات
/// Daily Unit Schedule Repository Interface
/// </summary>
public interface IDailyUnitScheduleRepository : IRepository<DailyUnitSchedule>
{
    /// <summary>
    /// الحصول على الجداول اليومية لوحدة في نطاق تاريخي
    /// Get daily schedules for a unit within a date range
    /// </summary>
    /// <param name="unitId">معرف الوحدة</param>
    /// <param name="startDate">تاريخ البداية</param>
    /// <param name="endDate">تاريخ النهاية</param>
    /// <returns>قائمة الجداول اليومية</returns>
    Task<IEnumerable<DailyUnitSchedule>> GetByUnitAndDateRangeAsync(
        Guid unitId, 
        DateTime startDate, 
        DateTime endDate);

    /// <summary>
    /// الحصول على جدول يومي محدد لوحدة في تاريخ معين
    /// Get a specific daily schedule for a unit on a specific date
    /// </summary>
    /// <param name="unitId">معرف الوحدة</param>
    /// <param name="date">التاريخ</param>
    /// <returns>الجدول اليومي أو null</returns>
    Task<DailyUnitSchedule?> GetByUnitAndDateAsync(Guid unitId, DateTime date);

    /// <summary>
    /// إدراج مجموعة من الجداول اليومية دفعة واحدة
    /// Bulk insert daily schedules
    /// </summary>
    /// <param name="schedules">قائمة الجداول اليومية</param>
    Task BulkInsertAsync(IEnumerable<DailyUnitSchedule> schedules);

    /// <summary>
    /// تحديث مجموعة من الجداول اليومية دفعة واحدة
    /// Bulk update daily schedules
    /// </summary>
    /// <param name="schedules">قائمة الجداول اليومية للتحديث</param>
    Task BulkUpdateAsync(IEnumerable<DailyUnitSchedule> schedules);

    /// <summary>
    /// حذف الجداول اليومية لوحدة في نطاق تاريخي
    /// Delete daily schedules for a unit within a date range
    /// </summary>
    /// <param name="unitId">معرف الوحدة</param>
    /// <param name="startDate">تاريخ البداية</param>
    /// <param name="endDate">تاريخ النهاية</param>
    Task DeleteRangeAsync(Guid unitId, DateTime startDate, DateTime endDate);

    /// <summary>
    /// الحصول على الأيام المتاحة لوحدة في نطاق تاريخي
    /// Get available days for a unit within a date range
    /// </summary>
    /// <param name="unitId">معرف الوحدة</param>
    /// <param name="startDate">تاريخ البداية</param>
    /// <param name="endDate">تاريخ النهاية</param>
    /// <returns>قائمة الجداول اليومية المتاحة</returns>
    Task<IEnumerable<DailyUnitSchedule>> GetAvailableDaysAsync(
        Guid unitId, 
        DateTime startDate, 
        DateTime endDate);

    /// <summary>
    /// الحصول على الأيام المحجوزة لوحدة في نطاق تاريخي
    /// Get booked days for a unit within a date range
    /// </summary>
    /// <param name="unitId">معرف الوحدة</param>
    /// <param name="startDate">تاريخ البداية</param>
    /// <param name="endDate">تاريخ النهاية</param>
    /// <returns>قائمة الجداول اليومية المحجوزة</returns>
    Task<IEnumerable<DailyUnitSchedule>> GetBookedDaysAsync(
        Guid unitId, 
        DateTime startDate, 
        DateTime endDate);

    /// <summary>
    /// التحقق من توفر وحدة في نطاق تاريخي
    /// Check if a unit is available within a date range
    /// </summary>
    /// <param name="unitId">معرف الوحدة</param>
    /// <param name="startDate">تاريخ البداية</param>
    /// <param name="endDate">تاريخ النهاية</param>
    /// <returns>true إذا كانت متاحة بالكامل، false خلاف ذلك</returns>
    Task<bool> IsUnitAvailableAsync(Guid unitId, DateTime startDate, DateTime endDate);

    /// <summary>
    /// الحصول على الأسعار لوحدة في نطاق تاريخي
    /// Get prices for a unit within a date range
    /// </summary>
    /// <param name="unitId">معرف الوحدة</param>
    /// <param name="startDate">تاريخ البداية</param>
    /// <param name="endDate">تاريخ النهاية</param>
    /// <returns>قائمة الجداول اليومية مع الأسعار</returns>
    Task<IEnumerable<DailyUnitSchedule>> GetPricingForPeriodAsync(
        Guid unitId, 
        DateTime startDate, 
        DateTime endDate);

    /// <summary>
    /// حذف جميع الجداول اليومية لوحدة معينة
    /// Delete all daily schedules for a specific unit
    /// </summary>
    /// <param name="unitId">معرف الوحدة</param>
    Task DeleteAllByUnitAsync(Guid unitId);

    /// <summary>
    /// الحصول على عدد الأيام المتاحة لوحدة في نطاق تاريخي
    /// Get count of available days for a unit within a date range
    /// </summary>
    /// <param name="unitId">معرف الوحدة</param>
    /// <param name="startDate">تاريخ البداية</param>
    /// <param name="endDate">تاريخ النهاية</param>
    /// <returns>عدد الأيام المتاحة</returns>
    Task<int> CountAvailableDaysAsync(Guid unitId, DateTime startDate, DateTime endDate);

    /// <summary>
    /// الحصول على الجداول اليومية حسب معرف الحجز
    /// Get daily schedules by booking ID
    /// </summary>
    /// <param name="bookingId">معرف الحجز</param>
    /// <returns>قائمة الجداول اليومية</returns>
    Task<IEnumerable<DailyUnitSchedule>> GetByBookingIdAsync(Guid bookingId);

    /// <summary>
    /// إضافة جدول يومي
    /// Add a daily schedule
    /// </summary>
    /// <param name="schedule">الجدول اليومي</param>
    Task AddAsync(DailyUnitSchedule schedule);

    /// <summary>
    /// تحديث جدول يومي
    /// Update a daily schedule
    /// </summary>
    /// <param name="schedule">الجدول اليومي</param>
    Task UpdateAsync(DailyUnitSchedule schedule);

    /// <summary>
    /// حفظ التغييرات
    /// Save changes
    /// </summary>
    Task SaveChangesAsync();

    /// <summary>
    /// إدراج مجموعة من الجداول اليومية دفعة واحدة
    /// Bulk create daily schedules
    /// </summary>
    /// <param name="schedules">قائمة الجداول اليومية</param>
    Task BulkCreateAsync(IEnumerable<DailyUnitSchedule> schedules);
}
