using YemenBooking.Core.Indexing.Models;

namespace YemenBooking.Infrastructure.Services;

/// <summary>
/// خدمة مقارنة معايير البحث الأصلية مع خصائص العقارات المُرجعة
/// Service for comparing original search criteria with returned property attributes
/// </summary>
public class PropertyFilterComparisonService
{
    /// <summary>
    /// مقارنة معايير الطلب الأصلي مع خصائص العقار وإرجاع الفروقات
    /// Compare original request criteria with property attributes and return mismatches
    /// </summary>
    /// <param name="property">العقار المُرجع / Returned property</param>
    /// <param name="request">الطلب الأصلي (قبل التخفيف) / Original request (before relaxation)</param>
    /// <returns>قائمة الفروقات / List of mismatches</returns>
    public List<PropertyFilterMismatch> ComparePropertyWithOriginalRequest(
        PropertyGroupSearchItem property,
        UnitSearchRequest request)
    {
        var mismatches = new List<PropertyFilterMismatch>();
        
        Console.WriteLine($"🔍 [ComparisonService] Comparing property '{property.PropertyName}'");
        Console.WriteLine($"   - Request GuestsCount: {request.GuestsCount}");
        Console.WriteLine($"   - Request DynamicFieldFilters: {request.DynamicFieldFilters?.Count ?? 0}");
        Console.WriteLine($"   - Matched Units: {property.MatchedUnits.Count()}");
        
        // 1. مقارنة عدد الضيوف
        if (request.GuestsCount.HasValue)
        {
            var guestMismatch = CompareGuestsCount(property, request.GuestsCount.Value);
            if (guestMismatch != null)
            {
                Console.WriteLine($"   ✓ Guest count mismatch found");
                mismatches.Add(guestMismatch);
            }
        }
        
        // 2. مقارنة الحقول الديناميكية
        if (request.DynamicFieldFilters?.Any() == true)
        {
            Console.WriteLine($"   - Checking {request.DynamicFieldFilters.Count} dynamic fields...");
            var dynamicMismatches = CompareDynamicFields(property, request.DynamicFieldFilters);
            Console.WriteLine($"   - Found {dynamicMismatches.Count} dynamic field mismatches");
            mismatches.AddRange(dynamicMismatches);
        }
        
        // 3. مقارنة السعر (إذا كان خارج النطاق المطلوب)
        if (request.MinPrice.HasValue || request.MaxPrice.HasValue)
        {
            var priceMismatch = ComparePriceRange(
                property, 
                request.MinPrice, 
                request.MaxPrice,
                request.PreferredCurrency ?? "YER");
            
            if (priceMismatch != null)
            {
                Console.WriteLine($"   ✓ Price mismatch found");
                mismatches.Add(priceMismatch);
            }
        }
        
        Console.WriteLine($"   → Total mismatches: {mismatches.Count}");
        return mismatches;
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // دوال المقارنة التفصيلية
    // Detailed comparison methods
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    /// <summary>
    /// مقارنة عدد الضيوف المطلوب مع سعة الوحدات المطابقة
    /// Compare requested guest count with matched units capacity
    /// </summary>
    private PropertyFilterMismatch? CompareGuestsCount(
        PropertyGroupSearchItem property, 
        int requestedGuests)
    {
        // الحصول على أكبر سعة من الوحدات المطابقة
        var maxCapacity = property.MatchedUnits.Max(u => u.MaxCapacity);
        
        if (maxCapacity < requestedGuests)
        {
            var diff = requestedGuests - maxCapacity;
            
            return new PropertyFilterMismatch
            {
                FilterType = "GuestsCount",
                FilterDisplayName = "السعة",
                RequestedValue = $"{requestedGuests} ضيوف",
                ActualValue = $"{maxCapacity} ضيوف",
                DisplayMessage = $"يستوعب {maxCapacity} ضيوف (طلبت {requestedGuests})",
                Severity = diff == 1 ? MismatchSeverity.Minor : MismatchSeverity.Moderate
            };
        }
        
        return null;
    }
    
    /// <summary>
    /// مقارنة الحقول الديناميكية المطلوبة مع حقول الوحدات المطابقة
    /// Compare requested dynamic fields with matched units fields
    /// </summary>
    private List<PropertyFilterMismatch> CompareDynamicFields(
        PropertyGroupSearchItem property,
        Dictionary<string, string> requestedFields)
    {
        var mismatches = new List<PropertyFilterMismatch>();
        
        foreach (var field in requestedFields)
        {
            var fieldName = field.Key;
            var requestedValue = field.Value;
            
            Console.WriteLine($"      - Checking field '{fieldName}' = '{requestedValue}'");
            
            // التحقق من جميع الوحدات المطابقة
            var allUnitsMatch = property.MatchedUnits.All(unit =>
            {
                // التحقق إذا كانت الوحدة تحتوي على هذا الحقل
                if (unit.DisplayFields == null || !unit.DisplayFields.ContainsKey(fieldName))
                {
                    Console.WriteLine($"        × Unit {unit.UnitId} doesn't have field '{fieldName}'");
                    return false;
                }
                
                var actualValue = unit.DisplayFields[fieldName];
                var matches = DoesValueMatch(actualValue, requestedValue);
                
                Console.WriteLine($"        Unit {unit.UnitId}: '{actualValue}' {(matches ? "✓" : "×")} '{requestedValue}'");
                
                // مقارنة القيمة حسب النوع
                return matches;
            });
            
            Console.WriteLine($"      → All units match: {allUnitsMatch}");
            
            if (!allUnitsMatch)
            {
                // إنشاء فرق للحقل الديناميكي
                var mismatch = CreateDynamicFieldMismatch(
                    fieldName, 
                    requestedValue, 
                    property.MatchedUnits);
                
                if (mismatch != null)
                {
                    Console.WriteLine($"      ✓ Added mismatch for '{fieldName}'");
                    mismatches.Add(mismatch);
                }
            }
        }
        
        return mismatches;
    }
    
    /// <summary>
    /// التحقق إذا كانت القيمة الفعلية تطابق القيمة المطلوبة
    /// Check if actual value matches requested value
    /// </summary>
    private bool DoesValueMatch(string actualValue, string requestedValue)
    {
        // 1. بحث نصي جزئي (يبدأ بـ ~)
        if (requestedValue.StartsWith("~"))
        {
            var searchText = requestedValue.Substring(1);
            return actualValue.Contains(searchText, StringComparison.OrdinalIgnoreCase);
        }
        
        // 2. نطاق رقمي (يحتوي على ..)
        if (requestedValue.Contains(".."))
        {
            var parts = requestedValue.Split("..");
            if (decimal.TryParse(parts[0], out var min) && 
                decimal.TryParse(parts[1], out var max) &&
                decimal.TryParse(actualValue, out var actual))
            {
                return actual >= min && actual <= max;
            }
        }
        
        // 3. تطابق تام (case-insensitive)
        return string.Equals(actualValue, requestedValue, StringComparison.OrdinalIgnoreCase);
    }
    
    /// <summary>
    /// إنشاء PropertyFilterMismatch لحقل ديناميكي
    /// Create PropertyFilterMismatch for a dynamic field
    /// </summary>
    private PropertyFilterMismatch? CreateDynamicFieldMismatch(
        string fieldName,
        string requestedValue,
        IEnumerable<UnitSearchItem> matchedUnits)
    {
        // الحصول على الاسم العربي للحقل
        var displayName = GetFieldDisplayName(fieldName);
        
        // تنسيق القيمة المطلوبة
        var formattedRequested = FormatFieldValue(fieldName, requestedValue);
        
        // الحصول على القيم الفعلية من الوحدات
        var actualValues = matchedUnits
            .Where(u => u.DisplayFields?.ContainsKey(fieldName) == true)
            .Select(u => u.DisplayFields![fieldName])
            .Distinct()
            .ToList();
        
        var formattedActual = actualValues.Any() 
            ? string.Join(", ", actualValues.Select(v => FormatFieldValue(fieldName, v)))
            : "غير متوفر";
        
        // تحديد الشدة
        var severity = DetermineSeverity(fieldName, requestedValue, actualValues);
        
        return new PropertyFilterMismatch
        {
            FilterType = "DynamicField",
            FilterDisplayName = displayName,
            RequestedValue = formattedRequested,
            ActualValue = formattedActual,
            DisplayMessage = GenerateDisplayMessage(displayName, formattedRequested, formattedActual),
            Severity = severity
        };
    }
    
    /// <summary>
    /// مقارنة نطاق السعر
    /// Compare price range
    /// </summary>
    private PropertyFilterMismatch? ComparePriceRange(
        PropertyGroupSearchItem property,
        decimal? minPrice,
        decimal? maxPrice,
        string currency)
    {
        // التحقق إذا كان سعر العقار خارج النطاق المطلوب
        var propertyMin = property.MinPrice;
        var propertyMax = property.MaxPrice;
        
        var isOutOfRange = false;
        string reason = "";
        
        if (minPrice.HasValue && propertyMax < minPrice.Value)
        {
            isOutOfRange = true;
            reason = "أقل من الحد الأدنى";
        }
        else if (maxPrice.HasValue && propertyMin > maxPrice.Value)
        {
            isOutOfRange = true;
            reason = "أعلى من الحد الأقصى";
        }
        
        if (isOutOfRange)
        {
            return new PropertyFilterMismatch
            {
                FilterType = "Price",
                FilterDisplayName = "السعر",
                RequestedValue = FormatPriceRange(minPrice, maxPrice, currency),
                ActualValue = FormatPriceRange(propertyMin, propertyMax, currency),
                DisplayMessage = $"السعر {reason}",
                Severity = MismatchSeverity.Moderate
            };
        }
        
        return null;
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // دوال مساعدة
    // Helper methods
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    /// <summary>
    /// قاموس ترجمة أسماء الحقول للعربية
    /// Dictionary for translating field names to Arabic
    /// </summary>
    private static readonly Dictionary<string, string> FieldDisplayNames = new()
    {
        ["has_pool"] = "مسبح",
        ["has_garden"] = "حديقة",
        ["has_wifi"] = "إنترنت",
        ["has_parking"] = "موقف سيارات",
        ["has_gym"] = "صالة رياضية",
        ["has_elevator"] = "مصعد",
        ["has_balcony"] = "شرفة",
        ["has_kitchen"] = "مطبخ",
        ["has_ac"] = "تكييف",
        ["has_tv"] = "تلفاز",
        ["area"] = "المساحة",
        ["chalet_size"] = "المساحة",
        ["room_count"] = "عدد الغرف",
        ["bedrooms"] = "عدد غرف النوم",
        ["bathroom_count"] = "عدد الحمامات",
        ["floor"] = "الطابق",
        ["view"] = "الإطلالة",
        ["furnishing"] = "التأثيث",
        ["smoking_allowed"] = "السماح بالتدخين",
        ["pets_allowed"] = "السماح بالحيوانات الأليفة"
    };
    
    private string GetFieldDisplayName(string fieldName)
    {
        return FieldDisplayNames.GetValueOrDefault(fieldName, fieldName);
    }
    
    /// <summary>
    /// تنسيق قيمة الحقل للعرض
    /// Format field value for display
    /// </summary>
    private string FormatFieldValue(string fieldName, string value)
    {
        // إزالة ~ للبحث النصي
        if (value.StartsWith("~"))
            value = value.Substring(1);
        
        // تنسيق النطاق الرقمي
        if (value.Contains(".."))
        {
            var parts = value.Split("..");
            var unit = GetUnitForField(fieldName);
            return $"{parts[0]}-{parts[1]}{unit}";
        }
        
        // تنسيق القيم المنطقية
        if (value.Equals("true", StringComparison.OrdinalIgnoreCase))
            return "نعم";
        if (value.Equals("false", StringComparison.OrdinalIgnoreCase))
            return "لا";
        
        // إضافة وحدة القياس
        var fieldUnit = GetUnitForField(fieldName);
        return value + fieldUnit;
    }
    
    /// <summary>
    /// الحصول على وحدة القياس للحقل
    /// Get unit of measurement for field
    /// </summary>
    private string GetUnitForField(string fieldName)
    {
        return fieldName switch
        {
            "area" or "chalet_size" => " م²",
            "floor" or "room_count" or "bedrooms" or "bathroom_count" => "",
            _ => ""
        };
    }
    
    /// <summary>
    /// تحديد شدة الفرق
    /// Determine severity of mismatch
    /// </summary>
    private MismatchSeverity DetermineSeverity(
        string fieldName, 
        string requestedValue, 
        List<string> actualValues)
    {
        // الحقول الحرجة (bedrooms, bathroom_count, room_count) → Moderate
        var criticalFields = new[] { "bedrooms", "bathroom_count", "room_count" };
        if (criticalFields.Contains(fieldName))
            return MismatchSeverity.Moderate;
        
        // الحقول الثانوية (has_wifi, has_parking) → Minor
        return MismatchSeverity.Minor;
    }
    
    /// <summary>
    /// توليد رسالة العرض
    /// Generate display message
    /// </summary>
    private string GenerateDisplayMessage(
        string displayName, 
        string requested, 
        string actual)
    {
        // إذا كانت القيمة المطلوبة "نعم" والفعلية "لا"
        if (requested == "نعم" && actual == "لا")
            return $"بدون {displayName}";
        
        // إذا كانت القيمة المطلوبة "لا" والفعلية "نعم"
        if (requested == "لا" && actual == "نعم")
            return $"يحتوي على {displayName}";
        
        // باقي الحالات
        return $"{displayName}: {actual} (طلبت {requested})";
    }
    
    /// <summary>
    /// تنسيق نطاق السعر
    /// Format price range
    /// </summary>
    private string FormatPriceRange(decimal? min, decimal? max, string currency)
    {
        if (min.HasValue && max.HasValue)
            return $"{min:N0}-{max:N0} {currency}";
        if (min.HasValue)
            return $"من {min:N0} {currency}";
        if (max.HasValue)
            return $"حتى {max:N0} {currency}";
        return "غير محدد";
    }
}
