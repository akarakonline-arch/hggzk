namespace YemenBooking.Core.Entities;

using System;
using System.ComponentModel.DataAnnotations;

/// <summary>
/// كيان الجدول اليومي الموحد للوحدة (يجمع التسعير والإتاحة)
/// Daily unified schedule entity for unit (combines pricing and availability)
/// </summary>
[Display(Name = "كيان الجدول اليومي الموحد للوحدة")]
public class DailyUnitSchedule : BaseEntity<Guid>
{
    /// <summary>
    /// معرف الوحدة
    /// Unit identifier
    /// </summary>
    [Display(Name = "معرف الوحدة")]
    public Guid UnitId { get; set; }
    
    /// <summary>
    /// الملاحة إلى كيان الوحدة
    /// Navigation to Unit entity
    /// </summary>
    public virtual Unit Unit { get; set; } = null!;

    /// <summary>
    /// تاريخ اليوم (بدون وقت)
    /// Date of the day (without time)
    /// </summary>
    [Display(Name = "تاريخ اليوم")]
    public DateTime Date { get; set; }

    // ====== خصائص الإتاحة (Availability Properties) ======
    
    /// <summary>
    /// حالة الإتاحة (Available, Booked, Blocked, Maintenance, OwnerUse)
    /// Availability status
    /// </summary>
    [Display(Name = "حالة الإتاحة")]
    public string Status { get; set; } = "Available";

    /// <summary>
    /// سبب عدم الإتاحة أو الحظر
    /// Unavailability or blocking reason
    /// </summary>
    [Display(Name = "سبب عدم الإتاحة")]
    public string? Reason { get; set; }

    /// <summary>
    /// ملاحظات إضافية
    /// Additional notes
    /// </summary>
    [Display(Name = "ملاحظات")]
    public string? Notes { get; set; }

    /// <summary>
    /// معرف الحجز المرتبط (إذا كانت محجوزة)
    /// Associated booking identifier (if booked)
    /// </summary>
    [Display(Name = "معرف الحجز المرتبط")]
    public Guid? BookingId { get; set; }

    /// <summary>
    /// الملاحة إلى كيان الحجز
    /// Navigation to Booking entity
    /// </summary>
    public virtual Booking? Booking { get; set; }

    // ====== خصائص التسعير (Pricing Properties) ======

    /// <summary>
    /// مبلغ السعر لهذا اليوم
    /// Price amount for this day
    /// </summary>
    [Display(Name = "مبلغ السعر")]
    public decimal? PriceAmount { get; set; }

    /// <summary>
    /// عملة السعر
    /// Price currency
    /// </summary>
    [Display(Name = "عملة السعر")]
    public string? Currency { get; set; }

    /// <summary>
    /// الملاحة إلى كيان العملة
    /// Navigation to Currency entity
    /// </summary>
    public virtual Currency? CurrencyRef { get; set; }

    /// <summary>
    /// نوع السعر (Base, Weekend, Seasonal, Holiday, SpecialEvent, Custom)
    /// Price type
    /// </summary>
    [Display(Name = "نوع السعر")]
    public string? PriceType { get; set; }

    /// <summary>
    /// فئة التسعير (Normal, High, Peak, Discount, Custom)
    /// Pricing tier
    /// </summary>
    [Display(Name = "فئة التسعير")]
    public string? PricingTier { get; set; }

    /// <summary>
    /// نسبة التغيير عن السعر الأساسي (+/-)
    /// Percentage change from base price
    /// </summary>
    [Display(Name = "نسبة التغيير")]
    public decimal? PercentageChange { get; set; }

    /// <summary>
    /// الحد الأدنى للسعر (إذا كان هناك قاعدة نسبة مئوية)
    /// Minimum price (if percentage rule applies)
    /// </summary>
    [Display(Name = "الحد الأدنى للسعر")]
    public decimal? MinPrice { get; set; }

    /// <summary>
    /// الحد الأقصى للسعر (إذا كان هناك قاعدة نسبة مئوية)
    /// Maximum price (if percentage rule applies)
    /// </summary>
    [Display(Name = "الحد الأقصى للسعر")]
    public decimal? MaxPrice { get; set; }

    // ====== خصائص إضافية (Additional Properties) ======

    /// <summary>
    /// وقت البداية (اختياري - للوحدات بالساعة)
    /// Start time (optional - for hourly units)
    /// </summary>
    [Display(Name = "وقت البداية")]
    public TimeSpan? StartTime { get; set; }

    /// <summary>
    /// وقت النهاية (اختياري - للوحدات بالساعة)
    /// End time (optional - for hourly units)
    /// </summary>
    [Display(Name = "وقت النهاية")]
    public TimeSpan? EndTime { get; set; }

    /// <summary>
    /// اسم المستخدم الذي أنشأ السجل
    /// Created by user
    /// </summary>
    [Display(Name = "أنشئ بواسطة")]
    public string? CreatedBy { get; set; }

    /// <summary>
    /// اسم المستخدم الذي عدّل السجل
    /// Modified by user
    /// </summary>
    [Display(Name = "عُدّل بواسطة")]
    public string? ModifiedBy { get; set; }
}
