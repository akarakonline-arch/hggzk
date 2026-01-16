using System;
using System.Collections.Generic;

namespace YemenBooking.Core.Indexing.Models;

/// <summary>
/// مستند فهرسة الوحدة الكامل - يحتوي على كل المعلومات المطلوبة للبحث والفلترة
/// هذا المستند يُخزن في Redis بصيغة JSON تحت المفتاح: property:{propertyId}:unit:{unitId}
/// 
/// الهدف:
/// • تجميع كل البيانات المتعلقة بالوحدة في مكان واحد لتسريع البحث
/// • تقليل عدد الاستعلامات إلى قاعدة البيانات
/// • توفير معلومات محسوبة مسبقاً (ملخصات، نطاقات، كلمات مفتاحية)
/// 
/// البنية:
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 1. بيانات الوحدة الأساسية (Unit Basic Data)
/// 2. بيانات العقار الأساسية (Property Basic Data)
/// 3. الموقع الجغرافي (Location)
/// 4. الإتاحات (Availabilities)
/// 5. قواعد التسعير (Pricing Rules)
/// 6. نطاقات الأسعار المحسوبة (Price Ranges)
/// 7. الحقول الديناميكية (Dynamic Fields)
/// 8. المرافق (Amenities)
/// 9. الخدمات (Services)
/// 10. الصور (Images)
/// 11. ملخصات البحث (Search Summaries)
/// 12. بيانات التحكم (Metadata)
/// </summary>
public class UnitIndexDocument
{
    #region === معرف المستند (Document Key) ===
    
    /// <summary>
    /// المفتاح المركب في Redis: property:{propertyId}:unit:{unitId}
    /// </summary>
    public string Key => $"property:{PropertyId}:unit:{UnitId}";
    
    #endregion
    
    #region === بيانات الوحدة الأساسية (Unit Basic Data) ===
    
    /// <summary>
    /// معرف الوحدة (Primary Key)
    /// </summary>
    public Guid UnitId { get; set; }
    
    /// <summary>
    /// اسم الوحدة
    /// مثال: "جناح ملكي 101"، "غرفة مزدوجة A"
    /// </summary>
    public string UnitName { get; set; } = string.Empty;
    
    /// <summary>
    /// معرف نوع الوحدة
    /// </summary>
    public Guid UnitTypeId { get; set; }
    
    /// <summary>
    /// اسم نوع الوحدة
    /// مثال: "جناح"، "غرفة"، "شقة"، "استوديو"
    /// </summary>
    public string UnitTypeName { get; set; } = string.Empty;
    
    /// <summary>
    /// السعر الأساسي للوحدة
    /// </summary>
    public MoneyData BasePrice { get; set; } = new();
    
    /// <summary>
    /// السعة القصوى (إجمالي عدد الضيوف)
    /// </summary>
    public int MaxCapacity { get; set; }
    
    /// <summary>
    /// سعة البالغين
    /// </summary>
    public int AdultsCapacity { get; set; }
    
    /// <summary>
    /// سعة الأطفال
    /// </summary>
    public int ChildrenCapacity { get; set; }
    
    /// <summary>
    /// نسبة الخصم الافتراضية (0-100)
    /// </summary>
    public decimal DiscountPercentage { get; set; }
    
    // ملاحظة: تم حذف IsAvailable - نعتمد على DailySchedules
    
    /// <summary>
    /// عدد مرات المشاهدة
    /// </summary>
    public int ViewCount { get; set; }
    
    /// <summary>
    /// عدد الحجوزات
    /// </summary>
    public int BookingCount { get; set; }
    
    /// <summary>
    /// هل تسمح الوحدة بإلغاء الحجز
    /// </summary>
    public bool AllowsCancellation { get; set; }
    
    /// <summary>
    /// عدد أيام السماح بالإلغاء قبل موعد الوصول
    /// </summary>
    public int? CancellationWindowDays { get; set; }
    
    /// <summary>
    /// طريقة التسعير
    /// Hourly, Daily, Weekly, Monthly
    /// </summary>
    public string PricingMethod { get; set; } = "Daily";
    
    #endregion
    
    #region === بيانات العقار الأساسية (Property Basic Data) ===
    
    /// <summary>
    /// معرف العقار
    /// </summary>
    public Guid PropertyId { get; set; }
    
    /// <summary>
    /// اسم العقار
    /// مثال: "فندق الريتز"، "منتجع النخيل"
    /// </summary>
    public string PropertyName { get; set; } = string.Empty;
    
    /// <summary>
    /// معرف نوع العقار
    /// </summary>
    public Guid PropertyTypeId { get; set; }
    
    /// <summary>
    /// اسم نوع العقار
    /// مثال: "فندق"، "شقة فندقية"، "منتجع"
    /// </summary>
    public string PropertyTypeName { get; set; } = string.Empty;
    
    /// <summary>
    /// معرف المالك
    /// </summary>
    public Guid OwnerId { get; set; }
    
    /// <summary>
    /// تصنيف النجوم (1-5)
    /// </summary>
    public int StarRating { get; set; }
    
    /// <summary>
    /// متوسط التقييمات
    /// </summary>
    public decimal AverageRating { get; set; }
    
    /// <summary>
    /// حالة الموافقة على العقار
    /// </summary>
    public bool IsApproved { get; set; }
    
    /// <summary>
    /// هل العقار مميز (Featured)
    /// </summary>
    public bool IsFeatured { get; set; }
    
    /// <summary>
    /// عدد مشاهدات العقار
    /// </summary>
    public int PropertyViewCount { get; set; }
    
    /// <summary>
    /// عدد حجوزات العقار
    /// </summary>
    public int PropertyBookingCount { get; set; }
    
    #endregion
    
    #region === الموقع الجغرافي (Location) ===
    
    /// <summary>
    /// بيانات الموقع الجغرافي
    /// </summary>
    public LocationData Location { get; set; } = new();
    
    #endregion
    
    #region === الإتاحات (Availabilities) ===
    
    /// <summary>
    /// قائمة الإتاحات للفترة القادمة (12 شهر)
    /// تُستخدم للتحقق السريع من التوفر
    /// </summary>
    public List<AvailabilityData> Availabilities { get; set; } = new();
    
    /// <summary>
    /// جميع فترات الإتاحة (صريحة + ضمنية) - للفهرسة الشاملة
    /// يستخدم في الحل الأول لفهرسة جميع الفترات
    /// </summary>
    public List<PeriodData> AllPeriods { get; set; } = new();
    
    /// <summary>
    /// بيانات فهرسة الفترات - معلومات إحصائية عن الفترات المفهرسة
    /// </summary>
    public PeriodIndexingMetadata IndexingMetadata { get; set; } = new();
    
    #endregion
    
    #region === قواعد التسعير (Pricing Rules) ===
    
    /// <summary>
    /// قائمة قواعد التسعير النشطة
    /// </summary>
    public List<PricingRuleData> PricingRules { get; set; } = new();
    
    #endregion
    
    #region === نطاقات الأسعار المحسوبة (Price Ranges) ===
    
    /// <summary>
    /// نطاقات الأسعار للبحث السريع
    /// تُحسب مسبقاً لتسريع الفلترة السعرية
    /// </summary>
    public PriceRangesData PriceRanges { get; set; } = new();
    
    #endregion
    
    #region === الحقول الديناميكية (Dynamic Fields) ===
    
    /// <summary>
    /// قاموس الحقول الديناميكية القابلة للبحث
    /// Key: اسم الحقل (مثال: "area", "bedrooms")
    /// Value: بيانات الحقل
    /// </summary>
    public Dictionary<string, DynamicFieldData> DynamicFields { get; set; } = new();
    
    #endregion
    
    #region === المرافق (Amenities) ===
    
    /// <summary>
    /// قائمة المرافق المتوفرة في العقار
    /// </summary>
    public List<AmenityData> Amenities { get; set; } = new();
    
    #endregion
    
    #region === الخدمات (Services) ===
    
    /// <summary>
    /// قائمة الخدمات الإضافية المتاحة
    /// </summary>
    public List<ServiceData> Services { get; set; } = new();
    
    #endregion
    
    #region === الصور (Images) ===
    
    /// <summary>
    /// قائمة صور الوحدة والعقار
    /// </summary>
    public List<ImageData> Images { get; set; } = new();
    
    #endregion
    
    #region === ملخصات البحث (Search Summaries) ===
    
    /// <summary>
    /// ملخصات محسوبة مسبقاً لتسريع البحث
    /// </summary>
    public SearchSummaryData SearchSummary { get; set; } = new();
    
    #endregion
    
    #region === بيانات التحكم (Metadata) ===
    
    /// <summary>
    /// بيانات التحكم والإدارة
    /// </summary>
    public IndexMetadata Metadata { get; set; } = new();
    
    #endregion
}

#region === نماذج البيانات المساعدة (Helper Models) ===

/// <summary>
/// بيانات المبلغ المالي
/// </summary>
public class MoneyData
{
    /// <summary>
    /// المبلغ
    /// </summary>
    public decimal Amount { get; set; }
    
    /// <summary>
    /// العملة (SAR, USD, YER)
    /// </summary>
    public string Currency { get; set; } = "YER";
}

/// <summary>
/// بيانات الموقع الجغرافي
/// </summary>
public class LocationData
{
    /// <summary>
    /// العنوان الكامل
    /// </summary>
    public string Address { get; set; } = string.Empty;
    
    /// <summary>
    /// المدينة
    /// </summary>
    public string City { get; set; } = string.Empty;
    
    /// <summary>
    /// مرجع المدينة (FK)
    /// </summary>
    public string? CityRef { get; set; }
    
    /// <summary>
    /// خط العرض
    /// </summary>
    public decimal Latitude { get; set; }
    
    /// <summary>
    /// خط الطول
    /// </summary>
    public decimal Longitude { get; set; }
}

/// <summary>
/// بيانات الإتاحة
/// </summary>
public class AvailabilityData
{
    /// <summary>
    /// معرف الإتاحة
    /// </summary>
    public Guid Id { get; set; }
    
    /// <summary>
    /// تاريخ البداية
    /// </summary>
    public DateTime StartDate { get; set; }
    
    /// <summary>
    /// تاريخ النهاية
    /// </summary>
    public DateTime EndDate { get; set; }
    
    /// <summary>
    /// حالة الإتاحة: Available, Blocked, Booked
    /// </summary>
    public string Status { get; set; } = "Available";
    
    /// <summary>
    /// سبب الحظر (إن وجد)
    /// </summary>
    public string? Reason { get; set; }
    
    /// <summary>
    /// ملاحظات
    /// </summary>
    public string? Notes { get; set; }
    
    /// <summary>
    /// معرف الحجز (إذا كانت محجوزة)
    /// </summary>
    public Guid? BookingId { get; set; }
}

/// <summary>
/// بيانات قاعدة التسعير
/// </summary>
public class PricingRuleData
{
    /// <summary>
    /// معرف القاعدة
    /// </summary>
    public Guid Id { get; set; }
    
    /// <summary>
    /// تاريخ بداية القاعدة
    /// </summary>
    public DateTime StartDate { get; set; }
    
    /// <summary>
    /// تاريخ نهاية القاعدة
    /// </summary>
    public DateTime EndDate { get; set; }
    
    /// <summary>
    /// السعر الأساسي
    /// </summary>
    public decimal BasePrice { get; set; }
    
    /// <summary>
    /// سعر نهاية الأسبوع
    /// </summary>
    public decimal? WeekendPrice { get; set; }
    
    /// <summary>
    /// السعر الأسبوعي
    /// </summary>
    public decimal? WeeklyPrice { get; set; }
    
    /// <summary>
    /// السعر الشهري
    /// </summary>
    public decimal? MonthlyPrice { get; set; }
    
    /// <summary>
    /// نوع الموسم: peak, low, regular
    /// </summary>
    public string SeasonType { get; set; } = "regular";
    
    /// <summary>
    /// الحد الأدنى للإقامة (أيام)
    /// </summary>
    public int? MinimumStay { get; set; }
    
    /// <summary>
    /// الحد الأقصى للإقامة (أيام)
    /// </summary>
    public int? MaximumStay { get; set; }
    
    /// <summary>
    /// العملة
    /// </summary>
    public string Currency { get; set; } = "YER";
}

/// <summary>
/// نطاقات الأسعار المحسوبة للبحث السريع
/// </summary>
public class PriceRangesData
{
    /// <summary>
    /// نطاق السعر اليومي
    /// </summary>
    public PriceRange Daily { get; set; } = new();
    
    /// <summary>
    /// نطاق السعر الأسبوعي
    /// </summary>
    public PriceRange Weekly { get; set; } = new();
    
    /// <summary>
    /// نطاق السعر الشهري
    /// </summary>
    public PriceRange Monthly { get; set; } = new();
    
    /// <summary>
    /// متوسط السعر لليلة الواحدة
    /// </summary>
    public decimal AvgPerNight { get; set; }
}

/// <summary>
/// نطاق سعري (حد أدنى وأقصى)
/// </summary>
public class PriceRange
{
    /// <summary>
    /// الحد الأدنى
    /// </summary>
    public decimal Min { get; set; }
    
    /// <summary>
    /// الحد الأقصى
    /// </summary>
    public decimal Max { get; set; }
}

/// <summary>
/// بيانات الحقل الديناميكي
/// </summary>
public class DynamicFieldData
{
    /// <summary>
    /// معرف الحقل
    /// </summary>
    public Guid FieldId { get; set; }
    
    /// <summary>
    /// قيمة الحقل (نص دائماً، يتم تحويله حسب النوع عند الحاجة)
    /// </summary>
    public string Value { get; set; } = string.Empty;
    
    /// <summary>
    /// الاسم المعروض للحقل
    /// </summary>
    public string DisplayName { get; set; } = string.Empty;
    
    /// <summary>
    /// نوع الحقل: number, text, select, multi-select, textarea
    /// </summary>
    public string FieldType { get; set; } = "text";
    
    /// <summary>
    /// فئة الحقل: basic, location, amenities, features
    /// </summary>
    public string Category { get; set; } = "basic";
    
    /// <summary>
    /// هل الحقل قابل للبحث
    /// </summary>
    public bool IsSearchable { get; set; }
    
    /// <summary>
    /// هل الحقل فلتر أساسي (يظهر بشكل بارز في البحث)
    /// </summary>
    public bool IsPrimaryFilter { get; set; }
    
    /// <summary>
    /// هل يُعرض في بطاقات النتائج
    /// </summary>
    public bool ShowInCards { get; set; }
}

/// <summary>
/// بيانات المرفق
/// </summary>
public class AmenityData
{
    /// <summary>
    /// معرف المرفق
    /// </summary>
    public Guid AmenityId { get; set; }
    
    /// <summary>
    /// اسم المرفق
    /// مثال: "مسبح"، "موقف سيارات"، "واي فاي"
    /// </summary>
    public string AmenityName { get; set; } = string.Empty;
    
    /// <summary>
    /// فئة المرفق
    /// مثال: "أساسيات"، "ترفيه"، "تقنية"، "أمان"
    /// </summary>
    public string Category { get; set; } = string.Empty;
    
    /// <summary>
    /// أيقونة المرفق
    /// </summary>
    public string Icon { get; set; } = string.Empty;
    
    /// <summary>
    /// هل المرفق متوفر حالياً
    /// </summary>
    public bool IsAvailable { get; set; }
    
    /// <summary>
    /// التكلفة الإضافية (إن وجدت)
    /// </summary>
    public MoneyData? ExtraCost { get; set; }
}

/// <summary>
/// بيانات الخدمة
/// </summary>
public class ServiceData
{
    /// <summary>
    /// معرف الخدمة
    /// </summary>
    public Guid ServiceId { get; set; }
    
    /// <summary>
    /// اسم الخدمة
    /// مثال: "نقل من المطار"، "إفطار"
    /// </summary>
    public string ServiceName { get; set; } = string.Empty;
    
    /// <summary>
    /// وصف الخدمة
    /// </summary>
    public string Description { get; set; } = string.Empty;
    
    /// <summary>
    /// أيقونة الخدمة
    /// </summary>
    public string Icon { get; set; } = string.Empty;
    
    /// <summary>
    /// سعر الخدمة
    /// </summary>
    public MoneyData Price { get; set; } = new();
    
    /// <summary>
    /// نموذج التسعير: Fixed, PerPerson, PerNight
    /// </summary>
    public string PricingModel { get; set; } = "Fixed";
}

/// <summary>
/// بيانات الصورة
/// </summary>
public class ImageData
{
    /// <summary>
    /// معرف الصورة
    /// </summary>
    public Guid ImageId { get; set; }
    
    /// <summary>
    /// رابط الصورة
    /// </summary>
    public string Url { get; set; } = string.Empty;
    
    /// <summary>
    /// هل هي الصورة الرئيسية
    /// </summary>
    public bool IsPrimary { get; set; }
    
    /// <summary>
    /// فئة الصورة: unit, property, amenity
    /// </summary>
    public string Category { get; set; } = "unit";
}

/// <summary>
/// ملخصات البحث المحسوبة مسبقاً
/// </summary>
public class SearchSummaryData
{
    /// <summary>
    /// ملخص الإتاحة
    /// </summary>
    public AvailabilitySummary AvailabilitySummary { get; set; } = new();
    
    /// <summary>
    /// ملخص المرافق
    /// </summary>
    public AmenitiesSummary AmenitiesSummary { get; set; } = new();
    
    /// <summary>
    /// ملخص الخدمات
    /// </summary>
    public ServicesSummary ServicesSummary { get; set; } = new();
    
    /// <summary>
    /// كلمات مفتاحية للبحث النصي
    /// </summary>
    public List<string> SearchKeywords { get; set; } = new();
}

/// <summary>
/// ملخص الإتاحة
/// </summary>
public class AvailabilitySummary
{
    /// <summary>
    /// تاريخ أول يوم متاح
    /// </summary>
    public DateTime? NextAvailableDate { get; set; }
    
    /// <summary>
    /// إجمالي الأيام المتاحة في الفترة القادمة
    /// </summary>
    public int TotalAvailableDays { get; set; }
    
    /// <summary>
    /// هل الوحدة متاحة حالياً
    /// </summary>
    public bool IsCurrentlyAvailable { get; set; }
    
    /// <summary>
    /// قائمة التواريخ المحجوزة/المحظورة
    /// </summary>
    public List<string> BlockedDates { get; set; } = new();
}

/// <summary>
/// ملخص المرافق
/// </summary>
public class AmenitiesSummary
{
    /// <summary>
    /// إجمالي عدد المرافق
    /// </summary>
    public int TotalAmenities { get; set; }
    
    /// <summary>
    /// عدد المرافق المجانية
    /// </summary>
    public int FreeAmenities { get; set; }
    
    /// <summary>
    /// عدد المرافق المدفوعة
    /// </summary>
    public int PaidAmenities { get; set; }
    
    /// <summary>
    /// قائمة فئات المرافق المتوفرة
    /// </summary>
    public List<string> Categories { get; set; } = new();
}

/// <summary>
/// ملخص الخدمات
/// </summary>
public class ServicesSummary
{
    /// <summary>
    /// إجمالي عدد الخدمات
    /// </summary>
    public int TotalServices { get; set; }
    
    /// <summary>
    /// عدد الخدمات المجانية
    /// </summary>
    public int FreeServices { get; set; }
    
    /// <summary>
    /// عدد الخدمات المدفوعة
    /// </summary>
    public int PaidServices { get; set; }
    
    /// <summary>
    /// التكلفة الإجمالية للخدمات
    /// </summary>
    public decimal TotalServicesCost { get; set; }
}

/// <summary>
/// بيانات التحكم والإدارة
/// </summary>
public class IndexMetadata
{
    /// <summary>
    /// تاريخ الفهرسة
    /// </summary>
    public DateTime IndexedAt { get; set; }
    
    /// <summary>
    /// تاريخ آخر تحديث
    /// </summary>
    public DateTime LastUpdated { get; set; }
    
    /// <summary>
    /// رقم النسخة
    /// </summary>
    public int Version { get; set; }
    
    /// <summary>
    /// هل تم فهرسة المستند
    /// </summary>
    public bool IsIndexed { get; set; }
}

/// <summary>
/// بيانات الفترة - محسّنة لفهرسة شاملة
/// تستخدم في الحل الأول لفهرسة جميع الفترات
/// </summary>
public class PeriodData
{
    /// <summary>
    /// معرف الفترة (للفترات الصريحة)
    /// </summary>
    public Guid? Id { get; set; }
    
    /// <summary>
    /// تاريخ البداية
    /// </summary>
    public DateTime StartDate { get; set; }
    
    /// <summary>
    /// تاريخ النهاية
    /// </summary>
    public DateTime EndDate { get; set; }
    
    /// <summary>
    /// حالة الفترة: available, booked, blocked, maintenance
    /// </summary>
    public string Status { get; set; } = "available";
    
    /// <summary>
    /// سبب الحظر (إن وجد)
    /// </summary>
    public string? Reason { get; set; }
    
    /// <summary>
    /// ملاحظات
    /// </summary>
    public string? Notes { get; set; }
    
    /// <summary>
    /// معرف الحجز (إذا كانت محجوزة)
    /// </summary>
    public Guid? BookingId { get; set; }
    
    /// <summary>
    /// هل هذه فترة ضمنية (غير موجودة في قاعدة البيانات)
    /// </summary>
    public bool IsImplicit { get; set; }
    
    /// <summary>
    /// طابع زمني لبداية الفترة (للفهرسة في RediSearch)
    /// </summary>
    public long StartTimestamp => new DateTimeOffset(StartDate).ToUnixTimeSeconds();
    
    /// <summary>
    /// طابع زمني لنهاية الفترة (للفهرسة في RediSearch)
    /// </summary>
    public long EndTimestamp => new DateTimeOffset(EndDate).ToUnixTimeSeconds();
    
    /// <summary>
    /// مدة الفترة بالأيام
    /// </summary>
    public int DurationDays => (EndDate - StartDate).Days;
}

/// <summary>
/// بيانات فهرسة الفترات - معلومات إحصائية
/// </summary>
public class PeriodIndexingMetadata
{
    /// <summary>
    /// إجمالي عدد الفترات
    /// </summary>
    public int TotalPeriods { get; set; }
    
    /// <summary>
    /// عدد الفترات المفهرسة في RediSearch
    /// </summary>
    public int IndexedPeriodsCount { get; set; }
    
    /// <summary>
    /// هل هناك فترات إضافية لم تُفهرس
    /// </summary>
    public bool HasMorePeriods { get; set; }
    
    /// <summary>
    /// تاريخ آخر فهرسة
    /// </summary>
    public DateTime LastIndexedAt { get; set; }
    
    /// <summary>
    /// عدد الفترات الضمنية
    /// </summary>
    public int ImplicitPeriodsCount { get; set; }
    
    /// <summary>
    /// عدد الفترات الصريحة
    /// </summary>
    public int ExplicitPeriodsCount { get; set; }
}

#endregion
