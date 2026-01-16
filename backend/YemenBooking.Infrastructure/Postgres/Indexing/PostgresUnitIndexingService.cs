using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Postgres.Indexing;

/// <summary>
/// خدمة الفهرسة لـ PostgreSQL
/// تنفيذ IUnitIndexingService للعمل مع قاعدة البيانات الأساسية
/// 
/// ملاحظة مهمة:
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// PostgreSQL لا يحتاج إلى فهرسة منفصلة لأن البيانات موجودة بالفعل في قاعدة البيانات
/// معظم الدوال هنا فارغة أو بسيطة جداً لأن:
/// • البيانات تُحدّث مباشرة في الجداول
/// • الفهارس (Indexes) تُدار تلقائياً من PostgreSQL
/// • لا حاجة لمزامنة مع نظام خارجي مثل Redis
/// 
/// الدوال المفيدة فقط:
/// • GetIndexStatisticsAsync - لجمع إحصائيات من قاعدة البيانات
/// • RebuildAllIndexesAsync - لإعادة بناء الفهارس (REINDEX)
/// </summary>
public sealed class PostgresUnitIndexingService : IUnitIndexingService
{
    #region === الحقول الخاصة ===
    
    private readonly YemenBookingDbContext _context;
    private readonly ILogger<PostgresUnitIndexingService> _logger;
    private readonly PostgresUnitSearchEngine _searchEngine;
    
    #endregion
    
    #region === البناء ===
    
    public PostgresUnitIndexingService(
        YemenBookingDbContext context,
        ILogger<PostgresUnitIndexingService> logger,
        PostgresUnitSearchEngine searchEngine)
    {
        _context = context ?? throw new ArgumentNullException(nameof(context));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _searchEngine = searchEngine ?? throw new ArgumentNullException(nameof(searchEngine));
    }
    
    #endregion
    
    #region === عمليات الوحدة (Unit Operations) ===
    
    /// <summary>
    /// فهرسة وحدة جديدة - غير مطلوب لـ PostgreSQL
    /// البيانات موجودة بالفعل في قاعدة البيانات
    /// </summary>
    public Task<bool> OnUnitCreatedAsync(Guid unitId, CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("PostgreSQL: تم إنشاء وحدة {UnitId} - لا حاجة للفهرسة", unitId);
        return Task.FromResult(true);
    }
    
    /// <summary>
    /// تحديث فهرسة وحدة - غير مطلوب لـ PostgreSQL
    /// </summary>
    public Task<bool> OnUnitUpdatedAsync(Guid unitId, CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("PostgreSQL: تم تحديث وحدة {UnitId} - لا حاجة للفهرسة", unitId);
        return Task.FromResult(true);
    }
    
    /// <summary>
    /// حذف فهرسة وحدة - غير مطلوب لـ PostgreSQL
    /// </summary>
    public Task<bool> OnUnitDeletedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("PostgreSQL: تم حذف وحدة {UnitId} - لا حاجة لحذف الفهرسة", unitId);
        return Task.FromResult(true);
    }
    
    #endregion
    
    #region === عمليات نوع الوحدة (Unit Type Operations) ===
    
    /// <summary>
    /// معالجة حذف نوع وحدة - غير مطلوب لـ PostgreSQL
    /// </summary>
    public Task<int> OnUnitTypeDeletedAsync(Guid unitTypeId, CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("PostgreSQL: تم حذف نوع وحدة {UnitTypeId} - لا حاجة لإعادة الفهرسة", unitTypeId);
        return Task.FromResult(0);
    }
    
    /// <summary>
    /// معالجة تحديث حقل ديناميكي - غير مطلوب لـ PostgreSQL
    /// </summary>
    public Task<int> OnUnitTypeFieldUpdatedAsync(
        string oldFieldName,
        string newFieldName,
        string fieldTypeId,
        bool isPrimaryFilter,
        Guid unitTypeId,
        CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("PostgreSQL: تم تحديث حقل {OldFieldName} → {NewFieldName} - لا حاجة لإعادة الفهرسة", 
            oldFieldName, newFieldName);
        return Task.FromResult(0);
    }
    
    /// <summary>
    /// معالجة حذف حقل ديناميكي - غير مطلوب لـ PostgreSQL
    /// </summary>
    public Task<int> OnUnitTypeFieldDeletedAsync(
        string fieldName,
        Guid unitTypeId,
        CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("PostgreSQL: تم حذف حقل {FieldName} - لا حاجة لإعادة الفهرسة", fieldName);
        return Task.FromResult(0);
    }
    
    #endregion
    
    #region === عمليات العقار (Property Operations) ===
    
    /// <summary>
    /// فهرسة عقار جديد - غير مطلوب لـ PostgreSQL
    /// </summary>
    public Task<int> OnPropertyCreatedAsync(Guid propertyId, CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("PostgreSQL: تم إنشاء عقار {PropertyId} - لا حاجة للفهرسة", propertyId);
        return Task.FromResult(0);
    }
    
    /// <summary>
    /// تحديث عقار - غير مطلوب لـ PostgreSQL
    /// </summary>
    public Task<int> OnPropertyUpdatedAsync(Guid propertyId, CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("PostgreSQL: تم تحديث عقار {PropertyId} - لا حاجة لإعادة الفهرسة", propertyId);
        return Task.FromResult(0);
    }
    
    /// <summary>
    /// حذف عقار - غير مطلوب لـ PostgreSQL
    /// </summary>
    public Task<int> OnPropertyDeletedAsync(Guid propertyId, CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("PostgreSQL: تم حذف عقار {PropertyId} - لا حاجة لحذف الفهرسة", propertyId);
        return Task.FromResult(0);
    }
    
    #endregion
    
    #region === عمليات الإتاحة والتسعير (Availability & Pricing) ===
    
    /// <summary>
    /// تحديث إتاحة وحدة - غير مطلوب لـ PostgreSQL
    /// </summary>
    public Task<bool> OnAvailabilityChangedAsync(Guid unitId, CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("PostgreSQL: تم تحديث إتاحة وحدة {UnitId} - لا حاجة لتحديث الفهرسة", unitId);
        return Task.FromResult(true);
    }
    
    /// <summary>
    /// تحديث تسعير وحدة - غير مطلوب لـ PostgreSQL
    /// </summary>
    public Task<bool> OnDailyScheduleChangedAsync(Guid unitId, CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("PostgreSQL: تم تحديث الجداول اليومية للوحدة {UnitId} - لا حاجة لتحديث الفهرسة", unitId);
        return Task.FromResult(true);
    }
    
    #endregion
    
    #region === البحث (Search) ===
    
    /// <summary>
    /// البحث عن الوحدات - يتم تنفيذه في PostgresUnitSearchEngine
    /// هذه الدالة موجودة فقط للتوافق مع الواجهة
    /// </summary>
    public async Task<UnitSearchResult> SearchUnitsAsync(
        UnitSearchRequest request,
        CancellationToken cancellationToken = default)
    {
        _logger.LogWarning("PostgreSQL: تم استدعاء SearchUnitsAsync من PostgresUnitIndexingService - " +
                          "يجب استخدام PostgresUnitSearchEngine بدلاً من ذلك");
        
        // يمكن إنشاء instance من PostgresUnitSearchEngine هنا إذا لزم الأمر
        // أو ببساطة إرجاع نتيجة فارغة
        return new UnitSearchResult
        {
            Units = new List<UnitSearchItem>(),
            TotalCount = 0,
            PageNumber = request.PageNumber,
            PageSize = request.PageSize
        };
    }
    
    /// <summary>
    /// البحث عن العقارات مع الوحدات - يتم تنفيذه في PostgresUnitSearchEngine
    /// ✅ FIX: استدعاء PostgresUnitSearchEngine بدلاً من إرجاع نتائج فارغة
    /// </summary>
    public async Task<PropertyWithUnitsSearchResult> SearchPropertiesWithUnitsAsync(
        PropertyWithUnitsSearchRequest request,
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("PostgreSQL: استدعاء البحث المحسّن عبر PostgresUnitSearchEngine");
        
        // ✅ استدعاء محرك البحث المحسّن
        return await _searchEngine.SearchPropertiesWithUnitsAsync(request, cancellationToken);
    }
    
    #endregion
    
    #region === الصيانة (Maintenance) ===
    
    /// <summary>
    /// إعادة بناء فهرس وحدة - غير مطلوب لـ PostgreSQL
    /// </summary>
    public Task<bool> RebuildUnitIndexAsync(Guid unitId, CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("PostgreSQL: طلب إعادة بناء فهرس وحدة {UnitId} - غير مطلوب", unitId);
        return Task.FromResult(true);
    }
    
    /// <summary>
    /// إعادة بناء فهارس عقار - غير مطلوب لـ PostgreSQL
    /// </summary>
    public Task<int> RebuildPropertyUnitsIndexAsync(Guid propertyId, CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("PostgreSQL: طلب إعادة بناء فهارس عقار {PropertyId} - غير مطلوب", propertyId);
        return Task.FromResult(0);
    }
    
    /// <summary>
    /// إعادة بناء جميع الفهارس
    /// في PostgreSQL: إعادة بناء الفهارس الفعلية باستخدام REINDEX
    /// </summary>
    public async Task<int> RebuildAllIndexesAsync(int batchSize = 100, CancellationToken cancellationToken = default)
    {
        try
        {
            _logger.LogInformation("PostgreSQL: بدء إعادة بناء جميع الفهارس...");
            
            // الحصول على قائمة الجداول الرئيسية
            var tables = new[]
            {
                "\"Units\"",
                "\"Properties\"",
                "\"DailyUnitSchedules\"",
                "\"UnitFieldValues\"",
                "\"PropertyAmenities\"",
                "\"PropertyServices\""
            };
            
            foreach (var table in tables)
            {
                try
                {
                    // إعادة بناء فهارس الجدول
                    await _context.Database.ExecuteSqlRawAsync(
                        $"REINDEX TABLE {table};",
                        cancellationToken);
                    
                    _logger.LogInformation("PostgreSQL: تم إعادة بناء فهارس جدول {Table}", table);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "PostgreSQL: خطأ أثناء إعادة بناء فهارس جدول {Table}", table);
                }
            }
            
            // تحديث الإحصائيات
            await _context.Database.ExecuteSqlRawAsync("ANALYZE;", cancellationToken);
            
            _logger.LogInformation("PostgreSQL: اكتمل إعادة بناء جميع الفهارس");
            
            return tables.Length;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "PostgreSQL: خطأ أثناء إعادة بناء الفهارس");
            return 0;
        }
    }
    
    /// <summary>
    /// تنظيف الفهارس
    /// في PostgreSQL: تنظيف البيانات القديمة والإحصائيات
    /// </summary>
    public async Task<int> CleanupIndexesAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            _logger.LogInformation("PostgreSQL: بدء تنظيف البيانات...");
            
            var cleanedCount = 0;
            
            // حذف الجداول اليومية القديمة جداً (أقدم من سنة)
            var oneYearAgo = DateTime.UtcNow.AddYears(-1);
            var deletedSchedules = await _context.Database.ExecuteSqlRawAsync(
                "DELETE FROM \"DailyUnitSchedules\" WHERE \"Date\" < {0};",
                oneYearAgo,
                cancellationToken);
            
            cleanedCount += deletedSchedules;
            _logger.LogInformation("PostgreSQL: تم حذف {Count} جدول يومي قديم", deletedSchedules);
            
            // تنظيف قاعدة البيانات (VACUUM)
            await _context.Database.ExecuteSqlRawAsync("VACUUM ANALYZE;", cancellationToken);
            
            _logger.LogInformation("PostgreSQL: اكتمل التنظيف - تم حذف {Count} سجل", cleanedCount);
            
            return cleanedCount;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "PostgreSQL: خطأ أثناء التنظيف");
            return 0;
        }
    }
    
    #endregion
    
    #region === الإحصائيات (Statistics) ===
    
    /// <summary>
    /// الحصول على إحصائيات الفهرس
    /// في PostgreSQL: جمع إحصائيات من قاعدة البيانات
    /// ⚠️ حساب الوحدات المتاحة من DailyUnitSchedules (الكيان الموحد الجديد)
    /// </summary>
    public async Task<Dictionary<string, object>> GetIndexStatisticsAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var statistics = new Dictionary<string, object>();
            
            // 1. إجمالي عدد الوحدات
            var totalUnits = await _context.Units.CountAsync(cancellationToken);
            statistics["TotalUnits"] = totalUnits;
            
            // 2. عدد الوحدات المتاحة - يُحسب من DailyUnitSchedules
            // الوحدة متاحة إذا:
            // - لا يوجد لها سجل في DailyUnitSchedules بحالة غير متاحة
            // - أو لديها سجل بحالة "Available"
            var currentDate = DateTime.UtcNow.Date;
            var futureDate = currentDate.AddMonths(3); // نافذة 3 أشهر
            
            // الوحدات التي لديها حجوزات أو blocking في الفترة القادمة
            var unavailableUnitIds = await _context.Set<DailyUnitSchedule>()
                .Where(s => 
                    s.Status != "Available" &&
                    s.Date >= currentDate &&
                    s.Date < futureDate)
                .Select(s => s.UnitId)
                .Distinct()
                .ToListAsync(cancellationToken);
            
            var availableUnits = totalUnits - unavailableUnitIds.Count;
            statistics["AvailableUnits"] = availableUnits;
            statistics["UnavailableUnits"] = unavailableUnitIds.Count;
            
            // 3. إجمالي عدد العقارات
            var totalProperties = await _context.Properties.CountAsync(cancellationToken);
            statistics["TotalProperties"] = totalProperties;
            
            // 4. توزيع الوحدات حسب المدن
            var unitsByCity = await _context.Units
                .Include(u => u.Property)
                .GroupBy(u => u.Property.City)
                .Select(g => new { City = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.City, x => (object)x.Count, cancellationToken);
            
            statistics["UnitsByCity"] = unitsByCity;
            
            // 5. توزيع الوحدات حسب الأنواع
            var unitsByType = await _context.Units
                .Include(u => u.UnitType)
                .GroupBy(u => u.UnitType.Name)
                .Select(g => new { Type = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.Type, x => (object)x.Count, cancellationToken);
            
            statistics["UnitsByType"] = unitsByType;
            
            // 6. نطاقات الأسعار
            var priceStats = new
            {
                MinPrice = 0m,
                MaxPrice = 0m,
                AvgPrice = 0m
            };
            
            if (priceStats != null)
            {
                statistics["MinPrice"] = priceStats.MinPrice;
                statistics["MaxPrice"] = priceStats.MaxPrice;
                statistics["AvgPrice"] = priceStats.AvgPrice;
            }
            
            // 7. إحصائيات DailyUnitSchedules
            var totalScheduleRecords = await _context.DailyUnitSchedules.CountAsync(cancellationToken);
            statistics["TotalScheduleRecords"] = totalScheduleRecords;
            
            var scheduleByStatus = await _context.DailyUnitSchedules
                .GroupBy(ds => ds.Status)
                .Select(g => new { Status = g.Key, Count = g.Count() })
                .ToDictionaryAsync(x => x.Status, x => (object)x.Count, cancellationToken);
            
            statistics["ScheduleByStatus"] = scheduleByStatus;
            
            // 9. حجم قاعدة البيانات (تقريبي)
            var dbSize = await _context.Database.ExecuteSqlRawAsync(
                "SELECT pg_size_pretty(pg_database_size(current_database()));",
                cancellationToken);
            
            statistics["DatabaseSize"] = $"~{dbSize}";
            
            // 10. عدد الفهارس
            var indexCount = await _context.Database.ExecuteSqlRawAsync(
                @"SELECT COUNT(*) 
                  FROM pg_indexes 
                  WHERE schemaname = 'public' 
                  AND tablename IN ('Units', 'Properties', 'DailyUnitSchedules');",
                cancellationToken);
            
            statistics["TotalIndexes"] = indexCount;
            
            _logger.LogInformation("PostgreSQL: تم جمع الإحصائيات بنجاح");
            
            return statistics;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "PostgreSQL: خطأ أثناء جمع الإحصائيات");
            
            return new Dictionary<string, object>
            {
                { "Error", ex.Message }
            };
        }
    }
    
    #endregion
}
