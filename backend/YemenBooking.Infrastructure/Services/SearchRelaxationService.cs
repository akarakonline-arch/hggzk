using System.Text.Json;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Indexing.Enums;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Core.Indexing.Options;

namespace YemenBooking.Infrastructure.Services;

/// <summary>
/// خدمة تخفيف معايير البحث التدريجية
/// Search Relaxation Service Implementation
/// 
/// تطبق استراتيجية تخفيف تدريجي لمعايير البحث عندما لا توجد نتائج مطابقة
/// Applies progressive relaxation strategy to search criteria when no exact matches found
/// </summary>
public class SearchRelaxationService : ISearchRelaxationService
{
    private readonly ILogger<SearchRelaxationService> _logger;

    // قاموس المدن اليمنية المجاورة
    private static readonly Dictionary<string, List<string>> YemeniCityGroups = new()
    {
        ["صنعاء"] = new() { "صنعاء", "أمانة العاصمة", "صنعاء القديمة", "الروضة", "شعوب" },
        ["عدن"] = new() { "عدن", "كريتر", "الشيخ عثمان", "المنصورة", "خور مكسر", "التواهي" },
        ["تعز"] = new() { "تعز", "الحوبان", "التربة", "المخاء", "الصلو" },
        ["الحديدة"] = new() { "الحديدة", "باجل", "زبيد", "اللحية", "الخوخة" },
        ["إب"] = new() { "إب", "جبلة", "يريم", "ذي السفال", "العدين" },
        ["ذمار"] = new() { "ذمار", "عنس", "معبر", "وصاب السافل" },
        ["المكلا"] = new() { "المكلا", "الشحر", "غيل باوزير" },
        ["مأرب"] = new() { "مأرب", "الوادي", "جوبة" },
        ["صعدة"] = new() { "صعدة", "حيدان", "البقع" },
        ["حجة"] = new() { "حجة", "حرض", "عبس" },
        ["عمران"] = new() { "عمران", "خمر", "ثلا" },
        ["لحج"] = new() { "لحج", "الحوطة", "تبن", "يافع" }
    };

    public SearchRelaxationService(ILogger<SearchRelaxationService> logger)
    {
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }

    #region === Main Methods ===

    /// <summary>
    /// تطبيق التخفيف على معايير البحث
    /// Apply relaxation to search criteria
    /// </summary>
    public UnitSearchRequest RelaxSearchCriteria(
        UnitSearchRequest originalRequest,
        SearchRelaxationLevel level,
        FallbackSearchOptions options,
        out List<string> relaxedFilters)
    {
        relaxedFilters = new List<string>();

        // نسخ الطلب الأصلي
        var relaxedRequest = CloneRequest(originalRequest);

        // تطبيق التخفيف حسب المستوى
        switch (level)
        {
            case SearchRelaxationLevel.MinorRelaxation:
                if (options.EnableMinorRelaxation)
                    ApplyMinorRelaxation(relaxedRequest, options, relaxedFilters);
                break;

            case SearchRelaxationLevel.ModerateRelaxation:
                if (options.EnableModerateRelaxation)
                    ApplyModerateRelaxation(relaxedRequest, options, relaxedFilters);
                break;

            case SearchRelaxationLevel.MajorRelaxation:
                if (options.EnableMajorRelaxation)
                    ApplyMajorRelaxation(relaxedRequest, options, relaxedFilters);
                break;

            case SearchRelaxationLevel.AlternativeSuggestions:
                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                // Validation: التحقق من وجود معايير أساسية كافية للتخفيف
                // Check for minimum criteria before applying alternative strategy
                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                if (!HasMinimumCriteria(originalRequest))
                {
                    _logger.LogWarning(
                        "⚠️ لا توجد معايير كافية للتخفيف إلى Alternative - إرجاع الطلب الأصلي");
                    return originalRequest; // بدون تعديل
                }
                
                if (options.EnableAlternativeSuggestions)
                    ApplyAlternativeStrategy(relaxedRequest, originalRequest, relaxedFilters);
                break;

            default:
                // Exact - لا تعديلات
                break;
        }

        if (options.LogRelaxationSteps && relaxedFilters.Any())
        {
            _logger.LogInformation(
                "📊 تم تخفيف {Count} فلتر في المستوى {Level}: {Filters}",
                relaxedFilters.Count, level, string.Join(", ", relaxedFilters));
        }

        return relaxedRequest;
    }

    /// <summary>
    /// استخراج المعايير من طلب البحث
    /// Extract criteria from search request
    /// </summary>
    public Dictionary<string, object> ExtractCriteria(UnitSearchRequest request)
    {
        var criteria = new Dictionary<string, object>();

        if (!string.IsNullOrWhiteSpace(request.SearchText))
            criteria["نص البحث"] = request.SearchText;

        if (!string.IsNullOrWhiteSpace(request.City))
            criteria["المدينة"] = request.City;

        if (request.UnitTypeId.HasValue)
            criteria["نوع الوحدة"] = request.UnitTypeId.Value;

        if (request.PropertyTypeId.HasValue)
            criteria["نوع العقار"] = request.PropertyTypeId.Value;

        if (request.CheckIn.HasValue)
            criteria["تاريخ الوصول"] = request.CheckIn.Value.ToString("yyyy-MM-dd");

        if (request.CheckOut.HasValue)
            criteria["تاريخ المغادرة"] = request.CheckOut.Value.ToString("yyyy-MM-dd");

        if (request.MinPrice.HasValue)
            criteria["الحد الأدنى للسعر"] = $"{request.MinPrice:N0} {request.PreferredCurrency ?? "YER"}";

        if (request.MaxPrice.HasValue)
            criteria["الحد الأقصى للسعر"] = $"{request.MaxPrice:N0} {request.PreferredCurrency ?? "YER"}";

        if (request.GuestsCount.HasValue)
            criteria["عدد الضيوف"] = request.GuestsCount.Value;

        if (request.MinRating.HasValue)
            criteria["الحد الأدنى للتقييم"] = $"{request.MinRating:F1} نجمة";

        if (request.MinStarRating.HasValue)
            criteria["تصنيف النجوم"] = $"{request.MinStarRating} نجوم";

        if (request.RequiredAmenities?.Any() == true)
            criteria["المرافق المطلوبة"] = $"{request.RequiredAmenities.Count} مرفق";

        if (request.RadiusKm.HasValue && request.Latitude.HasValue && request.Longitude.HasValue)
            criteria["النطاق الجغرافي"] = $"{request.RadiusKm:F1} كم";

        if (request.DynamicFieldFilters?.Any() == true)
            criteria["حقول إضافية"] = $"{request.DynamicFieldFilters.Count} حقل";

        return criteria;
    }

    /// <summary>
    /// نسخ عميق لطلب البحث باستخدام JSON
    /// Deep clone using JSON serialization
    /// 
    /// ✅ يدعم الأنواع المشتقة (PropertyWithUnitsSearchRequest)
    /// ✅ Supports derived types (PropertyWithUnitsSearchRequest)
    /// </summary>
    public UnitSearchRequest CloneRequest(UnitSearchRequest original)
    {
        try
        {
            // ✅ استخدام النوع الفعلي بدلاً من UnitSearchRequest المباشر
            // Use actual runtime type instead of hardcoded UnitSearchRequest
            var originalType = original.GetType();
            var json = JsonSerializer.Serialize(original, originalType);
            
            return (UnitSearchRequest)JsonSerializer.Deserialize(json, originalType)
                   ?? throw new InvalidOperationException("Failed to clone request");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ فشل نسخ طلب البحث، إرجاع الأصلي");
            return original;
        }
    }

    #endregion

    #region === Minor Relaxation (15-20%) ===

    private void ApplyMinorRelaxation(
        UnitSearchRequest request,
        FallbackSearchOptions options,
        List<string> relaxedFilters)
    {
        // 1. توسيع نطاق السعر (+/- 15%)
        RelaxPrice(request, options.PriceRelaxationMinor, relaxedFilters);

        // 2. تقليل المرافق المطلوبة إلى النصف
        RelaxAmenities(request, options.AmenitiesRetentionRatio, relaxedFilters);

        // 3. تخفيف فلتر التقييم
        RelaxRating(request, options.RatingReduction, relaxedFilters);

        // 4. إزالة الحقول الديناميكية غير الحرجة
        RelaxDynamicFields(request, keepCriticalOnly: true, relaxedFilters);
    }

    #endregion

    #region === Moderate Relaxation (30-40%) ===

    private void ApplyModerateRelaxation(
        UnitSearchRequest request,
        FallbackSearchOptions options,
        List<string> relaxedFilters)
    {
        // تطبيق التخفيف البسيط أولاً
        ApplyMinorRelaxation(request, options, relaxedFilters);

        // 5. توسيع نطاق السعر أكثر (+/- 30%)
        RelaxPrice(request, options.PriceRelaxationModerate, relaxedFilters, forceUpdate: true);

        // 6. توسيع النطاق الجغرافي
        RelaxGeographicRadius(request, options.RadiusMultiplierModerate, relaxedFilters);

        // 7. إضافة المدن المجاورة
        AddNearbyCities(request, relaxedFilters);

        // 8. تخفيف شرط السعة
        RelaxGuestsCount(request, options.GuestsCountReduction, relaxedFilters);

        // 9. إلغاء فلتر تصنيف النجوم
        if (request.MinStarRating.HasValue)
        {
            request.MinStarRating = null;
            relaxedFilters.Add("إلغاء شرط تصنيف النجوم");
        }
    }

    #endregion

    #region === Major Relaxation (50%+) ===

    private void ApplyMajorRelaxation(
        UnitSearchRequest request,
        FallbackSearchOptions options,
        List<string> relaxedFilters)
    {
        // تطبيق التخفيف المتوسط أولاً
        ApplyModerateRelaxation(request, options, relaxedFilters);

        // 10. توسيع نطاق السعر بشكل كبير (+/- 50%)
        RelaxPrice(request, options.PriceRelaxationMajor, relaxedFilters, forceUpdate: true);

        // 11. توسيع كبير في النطاق الجغرافي
        RelaxGeographicRadius(request, options.RadiusMultiplierMajor, relaxedFilters, forceUpdate: true);

        // 12. مرونة في التواريخ (±3 أيام)
        RelaxDates(request, options.DateFlexibilityDays, relaxedFilters);

        // 13. إلغاء جميع المرافق
        if (request.RequiredAmenities?.Any() == true)
        {
            request.RequiredAmenities = null;
            relaxedFilters.Add("إلغاء جميع شروط المرافق");
        }

        // 14. إلغاء جميع الحقول الديناميكية
        if (request.DynamicFieldFilters?.Any() == true)
        {
            request.DynamicFieldFilters = null;
            relaxedFilters.Add("إلغاء جميع الحقول الإضافية");
        }
    }

    #endregion

    #region === Alternative Strategy ===

    private void ApplyAlternativeStrategy(
        UnitSearchRequest request,
        UnitSearchRequest original,
        List<string> relaxedFilters)
    {
        // ✅ الاحتفاظ بالمعايير الأساسية التي لا يجب إلغاؤها أبداً:
        // - المدينة (City)
        // - نوع العقار (PropertyTypeId)  
        // - نوع الوحدة (UnitTypeId)
        // - التواريخ (CheckIn, CheckOut)
        
        var city = original.City;
        var propertyTypeId = original.PropertyTypeId;
        var unitTypeId = original.UnitTypeId;
        var checkIn = original.CheckIn;
        var checkOut = original.CheckOut;

        // نسخ الخصائص الأساسية
        request.City = city;
        request.PropertyTypeId = propertyTypeId;  // ✅ الاحتفاظ بنوع العقار
        request.UnitTypeId = unitTypeId;          // ✅ الاحتفاظ بنوع الوحدة
        request.CheckIn = checkIn;
        request.CheckOut = checkOut;
        request.SortBy = "relevance";

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // Validation: التحقق من وجود معايير أساسية بعد النسخ
        // If no basic criteria exists, apply safety constraints
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        if (string.IsNullOrWhiteSpace(request.City) && 
            !request.PropertyTypeId.HasValue && 
            !request.UnitTypeId.HasValue)
        {
            // فرض معايير افتراضية للحد من النتائج
            request.FeaturedOnly = true;
            request.PageSize = Math.Min(request.PageSize, 20);
            
            relaxedFilters.Add("عرض العقارات المميزة فقط (لا توجد معايير بحث محددة)");
            
            _logger.LogWarning(
                "⚠️ Alternative Strategy بدون معايير أساسية - فرض FeaturedOnly=true و PageSize=20");
        }

        // إلغاء باقي المعايير الثانوية فقط
        request.SearchText = null;
        request.MinPrice = null;
        request.MaxPrice = null;
        request.MinRating = null;
        request.MinStarRating = null;
        request.GuestsCount = null;
        request.RequiredAmenities = null;
        request.RequiredServices = null;
        request.DynamicFieldFilters = null;
        request.Latitude = null;
        request.Longitude = null;
        request.RadiusKm = null;

        var keptFilters = new List<string> { "المدينة", "التواريخ" };
        if (propertyTypeId.HasValue) keptFilters.Add("نوع العقار");
        if (unitTypeId.HasValue) keptFilters.Add("نوع الوحدة");
        
        relaxedFilters.Add($"بحث بديل: الاحتفاظ بـ {string.Join("، ", keptFilters)} فقط");
    }

    #endregion

    #region === Helper Methods ===

    /// <summary>
    /// تخفيف نطاق السعر
    /// Relax price range
    /// </summary>
    private void RelaxPrice(
        UnitSearchRequest request,
        decimal relaxationPercentage,
        List<string> relaxedFilters,
        bool forceUpdate = false)
    {
        var hasChanges = false;

        if (request.MinPrice.HasValue)
        {
            var newMin = request.MinPrice.Value * (1 - relaxationPercentage);
            if (forceUpdate || newMin != request.MinPrice.Value)
            {
                request.MinPrice = newMin;
                hasChanges = true;
            }
        }

        if (request.MaxPrice.HasValue)
        {
            var newMax = request.MaxPrice.Value * (1 + relaxationPercentage);
            if (forceUpdate || newMax != request.MaxPrice.Value)
            {
                request.MaxPrice = newMax;
                hasChanges = true;
            }
        }

        if (hasChanges)
        {
            var percentage = (int)(relaxationPercentage * 100);
            relaxedFilters.Add($"توسيع نطاق السعر {percentage}%");
        }
    }

    /// <summary>
    /// تقليل المرافق المطلوبة
    /// Reduce required amenities
    /// </summary>
    private void RelaxAmenities(
        UnitSearchRequest request,
        decimal retentionRatio,
        List<string> relaxedFilters)
    {
        if (request.RequiredAmenities?.Any() != true)
            return;

        var originalCount = request.RequiredAmenities.Count;
        var keepCount = Math.Max(1, (int)(originalCount * retentionRatio));

        if (keepCount < originalCount)
        {
            request.RequiredAmenities = request.RequiredAmenities.Take(keepCount).ToList();
            relaxedFilters.Add($"تقليل المرافق المطلوبة من {originalCount} إلى {keepCount}");
        }
    }

    /// <summary>
    /// تخفيف فلتر التقييم
    /// Relax rating filter
    /// </summary>
    private void RelaxRating(
        UnitSearchRequest request,
        decimal reduction,
        List<string> relaxedFilters)
    {
        if (request.MinRating.HasValue && request.MinRating > 0)
        {
            var newRating = Math.Max(0, request.MinRating.Value - reduction);
            if (newRating != request.MinRating.Value)
            {
                request.MinRating = newRating;
                relaxedFilters.Add($"تخفيض الحد الأدنى للتقييم إلى {newRating:F1}");
            }
        }
    }

    /// <summary>
    /// تخفيف الحقول الديناميكية
    /// Relax dynamic fields
    /// </summary>
    private void RelaxDynamicFields(
        UnitSearchRequest request,
        bool keepCriticalOnly,
        List<string> relaxedFilters)
    {
        if (request.DynamicFieldFilters?.Any() != true)
            return;

        var criticalFields = new[] { "room_count", "bedrooms", "bathroom_count" };
        var originalCount = request.DynamicFieldFilters.Count;

        if (keepCriticalOnly)
        {
            var filtered = request.DynamicFieldFilters
                .Where(f => criticalFields.Contains(f.Key.ToLower()))
                .ToDictionary(f => f.Key, f => f.Value);

            if (filtered.Count < originalCount)
            {
                request.DynamicFieldFilters = filtered.Any() ? filtered : null;
                relaxedFilters.Add($"إزالة {originalCount - filtered.Count} حقل إضافي");
            }
        }
        else
        {
            request.DynamicFieldFilters = null;
            relaxedFilters.Add($"إلغاء جميع الحقول الإضافية ({originalCount})");
        }
    }

    /// <summary>
    /// توسيع النطاق الجغرافي
    /// Expand geographic radius
    /// </summary>
    private void RelaxGeographicRadius(
        UnitSearchRequest request,
        double multiplier,
        List<string> relaxedFilters,
        bool forceUpdate = false)
    {
        if (request.RadiusKm.HasValue && request.RadiusKm.Value > 0)
        {
            var newRadius = request.RadiusKm.Value * multiplier;
            if (forceUpdate || newRadius != request.RadiusKm.Value)
            {
                request.RadiusKm = newRadius;
                relaxedFilters.Add($"توسيع نطاق البحث إلى {newRadius:F1} كم");
            }
        }
    }

    /// <summary>
    /// إضافة المدن المجاورة
    /// Add nearby cities
    /// </summary>
    private void AddNearbyCities(
        UnitSearchRequest request,
        List<string> relaxedFilters)
    {
        if (string.IsNullOrWhiteSpace(request.City))
            return;

        var nearbyCities = GetNearbyCities(request.City);
        if (nearbyCities.Count > 1)
        {
            // في حالة وجود مدن مجاورة، نضيفها لنص البحث
            var additionalCities = nearbyCities.Where(c => !c.Equals(request.City, StringComparison.OrdinalIgnoreCase)).ToList();
            if (additionalCities.Any())
            {
                relaxedFilters.Add($"إضافة المدن المجاورة: {string.Join(", ", additionalCities)}");
            }
        }
    }

    /// <summary>
    /// تخفيف شرط عدد الضيوف
    /// Relax guests count requirement
    /// </summary>
    private void RelaxGuestsCount(
        UnitSearchRequest request,
        int reduction,
        List<string> relaxedFilters)
    {
        if (request.GuestsCount.HasValue && request.GuestsCount > reduction)
        {
            var newCount = request.GuestsCount.Value - reduction;
            request.GuestsCount = newCount;
            relaxedFilters.Add($"تقليل عدد الضيوف إلى {newCount}");
        }
    }

    /// <summary>
    /// مرونة في التواريخ
    /// Add date flexibility
    /// </summary>
    private void RelaxDates(
        UnitSearchRequest request,
        int flexibilityDays,
        List<string> relaxedFilters)
    {
        if (request.CheckIn.HasValue && request.CheckOut.HasValue)
        {
            // لا نغير التواريخ فعلياً، لكن نضيف ملاحظة
            relaxedFilters.Add($"مرونة في التواريخ ±{flexibilityDays} أيام");
            // يمكن إضافة منطق إضافي هنا لاحقاً
        }
    }

    /// <summary>
    /// الحصول على المدن المجاورة
    /// Get nearby cities
    /// </summary>
    private List<string> GetNearbyCities(string city)
    {
        if (string.IsNullOrWhiteSpace(city))
            return new List<string> { city ?? "" };

        foreach (var group in YemeniCityGroups)
        {
            if (group.Value.Any(c => c.Equals(city, StringComparison.OrdinalIgnoreCase)))
            {
                return group.Value;
            }
        }

        return new List<string> { city };
    }

    /// <summary>
    /// التحقق من وجود معايير أساسية كافية للتخفيف إلى Alternative
    /// Check if request has minimum criteria for Alternative relaxation
    /// 
    /// ✅ المعايير الأساسية: المدينة أو نوع العقار أو نوع الوحدة أو التواريخ
    /// ✅ Minimum criteria: City OR PropertyType OR UnitType OR Dates
    /// ✅ يضمن عدم إرجاع جميع الوحدات عند تطبيق Alternative Strategy
    /// </summary>
    private bool HasMinimumCriteria(UnitSearchRequest request)
    {
        return !string.IsNullOrWhiteSpace(request.City) ||
               request.PropertyTypeId.HasValue ||
               request.UnitTypeId.HasValue ||
               (request.CheckIn.HasValue && request.CheckOut.HasValue);
    }

    #endregion
}

