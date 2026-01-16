using System;
using System.Collections.Generic;
using YemenBooking.Core.Indexing.Enums;

namespace YemenBooking.Core.Indexing.Models;

/// <summary>
/// طلب البحث عن الوحدات
/// يحتوي على جميع معايير البحث والفلترة الممكنة
/// 
/// استراتيجية البحث:
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// المرحلة 1 - الفلترة الأساسية (Primary Filters):
///   • City (المدينة) - فهرس ثانوي
///   • UnitTypeId (نوع الوحدة) - فهرس ثانوي
///   • PropertyTypeId (نوع العقار) - فهرس ثانوي
///   • CheckIn/CheckOut (التواريخ) - فحص bitmap الإتاحة
/// 
/// المرحلة 2 - الفلترة التفصيلية (Secondary Filters):
///   • PriceRange (نطاق السعر) - فهرس ثانوي ZSET
///   • MinRating (التقييم) - فهرس ثانوي ZSET
///   • RequiredAmenities (المرافق) - فهرس ثانوي SET
///   • GuestsCount (عدد الضيوف) - فحص MaxCapacity في JSON
///   • DynamicFields (الحقول الديناميكية) - فحص في JSON
/// 
/// المرحلة 3 - البحث النصي (Text Search):
///   • SearchText - فهرس نصي للكلمات المفتاحية
/// 
/// المرحلة 4 - البحث الجغرافي (Geographic Search):
///   • Latitude/Longitude/RadiusKm - فهرس GEO
/// 
/// المرحلة 5 - الترتيب (Sorting):
///   • SortBy: price_asc, price_desc, rating, distance, newest
/// </summary>
public class UnitSearchRequest
{
    #region === معايير البحث الأساسية (Primary Criteria) ===
    
    /// <summary>
    /// نص البحث الحر
    /// يُبحث في: اسم العقار، اسم الوحدة، الوصف، الكلمات المفتاحية
    /// </summary>
    public string? SearchText { get; set; }
    
    /// <summary>
    /// المدينة
    /// </summary>
    public string? City { get; set; }
    
    /// <summary>
    /// معرف نوع الوحدة
    /// مثال: جناح، غرفة، شقة
    /// </summary>
    public Guid? UnitTypeId { get; set; }
    
    /// <summary>
    /// معرف نوع العقار
    /// مثال: فندق، منتجع، شقة فندقية
    /// </summary>
    public Guid? PropertyTypeId { get; set; }
    
    /// <summary>
    /// تاريخ الوصول
    /// </summary>
    public DateTime? CheckIn { get; set; }
    
    /// <summary>
    /// تاريخ المغادرة
    /// </summary>
    public DateTime? CheckOut { get; set; }
    
    #endregion
    
    #region === معايير السعر (Price Criteria) ===
    
    /// <summary>
    /// الحد الأدنى للسعر
    /// </summary>
    public decimal? MinPrice { get; set; }
    
    /// <summary>
    /// الحد الأقصى للسعر
    /// </summary>
    public decimal? MaxPrice { get; set; }
    
    /// <summary>
    /// العملة المفضلة للعرض
    /// </summary>
    public string? PreferredCurrency { get; set; }
    
    #endregion
    
    #region === معايير التقييم والجودة (Rating & Quality) ===
    
    /// <summary>
    /// الحد الأدنى لمتوسط التقييم (0-5)
    /// </summary>
    public decimal? MinRating { get; set; }
    
    /// <summary>
    /// الحد الأدنى لتصنيف النجوم (1-5)
    /// </summary>
    public int? MinStarRating { get; set; }
    
    /// <summary>
    /// عرض العقارات المميزة فقط
    /// </summary>
    public bool? FeaturedOnly { get; set; }
    
    #endregion
    
    #region === معايير السعة (Capacity Criteria) ===
    
    /// <summary>
    /// إجمالي عدد الضيوف
    /// </summary>
    public int? GuestsCount { get; set; }
    
    /// <summary>
    /// عدد البالغين
    /// </summary>
    public int? AdultsCount { get; set; }
    
    /// <summary>
    /// عدد الأطفال
    /// </summary>
    public int? ChildrenCount { get; set; }
    
    #endregion
    
    #region === المرافق والخدمات (Amenities & Services) ===
    
    /// <summary>
    /// قائمة معرفات المرافق المطلوبة (جميعها إلزامية - AND)
    /// </summary>
    public List<Guid>? RequiredAmenities { get; set; }
    
    /// <summary>
    /// قائمة معرفات الخدمات المطلوبة
    /// </summary>
    public List<Guid>? RequiredServices { get; set; }
    
    #endregion
    
    #region === الحقول الديناميكية (Dynamic Fields) ===
    
    /// <summary>
    /// فلاتر الحقول الديناميكية
    /// Key: اسم الحقل
    /// Value: القيمة أو النمط (مثال: "50..100" للنطاق، "~نص" للبحث النصي)
    /// 
    /// أمثلة:
    /// • "area" → "50..150" (نطاق رقمي)
    /// • "bedrooms" → "2" (تطابق تام)
    /// • "view" → "بحر" (تطابق تام)
    /// • "description" → "~إطلالة رائعة" (بحث نصي)
    /// </summary>
    public Dictionary<string, string>? DynamicFieldFilters { get; set; }
    
    #endregion
    
    #region === البحث الجغرافي (Geographic Search) ===
    
    /// <summary>
    /// خط العرض (للبحث بالقرب)
    /// </summary>
    public decimal? Latitude { get; set; }
    
    /// <summary>
    /// خط الطول (للبحث بالقرب)
    /// </summary>
    public decimal? Longitude { get; set; }
    
    /// <summary>
    /// نصف القطر بالكيلومتر
    /// </summary>
    public double? RadiusKm { get; set; }
    
    #endregion
    
    #region === الترتيب والصفحات (Sorting & Pagination) ===
    
    /// <summary>
    /// نوع الترتيب:
    /// • "price_asc" - السعر من الأقل للأعلى
    /// • "price_desc" - السعر من الأعلى للأقل
    /// • "rating" - التقييم من الأعلى للأقل
    /// • "distance" - المسافة من الأقرب للأبعد (يتطلب Lat/Lng)
    /// • "newest" - الأحدث أولاً
    /// • "popular" - الأكثر شعبية
    /// • "relevance" - الملاءمة (افتراضي)
    /// </summary>
    public string? SortBy { get; set; }
    
    /// <summary>
    /// رقم الصفحة (يبدأ من 1)
    /// </summary>
    public int PageNumber { get; set; } = 1;
    
    /// <summary>
    /// حجم الصفحة
    /// </summary>
    public int PageSize { get; set; } = 20;
    
    #endregion
}

/// <summary>
/// نتيجة البحث عن الوحدات
/// </summary>
public class UnitSearchResult
{
    /// <summary>
    /// قائمة الوحدات المطابقة
    /// </summary>
    public List<UnitSearchItem> Units { get; set; } = new();
    
    /// <summary>
    /// إجمالي عدد النتائج (قبل التصفح)
    /// </summary>
    public int TotalCount { get; set; }
    
    /// <summary>
    /// رقم الصفحة الحالية
    /// </summary>
    public int PageNumber { get; set; }
    
    /// <summary>
    /// حجم الصفحة
    /// </summary>
    public int PageSize { get; set; }
    
    /// <summary>
    /// إجمالي عدد الصفحات
    /// </summary>
    public int TotalPages { get; set; }
    
    /// <summary>
    /// وقت البحث بالميلي ثانية
    /// </summary>
    public long SearchTimeMs { get; set; }
    
    /// <summary>
    /// المعايير المطبقة (للتوضيح للمستخدم)
    /// </summary>
    public Dictionary<string, string> AppliedFilters { get; set; } = new();

    #region === معلومات استراتيجية التخفيف (Fallback Strategy Info) ===

    /// <summary>
    /// مستوى التخفيف المطبق
    /// Applied relaxation level
    /// </summary>
    public SearchRelaxationLevel RelaxationLevel { get; set; } = SearchRelaxationLevel.Exact;

    /// <summary>
    /// قائمة الفلاتر التي تم تخفيفها
    /// List of relaxed filters
    /// </summary>
    public List<string> RelaxedFilters { get; set; } = new();

    /// <summary>
    /// استراتيجية البحث المطبقة
    /// Applied search strategy
    /// </summary>
    public string SearchStrategy { get; set; } = "تطابق دقيق";

    /// <summary>
    /// المعايير الأصلية (قبل التخفيف)
    /// Original criteria (before relaxation)
    /// </summary>
    public Dictionary<string, object> OriginalCriteria { get; set; } = new();

    /// <summary>
    /// المعايير الفعلية (بعد التخفيف)
    /// Actual criteria (after relaxation)
    /// </summary>
    public Dictionary<string, object> ActualCriteria { get; set; } = new();

    /// <summary>
    /// رسالة للمستخدم توضح التخفيف المطبق
    /// User message explaining applied relaxation
    /// </summary>
    public string? UserMessage { get; set; }

    /// <summary>
    /// اقتراحات لتحسين البحث
    /// Suggestions to improve search
    /// </summary>
    public List<string>? SuggestedActions { get; set; }

    #endregion
}

/// <summary>
/// عنصر نتيجة البحث - يمثل وحدة واحدة
/// يحتوي على البيانات الأساسية للعرض في النتائج
/// </summary>
public class UnitSearchItem
{
    #region === معلومات الوحدة (Unit Info) ===
    
    /// <summary>
    /// معرف الوحدة
    /// </summary>
    public Guid UnitId { get; set; }
    
    /// <summary>
    /// اسم الوحدة
    /// </summary>
    public string UnitName { get; set; } = string.Empty;
    
    /// <summary>
    /// نوع الوحدة
    /// </summary>
    public string UnitTypeName { get; set; } = string.Empty;
    
    /// <summary>
    /// السعر الأساسي (لليلة/الساعة حسب PricingMethod)
    /// </summary>
    public decimal BasePrice { get; set; }
    
    /// <summary>
    /// العملة
    /// </summary>
    public string Currency { get; set; } = "YER";
    
    /// <summary>
    /// السعة القصوى
    /// </summary>
    public int MaxCapacity { get; set; }
    
    // ملاحظة: تم حذف IsAvailable - نعتمد على DailySchedules
    
    /// <summary>
    /// طريقة التسعير
    /// </summary>
    public string PricingMethod { get; set; } = "Daily";
    
    #endregion
    
    #region === معلومات العقار (Property Info) ===
    
    /// <summary>
    /// معرف العقار
    /// </summary>
    public Guid PropertyId { get; set; }
    
    /// <summary>
    /// اسم العقار
    /// </summary>
    public string PropertyName { get; set; } = string.Empty;
    
    /// <summary>
    /// نوع العقار
    /// </summary>
    public string PropertyTypeName { get; set; } = string.Empty;
    
    /// <summary>
    /// المدينة
    /// </summary>
    public string City { get; set; } = string.Empty;
    
    /// <summary>
    /// العنوان
    /// </summary>
    public string Address { get; set; } = string.Empty;
    
    /// <summary>
    /// تصنيف النجوم
    /// </summary>
    public int StarRating { get; set; }
    
    /// <summary>
    /// متوسط التقييم
    /// </summary>
    public decimal AverageRating { get; set; }
    
    /// <summary>
    /// هل العقار مميز
    /// </summary>
    public bool IsFeatured { get; set; }
    
    /// <summary>
    /// معرف المالك (للفلترة الأمنية)
    /// </summary>
    public Guid OwnerId { get; set; }
    
    /// <summary>
    /// هل العقار معتمد (للفلترة الأمنية)
    /// </summary>
    public bool IsApproved { get; set; }
    
    /// <summary>
    /// خط العرض
    /// </summary>
    public decimal Latitude { get; set; }
    
    /// <summary>
    /// خط الطول
    /// </summary>
    public decimal Longitude { get; set; }
    
    #endregion
    
    #region === معلومات محسوبة (Calculated Info) ===
    
    /// <summary>
    /// المسافة بالكيلومتر (إذا كان بحث جغرافي)
    /// </summary>
    public double? DistanceKm { get; set; }
    
    /// <summary>
    /// السعر الإجمالي للفترة المحددة (إذا كانت CheckIn/CheckOut موجودة)
    /// </summary>
    public decimal? TotalPrice { get; set; }
    
    /// <summary>
    /// عدد الليالي (إذا كانت CheckIn/CheckOut موجودة)
    /// </summary>
    public int? NumberOfNights { get; set; }
    
    /// <summary>
    /// نقاط الملاءمة (0-100) بناءً على مطابقة المعايير
    /// </summary>
    public decimal RelevanceScore { get; set; }
    
    #endregion
    
    #region === ملخصات للعرض (Display Summaries) ===
    
    /// <summary>
    /// الصورة الرئيسية
    /// </summary>
    public string? MainImageUrl { get; set; }
    
    /// <summary>
    /// قائمة الصور (محدودة)
    /// </summary>
    public List<string> ImageUrls { get; set; } = new();
    
    /// <summary>
    /// ملخص المرافق الرئيسية (3-5 مرافق مهمة)
    /// </summary>
    public List<string> MainAmenities { get; set; } = new();
    
    /// <summary>
    /// ملخص الحقول الديناميكية المهمة (للعرض في البطاقة)
    /// Key: DisplayName
    /// Value: Value
    /// </summary>
    public Dictionary<string, string> DisplayFields { get; set; } = new();
    
    /// <summary>
    /// أقرب تاريخ متاح (إذا كانت الوحدة محجوزة حالياً)
    /// </summary>
    public DateTime? NextAvailableDate { get; set; }
    
    #endregion
}

/// <summary>
/// طلب البحث المجمع (للبحث على مستوى العقار وإرجاع وحداته)
/// يُستخدم عندما نريد عرض العقارات مع وحداتها المتاحة
/// </summary>
public class PropertyWithUnitsSearchRequest : UnitSearchRequest
{
    /// <summary>
    /// تجميع النتائج حسب العقار
    /// إذا true: يتم إرجاع PropertySearchItem مع قائمة الوحدات
    /// إذا false: يتم إرجاع قائمة مسطحة من UnitSearchItem
    /// </summary>
    public bool GroupByProperty { get; set; } = false;
    
    /// <summary>
    /// الحد الأقصى لعدد الوحدات المعروضة لكل عقار
    /// null = جميع الوحدات المطابقة
    /// </summary>
    public int? MaxUnitsPerProperty { get; set; }
}

/// <summary>
/// نتيجة بحث العقارات مع الوحدات
/// يُستخدم عند GroupByProperty = true
/// </summary>
public class PropertyWithUnitsSearchResult
{
    /// <summary>
    /// قائمة العقارات مع وحداتها المطابقة
    /// </summary>
    public List<PropertyGroupSearchItem> Properties { get; set; } = new();
    
    /// <summary>
    /// إجمالي عدد العقارات
    /// </summary>
    public int TotalPropertiesCount { get; set; }
    
    /// <summary>
    /// إجمالي عدد الوحدات المطابقة
    /// </summary>
    public int TotalUnitsCount { get; set; }
    
    /// <summary>
    /// رقم الصفحة الحالية
    /// </summary>
    public int PageNumber { get; set; }
    
    /// <summary>
    /// حجم الصفحة
    /// </summary>
    public int PageSize { get; set; }
    
    /// <summary>
    /// إجمالي عدد الصفحات
    /// </summary>
    public int TotalPages { get; set; }
    
    /// <summary>
    /// وقت البحث بالميلي ثانية
    /// </summary>
    public long SearchTimeMs { get; set; }

    #region === معلومات استراتيجية التخفيف (Fallback Strategy Info) ===

    /// <summary>
    /// مستوى التخفيف المطبق
    /// Applied relaxation level
    /// </summary>
    public SearchRelaxationLevel RelaxationLevel { get; set; } = SearchRelaxationLevel.Exact;

    /// <summary>
    /// قائمة الفلاتر التي تم تخفيفها
    /// List of relaxed filters
    /// </summary>
    public List<string> RelaxedFilters { get; set; } = new();

    /// <summary>
    /// استراتيجية البحث المطبقة
    /// Applied search strategy
    /// </summary>
    public string SearchStrategy { get; set; } = "تطابق دقيق";

    /// <summary>
    /// المعايير الأصلية (قبل التخفيف)
    /// Original criteria (before relaxation)
    /// </summary>
    public Dictionary<string, object> OriginalCriteria { get; set; } = new();

    /// <summary>
    /// المعايير الفعلية (بعد التخفيف)
    /// Actual criteria (after relaxation)
    /// </summary>
    public Dictionary<string, object> ActualCriteria { get; set; } = new();

    /// <summary>
    /// رسالة للمستخدم توضح التخفيف المطبق
    /// User message explaining applied relaxation
    /// </summary>
    public string? UserMessage { get; set; }

    /// <summary>
    /// اقتراحات لتحسين البحث
    /// Suggestions to improve search
    /// </summary>
    public List<string>? SuggestedActions { get; set; }

    #endregion
}

/// <summary>
/// عنصر عقار في نتائج البحث المجمعة
/// يحتوي على معلومات العقار + قائمة الوحدات المطابقة
/// </summary>
public class PropertyGroupSearchItem
{
    #region === معلومات العقار (Property Info) ===
    
    /// <summary>
    /// معرف العقار
    /// </summary>
    public Guid PropertyId { get; set; }
    
    /// <summary>
    /// اسم العقار
    /// </summary>
    public string PropertyName { get; set; } = string.Empty;
    
    /// <summary>
    /// نوع العقار
    /// </summary>
    public string PropertyTypeName { get; set; } = string.Empty;
    
    /// <summary>
    /// المدينة
    /// </summary>
    public string City { get; set; } = string.Empty;
    
    /// <summary>
    /// العنوان
    /// </summary>
    public string Address { get; set; } = string.Empty;
    
    /// <summary>
    /// تصنيف النجوم
    /// </summary>
    public int StarRating { get; set; }
    
    /// <summary>
    /// متوسط التقييم
    /// </summary>
    public decimal AverageRating { get; set; }
    
    /// <summary>
    /// هل العقار مميز
    /// </summary>
    public bool IsFeatured { get; set; }
    
    /// <summary>
    /// معرف المالك (للفلترة الأمنية)
    /// </summary>
    public Guid OwnerId { get; set; }
    
    /// <summary>
    /// هل العقار معتمد (للفلترة الأمنية)
    /// </summary>
    public bool IsApproved { get; set; }
    
    /// <summary>
    /// خط العرض
    /// </summary>
    public decimal Latitude { get; set; }
    
    /// <summary>
    /// خط الطول
    /// </summary>
    public decimal Longitude { get; set; }
    
    /// <summary>
    /// المسافة بالكيلومتر (إذا كان بحث جغرافي)
    /// </summary>
    public double? DistanceKm { get; set; }
    
    /// <summary>
    /// أقل سعر من بين الوحدات المطابقة
    /// </summary>
    public decimal MinPrice { get; set; }
    
    /// <summary>
    /// أعلى سعر من بين الوحدات المطابقة
    /// </summary>
    public decimal MaxPrice { get; set; }
    
    #endregion
    
    #region === الوحدات المطابقة (Matched Units) ===
    
    /// <summary>
    /// قائمة الوحدات المطابقة في هذا العقار
    /// </summary>
    public List<UnitSearchItem> MatchedUnits { get; set; } = new();
    
    /// <summary>
    /// إجمالي عدد الوحدات المطابقة
    /// </summary>
    public int MatchedUnitsCount { get; set; }
    
    /// <summary>
    /// نطاق الأسعار للوحدات المطابقة
    /// </summary>
    public PriceRange PriceRange { get; set; } = new();
    
    #endregion
    
    #region === ملخصات للعرض (Display Summaries) ===
    
    /// <summary>
    /// الصورة الرئيسية للعقار
    /// </summary>
    public string? MainImageUrl { get; set; }
    
    /// <summary>
    /// قائمة الصور
    /// </summary>
    public List<string> ImageUrls { get; set; } = new();
    
    /// <summary>
    /// ملخص المرافق المتوفرة
    /// </summary>
    public List<string> AvailableAmenities { get; set; } = new();
    
    #endregion
    
    #region === الفروقات مع معايير البحث (Search Criteria Mismatches) ===
    
    /// <summary>
    /// قائمة الفروقات بين المعايير المطلوبة وخصائص هذا العقار
    /// List of mismatches between requested criteria and this property
    /// </summary>
    public List<PropertyFilterMismatch> FilterMismatches { get; set; } = new();
    
    /// <summary>
    /// هل توجد فروقات؟
    /// Are there any mismatches?
    /// </summary>
    public bool HasMismatches => FilterMismatches.Any();
    
    /// <summary>
    /// عدد الفروقات
    /// Number of mismatches
    /// </summary>
    public int MismatchesCount => FilterMismatches.Count;
    
    #endregion
}

/// <summary>
/// معايير البحث المتقدمة (للاستخدام الداخلي)
/// </summary>
public class InternalSearchCriteria
{
    /// <summary>
    /// قائمة معرفات الوحدات من المرحلة السابقة
    /// </summary>
    public List<string> UnitIds { get; set; } = new();
    
    /// <summary>
    /// هل تم تطبيق فلتر التواريخ
    /// </summary>
    public bool DateFilterApplied { get; set; }
    
    /// <summary>
    /// هل تم تطبيق فلتر السعر
    /// </summary>
    public bool PriceFilterApplied { get; set; }
    
    /// <summary>
    /// عدد الفلاتر المطبقة
    /// </summary>
    public int FiltersAppliedCount { get; set; }
}
