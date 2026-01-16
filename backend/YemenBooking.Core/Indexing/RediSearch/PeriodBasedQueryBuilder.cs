using System;
using System.Collections.Generic;
using System.Linq;
using YemenBooking.Core.Indexing.Models;

namespace YemenBooking.Core.Indexing.RediSearch;

/// <summary>
/// بناء استعلامات RediSearch المحسّنة للبحث المباشر في الفترات
/// 
/// الاستراتيجية:
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 
/// **المرحلة 1: البحث عن الوحدات المتاحة (إذا كانت هناك تواريخ)**
/// 
/// 1.1. البحث في idx:periods:avail عن فترات محجوزة تتقاطع:
///      Query: @status:{Blocked|Booked} @startDateTs:[-inf checkOutTs] @endDateTs:[checkInTs +inf]
///      النتيجة: قائمة UnitIds المحجوزة
/// 
/// 1.2. استثناء هذه الوحدات من البحث الرئيسي
/// 
/// **المرحلة 2: البحث في الوحدات بالمعايير الأخرى**
/// 
/// 2.1. المدينة (الفلتر 1)
/// 2.2. نوع العقار (الفلتر 2)
/// 2.3. نوع الوحدة (الفلتر 3)
/// 2.4. الحقول الديناميكية (الفلتر 5)
/// 2.5. المرافق (الفلتر 6)
/// 2.6. الخدمات (الفلتر 7)
/// 2.7. السعة، التقييم، الموقع الجغرافي، إلخ
/// 
/// **المرحلة 3: حساب السعر للفترة المحددة (إذا كانت هناك تواريخ)**
/// 
/// 3.1. لكل وحدة في النتائج:
///      - البحث في idx:periods:price عن فترات تتقاطع مع (CheckIn, CheckOut)
///      - حساب السعر الإجمالي للفترة
///      - فلترة حسب MinPrice / MaxPrice إذا كانت محددة
/// </summary>
public class PeriodBasedQueryBuilder
{
    private readonly UnitSearchRequest _request;
    
    public PeriodBasedQueryBuilder(UnitSearchRequest request)
    {
        _request = request ?? throw new ArgumentNullException(nameof(request));
    }
    
    #region === بناء الاستعلامات الرئيسية ===
    
    /// <summary>
    /// بناء استعلام البحث عن الوحدات المتاحة
    /// </summary>
    public string[] BuildUnitsSearchQuery(HashSet<string>? excludedUnitIds = null)
    {
        var filters = new List<string>();
        
        // البدء بالقاعدة الأساسية
        filters.Add("*");
        
        // 1. فلتر المدينة (الفلتر 1)
        if (!string.IsNullOrWhiteSpace(_request.City))
        {
            var city = EscapeValue(_request.City);
            filters.Add($"@{PeriodBasedSearchSchema.UnitFields.CITY}:{{{city}}}");
        }
        
        // 2. فلتر نوع العقار (الفلتر 2)
        if (_request.PropertyTypeId.HasValue)
        {
            filters.Add($"@{PeriodBasedSearchSchema.UnitFields.PROPERTY_TYPE_ID}:{{{_request.PropertyTypeId.Value}}}");
        }
        
        // 3. فلتر نوع الوحدة (الفلتر 3)
        if (_request.UnitTypeId.HasValue)
        {
            filters.Add($"@{PeriodBasedSearchSchema.UnitFields.UNIT_TYPE_ID}:{{{_request.UnitTypeId.Value}}}");
        }
        
        // 5. فلتر الحقول الديناميكية (الفلتر 5)
        ApplyDynamicFieldsFilter(filters);
        
        // 6. فلتر المرافق (الفلتر 6)
        ApplyAmenitiesFilter(filters);
        
        // 7. فلتر الخدمات (الفلتر 7)
        ApplyServicesFilter(filters);
        
        // فلاتر إضافية
        ApplyCapacityFilter(filters);
        ApplyRatingFilter(filters);
        ApplyGeoFilter(filters);
        ApplyTextSearchFilter(filters);
        ApplyApprovalFilters(filters);
        
        // استثناء الوحدات المحجوزة
        if (excludedUnitIds != null && excludedUnitIds.Any())
        {
            var excludedIds = string.Join("|", excludedUnitIds.Select(id => EscapeValue(id)));
            filters.Add($"-@{PeriodBasedSearchSchema.UnitFields.UNIT_ID}:({excludedIds})");
        }
        
        // بناء الأمر النهائي
        var command = new List<string>
        {
            PeriodBasedSearchSchema.UNITS_INDEX,
            string.Join(" ", filters)
        };
        
        // SORTBY
        ApplySorting(command);
        
        // LIMIT (Pagination)
        var offset = (_request.PageNumber - 1) * _request.PageSize;
        command.Add("LIMIT");
        command.Add(offset.ToString());
        command.Add(_request.PageSize.ToString());
        
        return command.ToArray();
    }
    
    /// <summary>
    /// بناء استعلام البحث عن الفترات المحجوزة
    /// 
    /// الهدف: إيجاد جميع الوحدات المحجوزة في الفترة المطلوبة
    /// 
    /// المنطق:
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// فترتان تتقاطعان إذا:
    /// • period.startDate < checkOut AND period.endDate > checkIn
    /// 
    /// بصيغة RediSearch:
    /// • @startDateTs:[-inf checkOutTs] AND @endDateTs:[checkInTs +inf]
    /// • @status:{Blocked|Booked} (نستثني Available)
    /// </summary>
    public string[] BuildBlockedPeriodsQuery(DateTime checkIn, DateTime checkOut)
    {
        var checkInTs = new DateTimeOffset(checkIn.Date).ToUnixTimeSeconds();
        var checkOutTs = new DateTimeOffset(checkOut.Date).ToUnixTimeSeconds();
        
        var query = $"@{PeriodBasedSearchSchema.SchedulePeriodFields.STATUS}:{{Blocked|Booked}} " +
                    $"@{PeriodBasedSearchSchema.SchedulePeriodFields.DATE_TS}:[{checkInTs} {checkOutTs}]";
        
        return new[]
        {
            PeriodBasedSearchSchema.SCHEDULE_INDEX,
            query,
            "RETURN", "1", PeriodBasedSearchSchema.SchedulePeriodFields.UNIT_ID,
            "LIMIT", "0", "10000"
        };
    }
    
    /// <summary>
    /// بناء استعلام البحث عن فترات التسعير
    /// 
    /// الهدف: إيجاد جميع قواعد التسعير التي تتقاطع مع الفترة المطلوبة لوحدة محددة
    /// 
    /// المنطق:
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// • @unitId:{unitId}
    /// • @startDateTs:[-inf checkOutTs]
    /// • @endDateTs:[checkInTs +inf]
    /// </summary>
    public string[] BuildPricingPeriodsQuery(Guid unitId, DateTime checkIn, DateTime checkOut)
    {
        var checkInTs = new DateTimeOffset(checkIn.Date).ToUnixTimeSeconds();
        var checkOutTs = new DateTimeOffset(checkOut.Date).ToUnixTimeSeconds();
        
        var query = $"@{PeriodBasedSearchSchema.SchedulePeriodFields.UNIT_ID}:{{{unitId}}} " +
                    $"@{PeriodBasedSearchSchema.SchedulePeriodFields.DATE_TS}:[{checkInTs} {checkOutTs}]";
        
        return new[]
        {
            PeriodBasedSearchSchema.SCHEDULE_INDEX,
            query,
            "SORTBY", PeriodBasedSearchSchema.SchedulePeriodFields.DATE_TS, "ASC",
            "LIMIT", "0", "1000"
        };
    }
    
    #endregion
    
    #region === الفلاتر (Filters) ===
    
    /// <summary>
    /// 5. فلتر الحقول الديناميكية
    /// </summary>
    private void ApplyDynamicFieldsFilter(List<string> filters)
    {
        if (_request.DynamicFieldFilters == null || !_request.DynamicFieldFilters.Any())
            return;
        
        foreach (var (fieldName, filterValue) in _request.DynamicFieldFilters)
        {
            if (string.IsNullOrWhiteSpace(filterValue))
                continue;
            
            // فحص إذا كانت القيمة نطاق رقمي (مثال: "50..100")
            if (filterValue.Contains(".."))
            {
                var parts = filterValue.Split("..", StringSplitOptions.RemoveEmptyEntries);
                if (parts.Length == 2 
                    && decimal.TryParse(parts[0], out var min) 
                    && decimal.TryParse(parts[1], out var max))
                {
                    var numericField = PeriodBasedSearchSchema.GetDynamicNumericField(fieldName);
                    filters.Add($"@{numericField}:[{min} {max}]");
                    continue;
                }
            }
            
            // فحص إذا كانت القيمة رقمية
            if (decimal.TryParse(filterValue, out var numValue))
            {
                var numericField = PeriodBasedSearchSchema.GetDynamicNumericField(fieldName);
                filters.Add($"@{numericField}:[{numValue} {numValue}]");
            }
            else
            {
                var textField = PeriodBasedSearchSchema.GetDynamicTextField(fieldName);
                var escapedValue = EscapeValue(filterValue);
                filters.Add($"@{textField}:{{{escapedValue}}}");
            }
        }
    }
    
    /// <summary>
    /// 6. فلتر المرافق
    /// </summary>
    private void ApplyAmenitiesFilter(List<string> filters)
    {
        if (_request.RequiredAmenities == null || !_request.RequiredAmenities.Any())
            return;
        
        foreach (var amenityId in _request.RequiredAmenities)
        {
            filters.Add($"@{PeriodBasedSearchSchema.UnitFields.AMENITY_IDS}:{{{amenityId}}}");
        }
    }
    
    /// <summary>
    /// 7. فلتر الخدمات
    /// </summary>
    private void ApplyServicesFilter(List<string> filters)
    {
        if (_request.RequiredServices == null || !_request.RequiredServices.Any())
            return;
        
        foreach (var serviceId in _request.RequiredServices)
        {
            filters.Add($"@{PeriodBasedSearchSchema.UnitFields.SERVICE_IDS}:{{{serviceId}}}");
        }
    }
    
    /// <summary>
    /// فلتر السعة
    /// </summary>
    private void ApplyCapacityFilter(List<string> filters)
    {
        if (_request.GuestsCount.HasValue && _request.GuestsCount.Value > 0)
        {
            filters.Add($"@{PeriodBasedSearchSchema.UnitFields.MAX_CAPACITY}:[{_request.GuestsCount.Value} +inf]");
        }
        
        if (_request.AdultsCount.HasValue && _request.AdultsCount.Value > 0)
        {
            filters.Add($"@{PeriodBasedSearchSchema.UnitFields.ADULTS_CAPACITY}:[{_request.AdultsCount.Value} +inf]");
        }
        
        if (_request.ChildrenCount.HasValue && _request.ChildrenCount.Value > 0)
        {
            filters.Add($"@{PeriodBasedSearchSchema.UnitFields.CHILDREN_CAPACITY}:[{_request.ChildrenCount.Value} +inf]");
        }
    }
    
    /// <summary>
    /// فلتر التقييم
    /// </summary>
    private void ApplyRatingFilter(List<string> filters)
    {
        if (_request.MinRating.HasValue && _request.MinRating.Value > 0)
        {
            filters.Add($"@{PeriodBasedSearchSchema.UnitFields.AVERAGE_RATING}:[{_request.MinRating.Value} +inf]");
        }
        
        if (_request.MinStarRating.HasValue && _request.MinStarRating.Value > 0)
        {
            filters.Add($"@{PeriodBasedSearchSchema.UnitFields.STAR_RATING}:[{_request.MinStarRating.Value} +inf]");
        }
    }
    
    /// <summary>
    /// فلتر البحث الجغرافي
    /// </summary>
    private void ApplyGeoFilter(List<string> filters)
    {
        if (_request.Latitude.HasValue 
            && _request.Longitude.HasValue 
            && _request.RadiusKm.HasValue 
            && _request.RadiusKm.Value > 0)
        {
            var radiusM = _request.RadiusKm.Value * 1000;
            filters.Add($"@{PeriodBasedSearchSchema.UnitFields.LOCATION}:[{_request.Longitude.Value} {_request.Latitude.Value} {radiusM} m]");
        }
    }
    
    /// <summary>
    /// فلتر البحث النصي
    /// </summary>
    private void ApplyTextSearchFilter(List<string> filters)
    {
        if (!string.IsNullOrWhiteSpace(_request.SearchText))
        {
            var escapedText = EscapeValue(_request.SearchText);
            filters.Add($"@{PeriodBasedSearchSchema.UnitFields.SEARCH_KEYWORDS}:({escapedText})");
        }
    }
    
    /// <summary>
    /// فلاتر الموافقة
    /// </summary>
    private void ApplyApprovalFilters(List<string> filters)
    {
        filters.Add($"@{PeriodBasedSearchSchema.UnitFields.IS_APPROVED}:{{1}}");
        
        if (_request.FeaturedOnly == true)
        {
            filters.Add($"@{PeriodBasedSearchSchema.UnitFields.IS_FEATURED}:{{1}}");
        }
    }
    
    #endregion
    
    #region === الترتيب (Sorting) ===
    
    private void ApplySorting(List<string> command)
    {
        if (string.IsNullOrWhiteSpace(_request.SortBy))
            return;
        
        command.Add("SORTBY");
        
        switch (_request.SortBy.ToLowerInvariant())
        {
            case "rating":
            case "rating_desc":
                command.Add(PeriodBasedSearchSchema.UnitFields.AVERAGE_RATING);
                command.Add("DESC");
                break;
            
            case "newest":
                command.Add(PeriodBasedSearchSchema.UnitFields.INDEXED_AT);
                command.Add("DESC");
                break;
            
            case "popular":
                command.Add(PeriodBasedSearchSchema.UnitFields.BOOKING_COUNT);
                command.Add("DESC");
                break;
            
            default:
                command.Add(PeriodBasedSearchSchema.UnitFields.AVERAGE_RATING);
                command.Add("DESC");
                break;
        }
    }
    
    #endregion
    
    #region === مساعدات (Helpers) ===
    
    private string EscapeValue(string value)
    {
        if (string.IsNullOrEmpty(value))
            return value;
        
        return value.Replace("@", "\\@")
                     .Replace(":", "\\:")
                     .Replace("{", "\\{")
                     .Replace("}", "\\}")
                     .Replace("[", "\\[")
                     .Replace("]", "\\]")
                     .Replace("(", "\\(")
                     .Replace(")", "\\)")
                     .Replace("*", "\\*")
                     .Replace("|", "\\|");
    }
    
    #endregion
}
