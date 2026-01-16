namespace YemenBooking.Core.Indexing.RediSearch;

/// <summary>
/// Schema محسّن للبحث المباشر في التواريخ على مستوى Redis
/// 
/// الاستراتيجية:
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// فهرسة نوعين من المستندات:
/// 
/// 1. المستند الرئيسي للوحدة: unit:{unitId}
///    - جميع البيانات الأساسية للوحدة
///    - المدينة، نوع العقار، نوع الوحدة، إلخ
///    - بدون IS_AVAILABLE (نحذفه تماماً)
///    - بدون MIN/MAX prices (نحذفهم تماماً)
/// 
/// 2. مستندات الجدول اليومي: period:schedule:{scheduleId}
///    - scheduleId (TAG) - معرف الجدول
///    - unitId (TAG, SORTABLE) - معرف الوحدة
///    - propertyId (TAG) - معرف العقار
///    - dateTs (NUMERIC, SORTABLE) - timestamp التاريخ اليومي
///    - status (TAG) - Available / Blocked / Booked
///    - price (NUMERIC, SORTABLE) - السعر (اختياري)
///    - currency (TAG) - العملة (اختياري)
///    - bookingId (TAG) - معرف الحجز (اختياري)
///    - priceType (TAG) - نوع التسعير (اختياري)
///    - pricingTier (TAG) - مستوى التسعير (اختياري)
///    - reason (TEXT) - السبب أو ملاحظات (اختياري)
/// 
/// استراتيجية البحث:
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// عند البحث بتواريخ (CheckIn, CheckOut):
/// 
/// 1. البحث عن الوحدات المتاحة:
///    - نبحث في idx:periods:schedule عن أيام محجوزة تتقاطع مع (CheckIn, CheckOut)
///    - نستثني UnitIds الموجودة في النتيجة
///    
/// 2. حساب السعر:
///    - نبحث في idx:periods:schedule عن الأيام ضمن النطاق (CheckIn, CheckOut)
///    - نجمع الأسعار ونحسب المجموع
///    
/// 3. الفلترة النهائية:
///    - نبحث في idx:units عن الوحدات المتبقية بالمعايير الأخرى
/// </summary>
public static class PeriodBasedSearchSchema
{
    #region === Units Index (الوحدات) ===
    
    public const string UNITS_INDEX = "idx:units:v3";
    public const string UNITS_PREFIX = "unit:";
    
    /// <summary>
    /// حقول مستند الوحدة (بدون IS_AVAILABLE وبدون MIN/MAX prices)
    /// </summary>
    public static class UnitFields
    {
        public const string UNIT_ID = "unitId";
        public const string PROPERTY_ID = "propertyId";
        public const string UNIT_NAME = "unitName";
        public const string PROPERTY_NAME = "propertyName";
        
        // الفلتر 1: المدينة
        public const string CITY = "city";
        
        // الفلتر 2: نوع العقار
        public const string PROPERTY_TYPE_ID = "propertyTypeId";
        public const string PROPERTY_TYPE_NAME = "propertyTypeName";
        
        // الفلتر 3: نوع الوحدة
        public const string UNIT_TYPE_ID = "unitTypeId";
        public const string UNIT_TYPE_NAME = "unitTypeName";
        
        public const string OWNER_ID = "ownerId";
        public const string IS_APPROVED = "isApproved";
        public const string IS_FEATURED = "isFeatured";
        public const string STAR_RATING = "starRating";
        public const string AVERAGE_RATING = "averageRating";
        
        // الموقع الجغرافي
        public const string ADDRESS = "address";
        public const string LOCATION = "location";
        public const string LATITUDE = "latitude";
        public const string LONGITUDE = "longitude";
        
        // السعة
        public const string MAX_CAPACITY = "maxCapacity";
        public const string ADULTS_CAPACITY = "adultsCapacity";
        public const string CHILDREN_CAPACITY = "childrenCapacity";
        
        // السعر الأساسي (للرجوع فقط، ليس للبحث)
        public const string BASE_PRICE = "basePrice";
        public const string CURRENCY = "currency";
        
        // الفلتر 6: المرافق
        public const string AMENITY_IDS = "amenityIds";
        public const string AMENITY_NAMES = "amenityNames";
        
        // الفلتر 7: الخدمات
        public const string SERVICE_IDS = "serviceIds";
        public const string SERVICE_NAMES = "serviceNames";
        
        // الحقول الديناميكية - الفلتر 5
        public const string DYNAMIC_FIELD_PREFIX = "df_";
        public const string DYNAMIC_NUMERIC_PREFIX = "dfn_";
        
        // بيانات وصفية
        public const string VIEW_COUNT = "viewCount";
        public const string BOOKING_COUNT = "bookingCount";
        public const string INDEXED_AT = "indexedAt";
        
        // الكلمات المفتاحية
        public const string SEARCH_KEYWORDS = "searchKeywords";
        
        // المستند الكامل
        public const string FULL_DOCUMENT = "_doc";
    }
    
    public static string[] GetCreateUnitsIndexCommand()
    {
        return new[]
        {
            "FT.CREATE", UNITS_INDEX,
            "ON", "HASH",
            "PREFIX", "1", UNITS_PREFIX,
            "SCHEMA",
            
            UnitFields.UNIT_ID, "TAG", "SORTABLE",
            UnitFields.PROPERTY_ID, "TAG", "SORTABLE",
            UnitFields.UNIT_NAME, "TEXT", "WEIGHT", "2.0", "SORTABLE",
            UnitFields.PROPERTY_NAME, "TEXT", "WEIGHT", "1.5", "SORTABLE",
            UnitFields.CITY, "TAG", "SORTABLE",
            UnitFields.PROPERTY_TYPE_ID, "TAG", "SORTABLE",
            UnitFields.PROPERTY_TYPE_NAME, "TEXT",
            UnitFields.UNIT_TYPE_ID, "TAG", "SORTABLE",
            UnitFields.UNIT_TYPE_NAME, "TEXT",
            UnitFields.OWNER_ID, "TAG",
            UnitFields.IS_APPROVED, "TAG",
            UnitFields.IS_FEATURED, "TAG",
            UnitFields.STAR_RATING, "NUMERIC", "SORTABLE",
            UnitFields.AVERAGE_RATING, "NUMERIC", "SORTABLE",
            
            UnitFields.ADDRESS, "TEXT",
            UnitFields.LOCATION, "GEO", "SORTABLE",
            UnitFields.LATITUDE, "NUMERIC", "SORTABLE",
            UnitFields.LONGITUDE, "NUMERIC", "SORTABLE",
            
            UnitFields.MAX_CAPACITY, "NUMERIC", "SORTABLE",
            UnitFields.ADULTS_CAPACITY, "NUMERIC", "SORTABLE",
            UnitFields.CHILDREN_CAPACITY, "NUMERIC", "SORTABLE",
            
            UnitFields.BASE_PRICE, "NUMERIC",
            UnitFields.CURRENCY, "TAG",
            
            UnitFields.AMENITY_IDS, "TAG", "SEPARATOR", ",",
            UnitFields.AMENITY_NAMES, "TEXT",
            UnitFields.SERVICE_IDS, "TAG", "SEPARATOR", ",",
            UnitFields.SERVICE_NAMES, "TEXT",
            
            UnitFields.VIEW_COUNT, "NUMERIC", "SORTABLE",
            UnitFields.BOOKING_COUNT, "NUMERIC", "SORTABLE",
            UnitFields.INDEXED_AT, "NUMERIC", "SORTABLE",
            
            UnitFields.SEARCH_KEYWORDS, "TEXT", "WEIGHT", "1.0"
        };
    }
    
    #endregion
    
    #region === Schedule Periods Index (جدول الوحدات اليومي) ===
    
    public const string SCHEDULE_INDEX = "idx:periods:schedule";
    public const string SCHEDULE_PREFIX = "period:schedule:";
    
    /// <summary>
    /// حقول مستند جدول اليوم للوحدة
    /// </summary>
    public static class SchedulePeriodFields
    {
        /// <summary>معرف الجدول اليومي</summary>
        public const string SCHEDULE_ID = "scheduleId";
        
        /// <summary>معرف الوحدة المرتبطة</summary>
        public const string UNIT_ID = "unitId";
        
        /// <summary>معرف العقار (للفلترة السريعة)</summary>
        public const string PROPERTY_ID = "propertyId";
        
        /// <summary>timestamp التاريخ اليومي (NUMERIC للبحث بالنطاق)</summary>
        public const string DATE_TS = "dateTs";
        
        /// <summary>حالة اليوم: Available / Blocked / Booked</summary>
        public const string STATUS = "status";
        
        /// <summary>السعر لهذا اليوم (اختياري)</summary>
        public const string PRICE = "price";
        
        /// <summary>العملة (اختياري)</summary>
        public const string CURRENCY = "currency";
        
        /// <summary>معرف الحجز (اختياري)</summary>
        public const string BOOKING_ID = "bookingId";
        
        /// <summary>نوع التسعير (اختياري)</summary>
        public const string PRICE_TYPE = "priceType";
        
        /// <summary>مستوى التسعير (اختياري)</summary>
        public const string PRICING_TIER = "pricingTier";
        
        /// <summary>السبب أو ملاحظات (اختياري)</summary>
        public const string REASON = "reason";
    }
    
    public static string[] BuildSchedulePeriodIndexSchema()
    {
        return new[]
        {
            "FT.CREATE", SCHEDULE_INDEX,
            "ON", "HASH",
            "PREFIX", "1", SCHEDULE_PREFIX,
            "SCHEMA",
            
            SchedulePeriodFields.SCHEDULE_ID, "TAG",
            SchedulePeriodFields.UNIT_ID, "TAG", "SORTABLE",
            SchedulePeriodFields.PROPERTY_ID, "TAG",
            SchedulePeriodFields.DATE_TS, "NUMERIC", "SORTABLE",
            SchedulePeriodFields.STATUS, "TAG",
            SchedulePeriodFields.PRICE, "NUMERIC", "SORTABLE",
            SchedulePeriodFields.CURRENCY, "TAG",
            SchedulePeriodFields.BOOKING_ID, "TAG",
            SchedulePeriodFields.PRICE_TYPE, "TAG",
            SchedulePeriodFields.PRICING_TIER, "TAG",
            SchedulePeriodFields.REASON, "TEXT"
        };
    }
    
    #endregion
    
    #region === Helper Methods ===
    
    /// <summary>
    /// الحصول على اسم حقل ديناميكي نصي
    /// </summary>
    public static string GetDynamicTextField(string fieldName) 
        => $"{UnitFields.DYNAMIC_FIELD_PREFIX}{fieldName.ToLowerInvariant()}";
    
    /// <summary>
    /// الحصول على اسم حقل ديناميكي رقمي
    /// </summary>
    public static string GetDynamicNumericField(string fieldName) 
        => $"{UnitFields.DYNAMIC_NUMERIC_PREFIX}{fieldName.ToLowerInvariant()}";
    
    /// <summary>
    /// بناء مفتاح وحدة
    /// </summary>
    public static string GetUnitKey(Guid unitId) => $"{UNITS_PREFIX}{unitId}";
    
    /// <summary>
    /// بناء مفتاح جدول يومي
    /// </summary>
    public static string GetSchedulePeriodKey(Guid scheduleId) => $"{SCHEDULE_PREFIX}{scheduleId}";
    
    /// <summary>
    /// حذف جميع الفهارس
    /// </summary>
    public static string[][] GetDropAllIndexesCommands(bool deleteDocuments = false)
    {
        var suffix = deleteDocuments ? new[] { "DD" } : Array.Empty<string>();
        
        return new[]
        {
            new[] { "FT.DROPINDEX", UNITS_INDEX }.Concat(suffix).ToArray(),
            new[] { "FT.DROPINDEX", SCHEDULE_INDEX }.Concat(suffix).ToArray()
        };
    }
    
    #endregion
}
