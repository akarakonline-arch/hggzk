using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text.Json;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Indexing.RediSearch;

/// <summary>
/// بناء بيانات Hash للوحدة والفترات المرتبطة
/// 
/// الهدف:
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// • بناء Hash entry للوحدة (بدون IS_AVAILABLE وبدون MIN/MAX prices)
/// • بناء Hash entries للجداول اليومية (كل DailyUnitSchedule = مستند منفصل)
/// </summary>
public class PeriodBasedHashBuilder
{
    private readonly Unit _unit;
    private readonly Property _property;
    private readonly UnitType _unitType;
    private readonly PropertyType _propertyType;
    private readonly List<DailyUnitSchedule> _schedules;
    private readonly List<PropertyAmenity> _amenities;
    private readonly List<PropertyService> _services;
    private readonly List<UnitFieldValue> _fieldValues;
    private readonly List<UnitTypeField> _fieldDefinitions;
    
    public PeriodBasedHashBuilder(
        Unit unit,
        Property property,
        UnitType unitType,
        PropertyType propertyType,
        List<DailyUnitSchedule> schedules,
        List<PropertyAmenity> amenities,
        List<PropertyService> services,
        List<UnitFieldValue> fieldValues,
        List<UnitTypeField> fieldDefinitions)
    {
        _unit = unit ?? throw new ArgumentNullException(nameof(unit));
        _property = property ?? throw new ArgumentNullException(nameof(property));
        _unitType = unitType ?? throw new ArgumentNullException(nameof(unitType));
        _propertyType = propertyType ?? throw new ArgumentNullException(nameof(propertyType));
        _schedules = schedules ?? new List<DailyUnitSchedule>();
        _amenities = amenities ?? new List<PropertyAmenity>();
        _services = services ?? new List<PropertyService>();
        _fieldValues = fieldValues ?? new List<UnitFieldValue>();
        _fieldDefinitions = fieldDefinitions ?? new List<UnitTypeField>();
    }
    
    #region === بناء مستند الوحدة الرئيسي ===
    
    /// <summary>
    /// بناء Hash entry للوحدة (بدون IS_AVAILABLE وبدون MIN/MAX prices)
    /// </summary>
    public Dictionary<string, string> BuildUnitHash()
    {
        var entries = new Dictionary<string, string>();
        
        // البيانات الأساسية
        entries[PeriodBasedSearchSchema.UnitFields.UNIT_ID] = _unit.Id.ToString();
        entries[PeriodBasedSearchSchema.UnitFields.PROPERTY_ID] = _property.Id.ToString();
        entries[PeriodBasedSearchSchema.UnitFields.UNIT_NAME] = _unit.Name ?? "";
        entries[PeriodBasedSearchSchema.UnitFields.PROPERTY_NAME] = _property.Name ?? "";
        entries[PeriodBasedSearchSchema.UnitFields.CITY] = _property.City ?? "";
        entries[PeriodBasedSearchSchema.UnitFields.PROPERTY_TYPE_ID] = _propertyType.Id.ToString();
        entries[PeriodBasedSearchSchema.UnitFields.PROPERTY_TYPE_NAME] = _propertyType.Name ?? "";
        entries[PeriodBasedSearchSchema.UnitFields.UNIT_TYPE_ID] = _unitType.Id.ToString();
        entries[PeriodBasedSearchSchema.UnitFields.UNIT_TYPE_NAME] = _unitType.Name ?? "";
        entries[PeriodBasedSearchSchema.UnitFields.OWNER_ID] = _property.OwnerId.ToString();
        entries[PeriodBasedSearchSchema.UnitFields.IS_APPROVED] = _property.IsApproved ? "1" : "0";
        entries[PeriodBasedSearchSchema.UnitFields.IS_FEATURED] = _property.IsFeatured ? "1" : "0";
        entries[PeriodBasedSearchSchema.UnitFields.STAR_RATING] = _property.StarRating.ToString(CultureInfo.InvariantCulture);
        entries[PeriodBasedSearchSchema.UnitFields.AVERAGE_RATING] = _property.AverageRating.ToString(CultureInfo.InvariantCulture);
        
        // الموقع الجغرافي
        entries[PeriodBasedSearchSchema.UnitFields.ADDRESS] = _property.Address ?? "";
        entries[PeriodBasedSearchSchema.UnitFields.LATITUDE] = _property.Latitude.ToString(CultureInfo.InvariantCulture);
        entries[PeriodBasedSearchSchema.UnitFields.LONGITUDE] = _property.Longitude.ToString(CultureInfo.InvariantCulture);
        entries[PeriodBasedSearchSchema.UnitFields.LOCATION] = 
            $"{_property.Longitude.ToString(CultureInfo.InvariantCulture)},{_property.Latitude.ToString(CultureInfo.InvariantCulture)}";
        
        // السعة
        entries[PeriodBasedSearchSchema.UnitFields.MAX_CAPACITY] = _unit.MaxCapacity.ToString(CultureInfo.InvariantCulture);
        entries[PeriodBasedSearchSchema.UnitFields.ADULTS_CAPACITY] = (_unit.AdultsCapacity ?? _unit.MaxCapacity).ToString(CultureInfo.InvariantCulture);
        entries[PeriodBasedSearchSchema.UnitFields.CHILDREN_CAPACITY] = (_unit.ChildrenCapacity ?? 0).ToString(CultureInfo.InvariantCulture);
        
        // السعر الأساسي (للرجوع فقط)
        entries[PeriodBasedSearchSchema.UnitFields.BASE_PRICE] = "0";
        entries[PeriodBasedSearchSchema.UnitFields.CURRENCY] = "YER";
        
        // المرافق والخدمات
        AddAmenitiesAndServices(entries);
        
        // الحقول الديناميكية
        AddDynamicFields(entries);
        
        // البيانات الوصفية
        entries[PeriodBasedSearchSchema.UnitFields.VIEW_COUNT] = _unit.ViewCount.ToString(CultureInfo.InvariantCulture);
        entries[PeriodBasedSearchSchema.UnitFields.BOOKING_COUNT] = _unit.BookingCount.ToString(CultureInfo.InvariantCulture);
        entries[PeriodBasedSearchSchema.UnitFields.INDEXED_AT] = DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString(CultureInfo.InvariantCulture);
        
        // الكلمات المفتاحية
        AddSearchKeywords(entries);
        
        // المستند الكامل JSON
        AddFullDocument(entries);
        
        return entries;
    }
    
    private void AddAmenitiesAndServices(Dictionary<string, string> entries)
    {
        var amenityIds = _amenities
            .Where(a => a.IsAvailable)
            .Select(a => a.PtaId.ToString())
            .ToList();
        
        entries[PeriodBasedSearchSchema.UnitFields.AMENITY_IDS] = 
            amenityIds.Any() ? string.Join(",", amenityIds) : "";
        
        var amenityNames = _amenities
            .Where(a => a.IsAvailable && a.PropertyTypeAmenity?.Amenity != null)
            .Select(a => a.PropertyTypeAmenity.Amenity.Name)
            .ToList();
        
        entries[PeriodBasedSearchSchema.UnitFields.AMENITY_NAMES] = 
            amenityNames.Any() ? string.Join(" ", amenityNames) : "";
        
        var serviceIds = _services
            .Select(s => s.Id.ToString())
            .ToList();
        
        entries[PeriodBasedSearchSchema.UnitFields.SERVICE_IDS] = 
            serviceIds.Any() ? string.Join(",", serviceIds) : "";
        
        var serviceNames = _services
            .Select(s => s.Name)
            .ToList();
        
        entries[PeriodBasedSearchSchema.UnitFields.SERVICE_NAMES] = 
            serviceNames.Any() ? string.Join(" ", serviceNames) : "";
    }
    
    private void AddDynamicFields(Dictionary<string, string> entries)
    {
        foreach (var fieldValue in _fieldValues)
        {
            var fieldDef = _fieldDefinitions.FirstOrDefault(fd => fd.Id == fieldValue.UnitTypeFieldId);
            if (fieldDef == null || !fieldDef.IsSearchable)
                continue;
            
            var fieldName = fieldDef.FieldName?.ToLowerInvariant() ?? "";
            if (string.IsNullOrWhiteSpace(fieldName))
                continue;
            
            var value = fieldValue.FieldValue ?? "";
            var fieldType = fieldDef.FieldTypeId?.ToLowerInvariant() ?? "text";
            
            if (fieldType == "number" || fieldType == "numeric" || fieldType == "decimal")
            {
                if (decimal.TryParse(value, NumberStyles.Any, CultureInfo.InvariantCulture, out var numValue))
                {
                    var numericFieldName = PeriodBasedSearchSchema.GetDynamicNumericField(fieldName);
                    entries[numericFieldName] = numValue.ToString(CultureInfo.InvariantCulture);
                }
            }
            else
            {
                var textFieldName = PeriodBasedSearchSchema.GetDynamicTextField(fieldName);
                entries[textFieldName] = value;
            }
        }
    }
    
    private void AddSearchKeywords(Dictionary<string, string> entries)
    {
        var keywords = new List<string>
        {
            _property.Name,
            _unit.Name,
            _property.City,
            _propertyType.Name,
            _unitType.Name,
            _property.Address
        };
        
        keywords.AddRange(_amenities
            .Where(a => a.PropertyTypeAmenity?.Amenity != null)
            .Select(a => a.PropertyTypeAmenity.Amenity.Name));
        
        keywords.AddRange(_services.Select(s => s.Name));
        
        var cleanedKeywords = keywords
            .Where(k => !string.IsNullOrWhiteSpace(k))
            .Select(k => k.Trim())
            .Distinct();
        
        entries[PeriodBasedSearchSchema.UnitFields.SEARCH_KEYWORDS] = 
            string.Join(" ", cleanedKeywords);
    }
    
    private void AddFullDocument(Dictionary<string, string> entries)
    {
        var document = new
        {
            UnitId = _unit.Id,
            UnitName = _unit.Name,
            PropertyId = _property.Id,
            PropertyName = _property.Name,
            City = _property.City,
            Address = _property.Address,
            Latitude = _property.Latitude,
            Longitude = _property.Longitude,
            UnitTypeName = _unitType.Name,
            PropertyTypeName = _propertyType.Name,
            BasePrice = 0,
            Currency = "YER",
            MaxCapacity = _unit.MaxCapacity,
            StarRating = _property.StarRating,
            AverageRating = _property.AverageRating,
            IsApproved = _property.IsApproved,
            IsFeatured = _property.IsFeatured,
        };
        
        entries[PeriodBasedSearchSchema.UnitFields.FULL_DOCUMENT] = 
            JsonSerializer.Serialize(document);
    }
    
    #endregion
    
    #region === بناء مستندات الجداول اليومية ===
    
    /// <summary>
    /// بناء Hash entries لجميع الجداول اليومية
    /// كل DailyUnitSchedule = مستند منفصل في Redis
    /// 
    /// ملاحظة:
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// • نفهرس جميع الجداول التي تحتوي على تسعير أو حالة إتاحة غير متاحة
    /// • الجداول المتاحة بدون تسعير محدد تستخدم السعر الأساسي افتراضياً
    /// </summary>
    public List<(string Key, Dictionary<string, string> Hash)> BuildScheduleHashes()
    {
        var results = new List<(string, Dictionary<string, string>)>();
        
        foreach (var schedule in _schedules)
        {
            var key = PeriodBasedSearchSchema.GetSchedulePeriodKey(schedule.Id);
            var hash = new Dictionary<string, string>
            {
                [PeriodBasedSearchSchema.SchedulePeriodFields.SCHEDULE_ID] = schedule.Id.ToString(),
                [PeriodBasedSearchSchema.SchedulePeriodFields.UNIT_ID] = _unit.Id.ToString(),
                [PeriodBasedSearchSchema.SchedulePeriodFields.PROPERTY_ID] = _property.Id.ToString(),
                [PeriodBasedSearchSchema.SchedulePeriodFields.DATE_TS] = new DateTimeOffset(schedule.Date).ToUnixTimeSeconds().ToString(CultureInfo.InvariantCulture),
                [PeriodBasedSearchSchema.SchedulePeriodFields.STATUS] = schedule.Status ?? "Available"
            };
            
            // إضافة بيانات التسعير إذا كانت موجودة
            if (schedule.PriceAmount.HasValue)
            {
                hash[PeriodBasedSearchSchema.SchedulePeriodFields.PRICE] = schedule.PriceAmount.Value.ToString(CultureInfo.InvariantCulture);
                hash[PeriodBasedSearchSchema.SchedulePeriodFields.CURRENCY] = schedule.Currency ?? "YER";
            }
            
            // إضافة معرف الحجز إذا كان موجوداً
            if (schedule.BookingId.HasValue)
            {
                hash[PeriodBasedSearchSchema.SchedulePeriodFields.BOOKING_ID] = schedule.BookingId.Value.ToString();
            }
            
            // إضافة بيانات إضافية اختيارية
            if (!string.IsNullOrEmpty(schedule.PriceType))
            {
                hash[PeriodBasedSearchSchema.SchedulePeriodFields.PRICE_TYPE] = schedule.PriceType;
            }
            
            if (!string.IsNullOrEmpty(schedule.PricingTier))
            {
                hash[PeriodBasedSearchSchema.SchedulePeriodFields.PRICING_TIER] = schedule.PricingTier;
            }
            
            if (!string.IsNullOrEmpty(schedule.Reason))
            {
                hash[PeriodBasedSearchSchema.SchedulePeriodFields.REASON] = schedule.Reason;
            }
            
            results.Add((key, hash));
        }
        
        return results;
    }
    
    #endregion
}
