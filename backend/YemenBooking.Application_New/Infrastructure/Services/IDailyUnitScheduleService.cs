namespace YemenBooking.Application.Infrastructure.Services;

using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using YemenBooking.Core.Entities;

/// <summary>
/// واجهة خدمة الجدول اليومي الموحد للوحدات
/// Daily Unit Schedule Service Interface
/// </summary>
public interface IDailyUnitScheduleService
{
    /// <summary>
    /// تعيين أسعار لفترة زمنية - يتم تحويلها إلى سجلات يومية
    /// Set pricing for a period - converts to daily records
    /// </summary>
    /// <param name="unitId">معرف الوحدة</param>
    /// <param name="startDate">تاريخ البداية</param>
    /// <param name="endDate">تاريخ النهاية</param>
    /// <param name="priceAmount">مبلغ السعر</param>
    /// <param name="currency">العملة</param>
    /// <param name="priceType">نوع السعر</param>
    /// <param name="pricingTier">فئة التسعير</param>
    /// <param name="percentageChange">نسبة التغيير (اختياري)</param>
    /// <param name="minPrice">الحد الأدنى للسعر (اختياري)</param>
    /// <param name="maxPrice">الحد الأقصى للسعر (اختياري)</param>
    /// <param name="overwriteExisting">استبدال الأسعار الموجودة</param>
    /// <param name="createdBy">المستخدم الذي أنشأ السجل</param>
    /// <returns>عدد السجلات المنشأة/المحدثة</returns>
    Task<int> SetPricingForPeriodAsync(
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
        string? createdBy = null);

    /// <summary>
    /// تعيين حالة الإتاحة لفترة زمنية - يتم تحويلها إلى سجلات يومية
    /// Set availability status for a period - converts to daily records
    /// </summary>
    /// <param name="unitId">معرف الوحدة</param>
    /// <param name="startDate">تاريخ البداية</param>
    /// <param name="endDate">تاريخ النهاية</param>
    /// <param name="status">حالة الإتاحة</param>
    /// <param name="reason">السبب (اختياري)</param>
    /// <param name="notes">ملاحظات (اختياري)</param>
    /// <param name="bookingId">معرف الحجز (اختياري)</param>
    /// <param name="overwriteExisting">استبدال السجلات الموجودة</param>
    /// <param name="createdBy">المستخدم الذي أنشأ السجل</param>
    /// <returns>عدد السجلات المنشأة/المحدثة</returns>
    Task<int> SetAvailabilityForPeriodAsync(
        Guid unitId,
        DateTime startDate,
        DateTime endDate,
        string status,
        string? reason = null,
        string? notes = null,
        Guid? bookingId = null,
        bool overwriteExisting = false,
        string? createdBy = null);

    /// <summary>
    /// الحصول على الجدول اليومي لوحدة في فترة زمنية
    /// Get daily schedule for a unit in a period
    /// </summary>
    /// <param name="unitId">معرف الوحدة</param>
    /// <param name="startDate">تاريخ البداية</param>
    /// <param name="endDate">تاريخ النهاية</param>
    /// <param name="includeUnit">تضمين بيانات الوحدة</param>
    /// <param name="includeBooking">تضمين بيانات الحجز</param>
    /// <returns>قائمة الجداول اليومية</returns>
    Task<IEnumerable<DailyUnitSchedule>> GetScheduleForPeriodAsync(
        Guid unitId,
        DateTime startDate,
        DateTime endDate,
        bool includeUnit = false,
        bool includeBooking = false);

    /// <summary>
    /// التحقق من توفر وحدة لفترة زمنية
    /// Check if unit is available for a period
    /// </summary>
    /// <param name="unitId">معرف الوحدة</param>
    /// <param name="startDate">تاريخ البداية</param>
    /// <param name="endDate">تاريخ النهاية</param>
    /// <param name="excludeBookingId">استثناء حجز معيّن من التحقق (يُعامل كتوفّر لنفس العميل)</param>
    /// <returns>معلومات التوفر</returns>
    Task<AvailabilityCheckResult> CheckAvailabilityAsync(
        Guid unitId,
        DateTime startDate,
        DateTime endDate,
        Guid? excludeBookingId = null);

    /// <summary>
    /// حساب السعر الإجمالي لفترة زمنية
    /// Calculate total price for a period
    /// </summary>
    /// <param name="unitId">معرف الوحدة</param>
    /// <param name="startDate">تاريخ البداية</param>
    /// <param name="endDate">تاريخ النهاية</param>
    /// <param name="basePriceAmount">السعر الأساسي للوحدة (للأيام بدون سعر محدد)</param>
    /// <param name="baseCurrency">العملة الأساسية</param>
    /// <returns>معلومات السعر الإجمالي</returns>
    Task<PricingCalculationResult> CalculatePriceForPeriodAsync(
        Guid unitId,
        DateTime startDate,
        DateTime endDate,
        decimal basePriceAmount,
        string baseCurrency);

    /// <summary>
    /// حذف جميع السجلات لوحدة في فترة زمنية
    /// Delete all records for a unit in a period
    /// </summary>
    /// <param name="unitId">معرف الوحدة</param>
    /// <param name="startDate">تاريخ البداية</param>
    /// <param name="endDate">تاريخ النهاية</param>
    Task DeleteScheduleForPeriodAsync(
        Guid unitId,
        DateTime startDate,
        DateTime endDate);

    /// <summary>
    /// تحديث سجل يومي معين
    /// Update a specific daily schedule
    /// </summary>
    /// <param name="scheduleId">معرف السجل</param>
    /// <param name="priceAmount">مبلغ السعر (اختياري)</param>
    /// <param name="status">حالة الإتاحة (اختياري)</param>
    /// <param name="reason">السبب (اختياري)</param>
    /// <param name="notes">ملاحظات (اختياري)</param>
    /// <param name="modifiedBy">المستخدم الذي عدّل السجل</param>
    Task<DailyUnitSchedule?> UpdateDailyScheduleAsync(
        Guid scheduleId,
        decimal? priceAmount = null,
        string? status = null,
        string? reason = null,
        string? notes = null,
        string? modifiedBy = null);

    /// <summary>
    /// إنشاء أو تحديث جدول يومي لتاريخ محدد
    /// Create or update daily schedule for a specific date
    /// </summary>
    /// <param name="unitId">معرف الوحدة</param>
    /// <param name="date">التاريخ</param>
    /// <param name="schedule">بيانات الجدول اليومي</param>
    /// <returns>الجدول اليومي المحدث أو المنشأ</returns>
    Task<DailyUnitSchedule> UpsertDailyScheduleAsync(
        Guid unitId,
        DateTime date,
        DailyUnitSchedule schedule);
}

/// <summary>
/// نتيجة فحص التوفر
/// Availability check result
/// </summary>
public class AvailabilityCheckResult
{
    public bool IsAvailable { get; set; }
    public int TotalDays { get; set; }
    public int AvailableDays { get; set; }
    public int UnavailableDays { get; set; }
    public List<DateTime> UnavailableDates { get; set; } = new();
    public string? Message { get; set; }
}

/// <summary>
/// نتيجة حساب الأسعار
/// Pricing calculation result
/// </summary>
public class PricingCalculationResult
{
    public decimal TotalPrice { get; set; }
    public string Currency { get; set; } = string.Empty;
    public int TotalDays { get; set; }
    public int DaysWithCustomPricing { get; set; }
    public int DaysWithBasePrice { get; set; }
    public decimal AveragePerDay { get; set; }
    public List<DailyPriceInfo> DailyPrices { get; set; } = new();
}

/// <summary>
/// معلومات السعر اليومي
/// Daily price information
/// </summary>
public class DailyPriceInfo
{
    public DateTime Date { get; set; }
    public decimal Price { get; set; }
    public string? PriceType { get; set; }
    public bool IsCustomPrice { get; set; }
}
