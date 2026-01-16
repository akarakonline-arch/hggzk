# PostgreSQL Search & Indexing Implementation

## نظرة عامة

هذا التنفيذ يوفر بديلاً كاملاً لـ Redis للبحث والفلترة، يعمل مباشرة مع قاعدة البيانات الأساسية PostgreSQL.

## المكونات الرئيسية

### 1. PostgresUnitSearchEngine
محرك بحث محسّن يعمل مباشرة مع PostgreSQL باستخدام:
- ✅ **فهارس B-Tree** للبحث السريع
- ✅ **Full-Text Search (GIN)** للبحث النصي
- ✅ **فهارس جغرافية (GiST)** للبحث بالقرب
- ✅ **Composite Indexes** للاستعلامات المركبة
- ✅ **Partial Indexes** للفلترة الانتقائية

#### الميزات:
- بحث متقدم بجميع المعايير (المدينة، النوع، السعر، التقييم، إلخ)
- بحث نصي كامل في الأسماء والأوصاف
- بحث جغرافي بالمسافة
- فلترة ديناميكية للحقول المخصصة
- فلترة التواريخ والإتاحة
- ترتيب متعدد (السعر، التقييم، المسافة، الشعبية)
- Pagination محسّن

### 2. PostgresUnitIndexingService
خدمة فهرسة بسيطة - معظم الدوال فارغة لأن PostgreSQL يدير الفهارس تلقائياً.

#### الدوال المفيدة:
- `RebuildAllIndexesAsync()` - إعادة بناء الفهارس (REINDEX)
- `CleanupIndexesAsync()` - تنظيف البيانات القديمة
- `GetIndexStatisticsAsync()` - جمع الإحصائيات

### 3. AddOptimizedSearchIndexes Migration
Migration يضيف فهارس محسّنة لجميع الجداول الرئيسية.

---

## التثبيت والتكوين

### الخطوة 1: إضافة الخدمات في `Program.cs`

```csharp
using YemenBooking.Infrastructure.Postgres.Configuration;

// في Program.cs:

// الطريقة 1: استخدام PostgreSQL دائماً
builder.Services.AddPostgresSearchServices(builder.Configuration);

// الطريقة 2: استخدام Redis إذا كان متاحاً، وإلا PostgreSQL
if (builder.Configuration.GetValue<bool>("UseRedis"))
{
    builder.Services.AddRedisServices(builder.Configuration);
}
else
{
    builder.Services.AddPostgresSearchServices(builder.Configuration);
}

// الطريقة 3: مع تكوين متقدم
builder.Services.AddPostgresSearchServices(
    builder.Configuration,
    options =>
    {
        options.EnableCaching = true;
        options.CacheDurationMinutes = 10;
        options.EnableFullTextSearch = true;
        options.EnableGeographicSearch = true;
        options.MaxPageSize = 100;
    });
```

### الخطوة 2: إضافة التكوين في `appsettings.json`

```json
{
  "UseRedis": false,
  "PostgresSearch": {
    "EnableCaching": false,
    "CacheDurationMinutes": 5,
    "EnableDetailedLogging": false,
    "MaxPageSize": 100,
    "EnableFullTextSearch": true,
    "EnableGeographicSearch": true,
    "FullTextSearchLanguage": "english"
  }
}
```

### الخطوة 3: تطبيق Migration

```bash
# في مجلد Backend
cd YemenBooking.Api

# إنشاء Migration (إذا لم يكن موجوداً)
dotnet ef migrations add AddOptimizedSearchIndexes --project ../YemenBooking.Infrastructure

# تطبيق Migration
dotnet ef database update --project ../YemenBooking.Infrastructure
```

---

## الاستخدام

### في Controllers أو Services

```csharp
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Indexing.Models;

public class SearchController : ControllerBase
{
    private readonly IUnitSearchEngine _searchEngine;
    private readonly IUnitIndexingService _indexingService;
    
    public SearchController(
        IUnitSearchEngine searchEngine,
        IUnitIndexingService indexingService)
    {
        _searchEngine = searchEngine;
        _indexingService = indexingService;
    }
    
    [HttpPost("search")]
    public async Task<IActionResult> SearchUnits([FromBody] UnitSearchRequest request)
    {
        // البحث عن الوحدات
        var result = await _searchEngine.SearchUnitsAsync(request);
        return Ok(result);
    }
    
    [HttpPost("search/properties")]
    public async Task<IActionResult> SearchProperties([FromBody] PropertyWithUnitsSearchRequest request)
    {
        // البحث المجمّع حسب العقار
        var result = await _searchEngine.SearchPropertiesWithUnitsAsync(request);
        return Ok(result);
    }
    
    [HttpPost("maintenance/reindex")]
    public async Task<IActionResult> RebuildIndexes()
    {
        // إعادة بناء الفهارس
        var count = await _indexingService.RebuildAllIndexesAsync();
        return Ok(new { Message = $"تم إعادة بناء {count} فهرس" });
    }
    
    [HttpGet("statistics")]
    public async Task<IActionResult> GetStatistics()
    {
        // الحصول على الإحصائيات
        var stats = await _indexingService.GetIndexStatisticsAsync();
        return Ok(stats);
    }
}
```

### مثال طلب بحث

```json
{
  "city": "صنعاء",
  "checkIn": "2024-12-01",
  "checkOut": "2024-12-05",
  "minPrice": 100,
  "maxPrice": 500,
  "guestsCount": 2,
  "requiredAmenities": [
    "wifi-guid",
    "parking-guid"
  ],
  "latitude": 15.3694,
  "longitude": 44.1910,
  "radiusKm": 5,
  "sortBy": "price_asc",
  "pageNumber": 1,
  "pageSize": 20
}
```

---

## الفهارس المضافة

### جدول Units
- `IX_Units_PropertyId_IsAvailable` - بحث الوحدات حسب العقار
- `IX_Units_UnitTypeId_IsAvailable` - بحث حسب النوع
- `IX_Units_MaxCapacity` - فلترة السعة
- `IX_Units_CreatedAt_Desc` - ترتيب حسب الأحدث
- `IX_Units_BookingCount_ViewCount` - ترتيب حسب الشعبية
- `IX_Units_Name_FullText` - بحث نصي كامل

### جدول Properties
- `IX_Properties_City_IsApproved` - بحث حسب المدينة
- `IX_Properties_TypeId_IsApproved` - بحث حسب النوع
- `IX_Properties_City_TypeId_IsApproved` - بحث مركب
- `IX_Properties_AverageRating_Desc` - ترتيب حسب التقييم
- `IX_Properties_StarRating_Desc` - ترتيب حسب النجوم
- `IX_Properties_IsFeatured_True` - العقارات المميزة فقط
- `IX_Properties_Location_GiST` - **بحث جغرافي**
- `IX_Properties_Search_FullText` - **بحث نصي كامل**

### جدول UnitAvailabilities
- `IX_UnitAvailabilities_UnitId_Dates` - فلترة التواريخ
- `IX_UnitAvailabilities_Status_Dates` - البحث حسب الحالة
- `IX_UnitAvailabilities_Overlap` - **كشف التعارضات** (GiST)

### جدول PricingRules
- `IX_PricingRules_UnitId_Dates` - قواعد التسعير حسب التواريخ
- `IX_PricingRules_PriceAmount` - فلترة السعر
- `IX_PricingRules_Currency` - فلترة العملة

### جدول UnitFieldValues
- `IX_UnitFieldValues_UnitId_FieldId` - الحقول الديناميكية
- `IX_UnitFieldValues_FieldId_Value` - البحث في القيم

---

## الأداء المتوقع

### مقارنة مع Redis

| المعيار | Redis | PostgreSQL (مع الفهارس) |
|--------|-------|------------------------|
| بحث بسيط (مدينة فقط) | ~10ms | ~15-25ms |
| بحث متوسط (مدينة + تواريخ) | ~30ms | ~40-60ms |
| بحث معقد (جميع المعايير) | ~50-80ms | ~80-120ms |
| استهلاك الذاكرة | عالي | منخفض |
| تزامن البيانات | يحتاج فهرسة | تلقائي |
| تعقيد النشر | يحتاج سيرفر Redis | لا يحتاج شيء إضافي |

### ملاحظات الأداء:
- ✅ PostgreSQL أبطأ قليلاً لكن الفرق مقبول (50-80ms فرق)
- ✅ لا حاجة لمزامنة البيانات مع نظام خارجي
- ✅ استهلاك ذاكرة أقل بكثير
- ✅ نشر أبسط (لا حاجة لـ Redis)
- ✅ تكلفة أقل (لا حاجة لسيرفر منفصل)

---

## التحسينات الإضافية الموصى بها

### 1. إضافة Materialized Views للبحث الأسرع

```sql
-- عرض مادي للوحدات المتاحة مع جميع البيانات
CREATE MATERIALIZED VIEW mv_available_units AS
SELECT 
    u."Id" as unit_id,
    u."Name" as unit_name,
    u."IsAvailable",
    u."MaxCapacity",
    u."BasePrice_Amount" as base_price,
    u."BasePrice_Currency" as currency,
    p."Id" as property_id,
    p."Name" as property_name,
    p."City",
    p."TypeId" as property_type_id,
    p."AverageRating",
    p."StarRating",
    p."Latitude",
    p."Longitude",
    p."IsFeatured",
    p."IsApproved",
    ut."Name" as unit_type_name
FROM "Units" u
INNER JOIN "Properties" p ON u."PropertyId" = p."Id"
INNER JOIN "UnitTypes" ut ON u."UnitTypeId" = ut."Id"
WHERE u."IsAvailable" = true 
  AND p."IsApproved" = true;

-- إنشاء فهارس على الـ View
CREATE INDEX idx_mv_available_units_city 
ON mv_available_units (city, is_approved);

CREATE INDEX idx_mv_available_units_location 
ON mv_available_units USING gist (point(longitude, latitude));

-- تحديث الـ View دورياً (كل ساعة مثلاً)
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_available_units;
```

### 2. إضافة Partitioning للبيانات الكبيرة

```sql
-- تقسيم UnitAvailabilities حسب السنة
CREATE TABLE unit_availabilities_2024 
PARTITION OF "UnitAvailabilities"
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE unit_availabilities_2025 
PARTITION OF "UnitAvailabilities"
FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');
```

### 3. إضافة Connection Pooling

```csharp
// في Program.cs
builder.Services.AddDbContextPool<YemenBookingDbContext>(options =>
{
    options.UseNpgsql(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        npgsqlOptions =>
        {
            npgsqlOptions.EnableRetryOnFailure(
                maxRetryCount: 3,
                maxRetryDelay: TimeSpan.FromSeconds(5),
                errorCodesToAdd: null);
            
            // تفعيل Command Timeout
            npgsqlOptions.CommandTimeout(30);
        });
}, poolSize: 128); // حجم Pool
```

### 4. إضافة Query Caching

```csharp
// باستخدام EF Core Second Level Cache
builder.Services.AddEFSecondLevelCache(options =>
{
    options.UseMemoryCacheProvider();
    options.CacheAllQueries(CacheExpirationMode.Sliding, TimeSpan.FromMinutes(5));
});
```

---

## الصيانة

### تحديث الإحصائيات

```sql
-- تحديث إحصائيات جميع الجداول
ANALYZE "Units";
ANALYZE "Properties";
ANALYZE "UnitAvailabilities";
ANALYZE "PricingRules";
```

### إعادة بناء الفهارس

```sql
-- إعادة بناء جميع الفهارس
REINDEX TABLE "Units";
REINDEX TABLE "Properties";
REINDEX TABLE "UnitAvailabilities";
REINDEX TABLE "PricingRules";
```

### تنظيف قاعدة البيانات

```sql
-- تنظيف البيانات القديمة واسترجاع المساحة
VACUUM ANALYZE "Units";
VACUUM ANALYZE "Properties";
VACUUM ANALYZE "UnitAvailabilities";
VACUUM ANALYZE "PricingRules";
```

### جدولة المهام الدورية

```csharp
// في Program.cs - إضافة Background Service
public class DatabaseMaintenanceService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<DatabaseMaintenanceService> _logger;
    
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var indexingService = scope.ServiceProvider
                    .GetRequiredService<IUnitIndexingService>();
                
                // تنظيف كل 6 ساعات
                await indexingService.CleanupIndexesAsync(stoppingToken);
                
                await Task.Delay(TimeSpan.FromHours(6), stoppingToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في الصيانة الدورية");
            }
        }
    }
}

// تسجيل الخدمة
builder.Services.AddHostedService<DatabaseMaintenanceService>();
```

---

## الخلاصة

### متى تستخدم PostgreSQL بدلاً من Redis؟

✅ **استخدم PostgreSQL إذا:**
- ليس لديك سيرفر مخصص لـ Redis
- تريد تقليل التعقيد والتكاليف
- البيانات ليست ضخمة جداً (< مليون وحدة)
- الأداء المقبول هو 50-150ms
- تريد استهلاك ذاكرة أقل

❌ **استخدم Redis إذا:**
- لديك سيرفر مخصص لـ Redis
- تحتاج أداء عالي جداً (< 50ms)
- البيانات ضخمة جداً (> مليون وحدة)
- تريد أقصى سرعة ممكنة

### التبديل بين PostgreSQL و Redis

الكود مصمم للعمل مع كلا الواجهتين بنفس الطريقة، يمكنك التبديل بسهولة:

```csharp
// في Program.cs
var useRedis = builder.Configuration.GetValue<bool>("UseRedis");

if (useRedis)
{
    builder.Services.AddRedisServices(builder.Configuration);
}
else
{
    builder.Services.AddPostgresSearchServices(builder.Configuration);
}
```

---

## الدعم والمساهمة

إذا واجهت أي مشاكل أو لديك اقتراحات للتحسين، يرجى فتح Issue أو Pull Request.

---

**آخر تحديث:** نوفمبر 2024  
**الإصدار:** 1.0.0
