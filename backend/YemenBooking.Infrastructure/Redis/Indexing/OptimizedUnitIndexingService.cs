using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using StackExchange.Redis;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Core.Indexing.RediSearch;
using YemenBooking.Core.Settings;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Infrastructure.Redis.Core.Interfaces;

namespace YemenBooking.Infrastructure.Redis.Indexing;

/// <summary>
/// خدمة الفهرسة المحسّنة - النسخة الجديدة المعتمدة على Period-Based Search
/// 
/// الاستراتيجية:
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// فهرسة ثلاثة أنواع من المستندات في Redis:
/// 
/// 1. مستند الوحدة الرئيسي: unit:{unitId}
///    - جميع البيانات الأساسية (المدينة، النوع، المرافق، الخدمات، الحقول الديناميكية)
///    - بدون IS_AVAILABLE (تم حذفه تماماً)
///    - بدون MIN/MAX prices (تم حذفهم تماماً)
/// 
/// 2. مستندات فترات التسعير: period:price:{pricingRuleId}
///    - كل DailyUnitSchedule = مستند منفصل
///    - يحتوي على: unitId, dateTs, price, status, currency
/// 
/// 3. مستندات الجداول اليومية: daily:schedule:{scheduleId}
///    - كل DailyUnitSchedule = مستند منفصل
///    - يحتوي على: unitId, date, status, priceAmount
/// 
/// آلية البحث متعددة المراحل:
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// 1. البحث في idx:periods:avail عن فترات محجوزة تتقاطع مع التواريخ المطلوبة
/// 2. استثناء UnitIds المحجوزة
/// 3. البحث في idx:units بالمعايير الأخرى
/// 4. لكل وحدة متبقية، حساب السعر الإجمالي من idx:periods:price
/// </summary>
public sealed class OptimizedUnitIndexingService : IUnitIndexingService, IDisposable
{
    #region === الحقول الخاصة ===
    
    private readonly IServiceProvider _serviceProvider;
    private readonly IRedisConnectionManager _redisManager;
    private readonly ILogger<OptimizedUnitIndexingService> _logger;
    private readonly IndexingSettings _settings;
    private readonly SemaphoreSlim _indexingLock;
    private readonly SemaphoreSlim _parallelProcessingSemaphore;
    private readonly IUnitSearchEngine _searchEngine;
    private bool _disposed;
    
    #endregion
    
    #region === البناء والتهيئة ===
    
    /// <summary>
    /// إنشاء خدمة الفهرسة المحسّنة
    /// </summary>
    public OptimizedUnitIndexingService(
        IServiceProvider serviceProvider,
        IRedisConnectionManager redisManager,
        ILogger<OptimizedUnitIndexingService> logger,
        IOptions<IndexingSettings> settings,
        IUnitSearchEngine searchEngine)
    {
        _serviceProvider = serviceProvider ?? throw new ArgumentNullException(nameof(serviceProvider));
        _redisManager = redisManager ?? throw new ArgumentNullException(nameof(redisManager));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _searchEngine = searchEngine ?? throw new ArgumentNullException(nameof(searchEngine));
        
        _settings = settings?.Value ?? throw new ArgumentNullException(nameof(settings));
        _settings.Validate();
        
        _indexingLock = new SemaphoreSlim(_settings.GetMaxDegreeOfParallelism() * 2);
        _parallelProcessingSemaphore = new SemaphoreSlim(10); // حد أقصى 10 عمليات متزامنة
    }
    
    /// <summary>
    /// إنشاء الفهارس الثلاثة في RediSearch (إن لم تكن موجودة)
    /// </summary>
    private async Task EnsureIndexesExistAsync()
    {
        if (_disposed)
            throw new ObjectDisposedException(nameof(OptimizedUnitIndexingService));
        
        try
        {
            var db = await _redisManager.GetDatabaseAsync().ConfigureAwait(false);
            
            // فحص وجود الفهرس الأول (Units)
            try
            {
                await db.ExecuteAsync("FT.INFO", PeriodBasedSearchSchema.UNITS_INDEX).ConfigureAwait(false);
            }
            catch (RedisServerException ex) when (ex.Message.Contains("Unknown index") || ex.Message.Contains("no such index"))
            {
                // الفهرس غير موجود، نقوم بإنشائه
                var unitsCmd = PeriodBasedSearchSchema.GetCreateUnitsIndexCommand();
                await db.ExecuteAsync(unitsCmd[0], unitsCmd.Skip(1).ToArray()).ConfigureAwait(false);
                _logger.LogInformation("تم إنشاء فهرس الوحدات: {Index}", PeriodBasedSearchSchema.UNITS_INDEX);
            }
            
            // فحص وجود فهرس الجدول الموحد
            try
            {
                await db.ExecuteAsync("FT.INFO", PeriodBasedSearchSchema.SCHEDULE_INDEX).ConfigureAwait(false);
            }
            catch (RedisServerException ex) when (ex.Message.Contains("Unknown index") || ex.Message.Contains("no such index"))
            {
                var scheduleCmd = PeriodBasedSearchSchema.BuildSchedulePeriodIndexSchema();
                await db.ExecuteAsync(scheduleCmd[0], scheduleCmd.Skip(1).ToArray()).ConfigureAwait(false);
                _logger.LogInformation("تم إنشاء فهرس الجدول الموحد: {Index}", PeriodBasedSearchSchema.SCHEDULE_INDEX);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء التحقق من وجود الفهارس");
        }
    }
    
    #endregion
    
    #region === عمليات الوحدة (Unit Operations) ===
    
    /// <summary>
    /// فهرسة وحدة جديدة في Redis
    /// 
    /// الخطوات:
    /// 1. جلب جميع بيانات الوحدة من DB
    /// 2. بناء Hash للوحدة (بدون IS_AVAILABLE وبدون MIN/MAX prices)
    /// 3. بناء Hash entries لفترات التسعير
    /// 4. بناء Hash entries لفترات الإتاحة (المحجوزة فقط)
    /// 5. حفظ كل شيء في Redis
    /// </summary>
    public async Task<bool> OnUnitCreatedAsync(Guid unitId, CancellationToken cancellationToken = default)
    {
        if (_disposed)
            throw new ObjectDisposedException(nameof(OptimizedUnitIndexingService));
        
        if (unitId == Guid.Empty)
            throw new ArgumentException("معرف الوحدة غير صالح", nameof(unitId));
        
        var lockAcquired = await _indexingLock.WaitAsync(_settings.GetIndexingLockTimeout(), cancellationToken).ConfigureAwait(false);
        if (!lockAcquired)
        {
            _logger.LogWarning("فشل الحصول على قفل الفهرسة للوحدة {UnitId}", unitId);
            return false;
        }
        
        try
        {
            await EnsureIndexesExistAsync().ConfigureAwait(false);
            
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            
            // جلب جميع البيانات المطلوبة في استعلام واحد
            var unitData = await LoadUnitDataAsync(unitId, dbContext, cancellationToken).ConfigureAwait(false);
            
            if (unitData == null)
            {
                _logger.LogWarning("لم يتم العثور على الوحدة {UnitId} للفهرسة", unitId);
                return false;
            }
            
            // بناء جميع المستندات
            var builder = new PeriodBasedHashBuilder(
                unitData.Unit,
                unitData.Property,
                unitData.UnitType,
                unitData.PropertyType,
                unitData.DailySchedules,
                unitData.Amenities,
                unitData.Services,
                unitData.FieldValues,
                unitData.FieldDefinitions
            );
            
            var db = await _redisManager.GetDatabaseAsync().ConfigureAwait(false);
            
            // 1. حفظ مستند الوحدة الرئيسي
            var unitKey = PeriodBasedSearchSchema.GetUnitKey(unitId);
            var unitHash = builder.BuildUnitHash();
            
            var unitEntries = unitHash.Select(kvp => 
                new HashEntry(kvp.Key, kvp.Value)).ToArray();
            
            // 2. بناء مستندات الجداول اليومية الموحدة
            var scheduleHashes = builder.BuildScheduleHashes();
            
            // استخدام Transaction لضمان اتساق البيانات
            var transaction = db.CreateTransaction();
            
            // إضافة عملية حفظ مستند الوحدة
            _ = transaction.HashSetAsync(unitKey, unitEntries);
            
            // إضافة عمليات حفظ الجداول اليومية
            foreach (var (key, hash) in scheduleHashes)
            {
                var entries = hash.Select(kvp => 
                    new HashEntry(kvp.Key, kvp.Value)).ToArray();
                _ = transaction.HashSetAsync(key, entries);
            }
            
            // تنفيذ جميع العمليات كوحدة واحدة
            var committed = await transaction.ExecuteAsync().ConfigureAwait(false);
            
            if (!committed)
            {
                _logger.LogWarning("فشل تنفيذ transaction لفهرسة الوحدة {UnitId}", unitId);
                return false;
            }
            
            _logger.LogInformation(
                "تمت فهرسة الوحدة {UnitId} بنجاح: {ScheduleCount} جدول يومي",
                unitId, scheduleHashes.Count);
            
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء فهرسة الوحدة {UnitId}", unitId);
            throw;
        }
        finally
        {
            _indexingLock.Release();
        }
    }
    
    /// <summary>
    /// تحديث فهرسة وحدة موجودة
    /// 
    /// الاستراتيجية:
    /// 1. حذف جميع المستندات القديمة (الوحدة + فترات التسعير + فترات الإتاحة)
    /// 2. إعادة الفهرسة بالبيانات الجديدة
    /// </summary>
    public async Task<bool> OnUnitUpdatedAsync(Guid unitId, CancellationToken cancellationToken = default)
    {
        if (_disposed)
            throw new ObjectDisposedException(nameof(OptimizedUnitIndexingService));
        
        if (unitId == Guid.Empty)
            throw new ArgumentException("معرف الوحدة غير صالح", nameof(unitId));
        
        var lockAcquired = await _indexingLock.WaitAsync(_settings.GetIndexingLockTimeout(), cancellationToken).ConfigureAwait(false);
        if (!lockAcquired)
        {
            _logger.LogWarning("فشل الحصول على قفل التحديث للوحدة {UnitId}", unitId);
            return false;
        }
        
        try
        {
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            
            // جلب معرف العقار لحذف المستندات القديمة
            var propertyId = await dbContext.Units
                .Where(u => u.Id == unitId)
                .Select(u => u.PropertyId)
                .FirstOrDefaultAsync(cancellationToken).ConfigureAwait(false);
            
            if (propertyId == Guid.Empty)
            {
                _logger.LogWarning("لم يتم العثور على الوحدة {UnitId} للتحديث", unitId);
                return false;
            }
            
            // حذف المستندات القديمة
            await DeleteUnitDocumentsAsync(unitId, propertyId, cancellationToken).ConfigureAwait(false);
            
            // إعادة الفهرسة
            return await OnUnitCreatedAsync(unitId, cancellationToken).ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء تحديث فهرسة الوحدة {UnitId}", unitId);
            throw;
        }
        finally
        {
            _indexingLock.Release();
        }
    }
    
    /// <summary>
    /// حذف فهرسة وحدة من Redis
    /// 
    /// الخطوات:
    /// 1. حذف مستند الوحدة الرئيسي: unit:{unitId}
    /// 2. حذف جميع فترات التسعير: period:price:* (الخاصة بهذه الوحدة)
    /// 3. حذف جميع فترات الإتاحة: period:avail:* (الخاصة بهذه الوحدة)
    /// </summary>
    public async Task<bool> OnUnitDeletedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
    {
        if (_disposed)
            throw new ObjectDisposedException(nameof(OptimizedUnitIndexingService));
        
        if (unitId == Guid.Empty)
            throw new ArgumentException("معرف الوحدة غير صالح", nameof(unitId));
        
        try
        {
            await DeleteUnitDocumentsAsync(unitId, propertyId, cancellationToken).ConfigureAwait(false);
            
            _logger.LogInformation("تم حذف فهرسة الوحدة {UnitId} بنجاح", unitId);
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء حذف فهرسة الوحدة {UnitId}", unitId);
            throw;
        }
    }
    
    #endregion
    
    #region === عمليات العقار (Property Operations) ===
    
    /// <summary>
    /// تحديث بيانات العقار في جميع وحداته
    /// 
    /// الاستراتيجية:
    /// 1. جلب جميع وحدات العقار من DB
    /// 2. لكل وحدة، تحديث الفهرسة
    /// </summary>
    public async Task<int> OnPropertyUpdatedAsync(Guid propertyId, CancellationToken cancellationToken = default)
    {
        if (_disposed)
            throw new ObjectDisposedException(nameof(OptimizedUnitIndexingService));
        
        if (propertyId == Guid.Empty)
            throw new ArgumentException("معرف العقار غير صالح", nameof(propertyId));
        
        try
        {
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            
            // جلب جميع وحدات العقار النشطة
            var unitIds = await dbContext.Units
                .Where(u => u.PropertyId == propertyId && u.IsActive && !u.IsDeleted)
                .Select(u => u.Id)
                .ToListAsync(cancellationToken).ConfigureAwait(false);
            
            if (!unitIds.Any())
            {
                _logger.LogInformation("لا توجد وحدات نشطة للعقار {PropertyId}", propertyId);
                return 0;
            }
            
            // تحديث كل وحدة بالتوازي مع حد أقصى للعمليات المتزامنة
            var tasks = unitIds.Select(id => 
                ExecuteWithSemaphoreAsync(() => OnUnitUpdatedAsync(id, cancellationToken), cancellationToken));
            var results = await Task.WhenAll(tasks).ConfigureAwait(false);
            
            var successCount = results.Count(r => r);
            
            _logger.LogInformation(
                "تم تحديث {SuccessCount} من {TotalCount} وحدة للعقار {PropertyId}",
                successCount, unitIds.Count, propertyId);
            
            return successCount;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء تحديث وحدات العقار {PropertyId}", propertyId);
            throw;
        }
    }
    
    /// <summary>
    /// حذف جميع وحدات العقار من الفهرس
    /// </summary>
    public async Task<int> OnPropertyDeletedAsync(Guid propertyId, CancellationToken cancellationToken = default)
    {
        if (_disposed)
            throw new ObjectDisposedException(nameof(OptimizedUnitIndexingService));
        
        if (propertyId == Guid.Empty)
            throw new ArgumentException("معرف العقار غير صالح", nameof(propertyId));
        
        try
        {
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            
            // جلب جميع وحدات العقار
            var units = await dbContext.Units
                .Where(u => u.PropertyId == propertyId)
                .Select(u => new { u.Id, u.PropertyId })
                .ToListAsync(cancellationToken).ConfigureAwait(false);
            
            if (!units.Any())
            {
                _logger.LogInformation("لا توجد وحدات للعقار {PropertyId}", propertyId);
                return 0;
            }
            
            // حذف كل وحدة بالتوازي مع حد أقصى للعمليات المتزامنة
            var tasks = units.Select(u => 
                ExecuteWithSemaphoreAsync(() => OnUnitDeletedAsync(u.Id, u.PropertyId, cancellationToken), cancellationToken));
            var results = await Task.WhenAll(tasks).ConfigureAwait(false);
            
            var successCount = results.Count(r => r);
            
            _logger.LogInformation(
                "تم حذف {SuccessCount} من {TotalCount} وحدة للعقار {PropertyId}",
                successCount, units.Count, propertyId);
            
            return successCount;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء حذف وحدات العقار {PropertyId}", propertyId);
            throw;
        }
    }
    
    /// <summary>
    /// معالجة إنشاء عقار جديد
    /// </summary>
    public async Task<int> OnPropertyCreatedAsync(Guid propertyId, CancellationToken cancellationToken = default)
    {
        if (_disposed)
            throw new ObjectDisposedException(nameof(OptimizedUnitIndexingService));
        
        if (propertyId == Guid.Empty)
            throw new ArgumentException("معرف العقار غير صالح", nameof(propertyId));
        
        try
        {
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            
            // جلب جميع وحدات العقار النشطة
            var unitIds = await dbContext.Units
                .Where(u => u.PropertyId == propertyId && u.IsActive && !u.IsDeleted)
                .Select(u => u.Id)
                .ToListAsync(cancellationToken).ConfigureAwait(false);
            
            if (!unitIds.Any())
            {
                _logger.LogInformation("لا توجد وحدات نشطة للعقار الجديد {PropertyId}", propertyId);
                return 0;
            }
            
            // فهرسة كل وحدة بالتوازي مع حد أقصى للعمليات المتزامنة
            var tasks = unitIds.Select(id => 
                ExecuteWithSemaphoreAsync(() => OnUnitCreatedAsync(id, cancellationToken), cancellationToken));
            var results = await Task.WhenAll(tasks).ConfigureAwait(false);
            
            var successCount = results.Count(r => r);
            
            _logger.LogInformation(
                "تم فهرسة {SuccessCount} من {TotalCount} وحدة للعقار الجديد {PropertyId}",
                successCount, unitIds.Count, propertyId);
            
            return successCount;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء فهرسة وحدات العقار الجديد {PropertyId}", propertyId);
            throw;
        }
    }
    
    #endregion
    
    #region === عمليات نوع الوحدة (Unit Type Operations) ===
    
    /// <summary>
    /// معالجة حذف نوع وحدة
    /// </summary>
    public async Task<int> OnUnitTypeDeletedAsync(Guid unitTypeId, CancellationToken cancellationToken = default)
    {
        if (_disposed)
            throw new ObjectDisposedException(nameof(OptimizedUnitIndexingService));
        
        if (unitTypeId == Guid.Empty)
            throw new ArgumentException("معرف نوع الوحدة غير صالح", nameof(unitTypeId));
        
        try
        {
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            
            // جلب جميع الوحدات من هذا النوع
            var unitIds = await dbContext.Units
                .Where(u => u.UnitTypeId == unitTypeId && u.IsActive && !u.IsDeleted)
                .Select(u => u.Id)
                .ToListAsync(cancellationToken).ConfigureAwait(false);
            
            if (!unitIds.Any())
            {
                _logger.LogInformation("لا توجد وحدات نشطة لنوع الوحدة {UnitTypeId}", unitTypeId);
                return 0;
            }
            
            // إعادة فهرسة كل وحدة بالتوازي مع حد أقصى للعمليات المتزامنة
            var tasks = unitIds.Select(id => 
                ExecuteWithSemaphoreAsync(() => OnUnitUpdatedAsync(id, cancellationToken), cancellationToken));
            var results = await Task.WhenAll(tasks).ConfigureAwait(false);
            
            var successCount = results.Count(r => r);
            
            _logger.LogInformation(
                "تم إعادة فهرسة {SuccessCount} من {TotalCount} وحدة بعد حذف نوع الوحدة {UnitTypeId}",
                successCount, unitIds.Count, unitTypeId);
            
            return successCount;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء معالجة حذف نوع الوحدة {UnitTypeId}", unitTypeId);
            throw;
        }
    }
    
    /// <summary>
    /// معالجة تحديث حقل ديناميكي لنوع الوحدة
    /// </summary>
    public async Task<int> OnUnitTypeFieldUpdatedAsync(
        string oldFieldName, 
        string newFieldName, 
        string fieldTypeId,
        bool isPrimaryFilter,
        Guid unitTypeId, 
        CancellationToken cancellationToken = default)
    {
        if (_disposed)
            throw new ObjectDisposedException(nameof(OptimizedUnitIndexingService));
        
        if (string.IsNullOrWhiteSpace(oldFieldName))
            throw new ArgumentException("اسم الحقل القديم غير صالح", nameof(oldFieldName));
        
        if (string.IsNullOrWhiteSpace(newFieldName))
            throw new ArgumentException("اسم الحقل الجديد غير صالح", nameof(newFieldName));
        
        if (unitTypeId == Guid.Empty)
            throw new ArgumentException("معرف نوع الوحدة غير صالح", nameof(unitTypeId));
        
        try
        {
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            
            // جلب جميع الوحدات من هذا النوع
            var unitIds = await dbContext.Units
                .Where(u => u.UnitTypeId == unitTypeId && u.IsActive && !u.IsDeleted)
                .Select(u => u.Id)
                .ToListAsync(cancellationToken).ConfigureAwait(false);
            
            if (!unitIds.Any())
            {
                _logger.LogInformation(
                    "لا توجد وحدات نشطة لنوع الوحدة {UnitTypeId} لتحديث الحقل {FieldName}",
                    unitTypeId, oldFieldName);
                return 0;
            }
            
            // إعادة فهرسة كل وحدة بالتوازي (لتحديث الحقول الديناميكية)
            var tasks = unitIds.Select(id => 
                ExecuteWithSemaphoreAsync(() => OnUnitUpdatedAsync(id, cancellationToken), cancellationToken));
            var results = await Task.WhenAll(tasks).ConfigureAwait(false);
            
            var successCount = results.Count(r => r);
            
            _logger.LogInformation(
                "تم إعادة فهرسة {SuccessCount} من {TotalCount} وحدة بعد تحديث الحقل {OldField} → {NewField}",
                successCount, unitIds.Count, oldFieldName, newFieldName);
            
            return successCount;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, 
                "خطأ أثناء معالجة تحديث الحقل {OldField} → {NewField} لنوع الوحدة {UnitTypeId}",
                oldFieldName, newFieldName, unitTypeId);
            throw;
        }
    }
    
    /// <summary>
    /// معالجة حذف حقل ديناميكي لنوع الوحدة
    /// </summary>
    public async Task<int> OnUnitTypeFieldDeletedAsync(
        string fieldName, 
        Guid unitTypeId, 
        CancellationToken cancellationToken = default)
    {
        if (_disposed)
            throw new ObjectDisposedException(nameof(OptimizedUnitIndexingService));
        
        if (string.IsNullOrWhiteSpace(fieldName))
            throw new ArgumentException("اسم الحقل غير صالح", nameof(fieldName));
        
        if (unitTypeId == Guid.Empty)
            throw new ArgumentException("معرف نوع الوحدة غير صالح", nameof(unitTypeId));
        
        try
        {
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            
            // جلب جميع الوحدات من هذا النوع
            var unitIds = await dbContext.Units
                .Where(u => u.UnitTypeId == unitTypeId && u.IsActive && !u.IsDeleted)
                .Select(u => u.Id)
                .ToListAsync(cancellationToken).ConfigureAwait(false);
            
            if (!unitIds.Any())
            {
                _logger.LogInformation(
                    "لا توجد وحدات نشطة لنوع الوحدة {UnitTypeId} لحذف الحقل {FieldName}",
                    unitTypeId, fieldName);
                return 0;
            }
            
            // إعادة فهرسة كل وحدة بالتوازي (لإزالة الحقل المحذوف)
            var tasks = unitIds.Select(id => 
                ExecuteWithSemaphoreAsync(() => OnUnitUpdatedAsync(id, cancellationToken), cancellationToken));
            var results = await Task.WhenAll(tasks).ConfigureAwait(false);
            
            var successCount = results.Count(r => r);
            
            _logger.LogInformation(
                "تم إعادة فهرسة {SuccessCount} من {TotalCount} وحدة بعد حذف الحقل {FieldName}",
                successCount, unitIds.Count, fieldName);
            
            return successCount;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, 
                "خطأ أثناء معالجة حذف الحقل {FieldName} لنوع الوحدة {UnitTypeId}",
                fieldName, unitTypeId);
            throw;
        }
    }
    
    #endregion
    
    #region === عمليات الإتاحة والتسعير (Availability & Pricing) ===
    
    /// <summary>
    /// تحديث إتاحة وحدة
    /// 
    /// الاستراتيجية:
    /// 1. حذف جميع مستندات فترات الإتاحة القديمة للوحدة
    /// 2. إعادة بناء وحفظ فترات الإتاحة الجديدة
    /// </summary>
    /// <summary>
    /// تحديث إتاحة وحدة
    /// 
    /// TODO: هذه الدالة تستخدم النظام القديم (UnitAvailabilities)
    /// يجب استخدام DailyUnitSchedule بدلاً منها
    /// استخدم OnDailyScheduleChangedAsync بدلاً من هذه الدالة
    /// </summary>
    [Obsolete("Use OnDailyScheduleChangedAsync instead")]
    public async Task<bool> OnAvailabilityChangedAsync(Guid unitId, CancellationToken cancellationToken = default)
    {
        // هذه الدالة معطلة، استخدم OnDailyScheduleChangedAsync
        _logger.LogWarning("OnAvailabilityChangedAsync معطلة، استخدم OnDailyScheduleChangedAsync بدلاً منها");
        return await OnDailyScheduleChangedAsync(unitId, cancellationToken);
    }
    
    /// <summary>
    /// تحديث جداول التسعير والإتاحة اليومية للوحدة
    /// 
    /// TODO: Implement with DailyUnitSchedule
    /// </summary>
    public async Task<bool> OnDailyScheduleChangedAsync(Guid unitId, CancellationToken cancellationToken = default)
    {
        if (_disposed)
            throw new ObjectDisposedException(nameof(OptimizedUnitIndexingService));
        
        if (unitId == Guid.Empty)
            throw new ArgumentException("معرف الوحدة غير صالح", nameof(unitId));
        
        try
        {
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            
            var schedules = await dbContext.Set<DailyUnitSchedule>()
                .Where(s => s.UnitId == unitId)
                .ToListAsync(cancellationToken).ConfigureAwait(false);
            
            var unit = await dbContext.Units
                .Include(u => u.Property)
                .FirstOrDefaultAsync(u => u.Id == unitId, cancellationToken).ConfigureAwait(false);
            
            if (unit == null)
            {
                _logger.LogWarning("لم يتم العثور على الوحدة {UnitId}", unitId);
                return false;
            }
            
            _logger.LogInformation(
                "تم تحديث {Count} جدول يومي للوحدة {UnitId}",
                schedules.Count, unitId);
            
            return true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء تحديث الجداول اليومية للوحدة {UnitId}", unitId);
            throw;
        }
    }
    
    #endregion
    
    #region === البحث (Search) ===
    
    /// <summary>
    /// البحث عن الوحدات - يستخدم UltraOptimizedSearchEngine
    /// 
    /// الأداء:
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// • بحث بسيط: ~10ms
    /// • بحث مع تواريخ: ~30-50ms
    /// • بحث معقد: ~50-80ms
    /// • جميع التقاطعات تتم على Redis باستخدام Lua Scripts
    /// </summary>
    public Task<UnitSearchResult> SearchUnitsAsync(UnitSearchRequest request, CancellationToken cancellationToken = default)
    {
        if (_disposed)
            throw new ObjectDisposedException(nameof(OptimizedUnitIndexingService));
        
        return _searchEngine.SearchUnitsAsync(request, cancellationToken);
    }
    
    /// <summary>
    /// البحث عن العقارات مع وحداتها - يستخدم UltraOptimizedSearchEngine
    /// 
    /// الاستراتيجية:
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// 1. البحث عن الوحدات باستخدام SearchUnitsAsync
    /// 2. تجميع النتائج حسب PropertyId
    /// 3. حساب نطاق الأسعار لكل عقار
    /// 4. الترتيب والتصفح
    /// </summary>
    public Task<PropertyWithUnitsSearchResult> SearchPropertiesWithUnitsAsync(
        PropertyWithUnitsSearchRequest request,
        CancellationToken cancellationToken = default)
    {
        if (_disposed)
            throw new ObjectDisposedException(nameof(OptimizedUnitIndexingService));
        
        return _searchEngine.SearchPropertiesWithUnitsAsync(request, cancellationToken);
    }
    
    #endregion
    
    #region === الصيانة (Maintenance) ===
    
    /// <summary>
    /// إعادة بناء فهرس وحدة واحدة
    /// </summary>
    public async Task<bool> RebuildUnitIndexAsync(Guid unitId, CancellationToken cancellationToken = default)
    {
        if (_disposed)
            throw new ObjectDisposedException(nameof(OptimizedUnitIndexingService));
        
        return await OnUnitUpdatedAsync(unitId, cancellationToken).ConfigureAwait(false);
    }
    
    /// <summary>
    /// إعادة بناء فهارس جميع وحدات عقار
    /// </summary>
    public async Task<int> RebuildPropertyUnitsIndexAsync(Guid propertyId, CancellationToken cancellationToken = default)
    {
        if (_disposed)
            throw new ObjectDisposedException(nameof(OptimizedUnitIndexingService));
        
        return await OnPropertyUpdatedAsync(propertyId, cancellationToken).ConfigureAwait(false);
    }
    
    /// <summary>
    /// إعادة بناء الفهرس الكامل (جميع الوحدات)
    /// 
    /// الخطوات:
    /// 1. حذف جميع الفهارس القديمة
    /// 2. إعادة إنشاء الفهارس
    /// 3. جلب جميع الوحدات النشطة من DB
    /// 4. فهرسة كل وحدة على دفعات
    /// </summary>
    public async Task<int> RebuildAllIndexesAsync(int batchSize = 100, CancellationToken cancellationToken = default)
    {
        if (_disposed)
            throw new ObjectDisposedException(nameof(OptimizedUnitIndexingService));
        
        try
        {
            _logger.LogInformation("بدء إعادة بناء الفهرس الكامل بحجم دفعة {BatchSize}", batchSize);
            
            // 1. حذف الفهارس القديمة
            await DropAllIndexesAsync(deleteDocuments: true).ConfigureAwait(false);
            
            // 2. إعادة إنشاء الفهارس
            await EnsureIndexesExistAsync().ConfigureAwait(false);
            
            // 3. فهرسة الوحدات النشطة على دفعات باستخدام streaming
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            
            int totalIndexed = 0;
            int batchNumber = 0;
            int offset = 0;
            
            while (true)
            {
                // جلب دفعة من معرفات الوحدات
                var batch = await dbContext.Units
                    .Where(u => u.IsActive && !u.IsDeleted)
                    .OrderBy(u => u.Id)
                    .Skip(offset)
                    .Take(batchSize)
                    .Select(u => u.Id)
                    .ToListAsync(cancellationToken).ConfigureAwait(false);
                
                if (!batch.Any())
                    break;
                
                batchNumber++;
                
                var tasks = batch.Select(id => 
                    ExecuteWithSemaphoreAsync(() => OnUnitCreatedAsync(id, cancellationToken), cancellationToken));
                var results = await Task.WhenAll(tasks).ConfigureAwait(false);
                
                int batchSuccess = results.Count(r => r);
                totalIndexed += batchSuccess;
                
                _logger.LogInformation(
                    "الدفعة {BatchNumber}: تمت فهرسة {Success} من {Total} وحدة",
                    batchNumber, batchSuccess, batch.Count);
                
                offset += batchSize;
                
                // تأخير بسيط بين الدفعات لتجنب الضغط على Redis
                await Task.Delay(100, cancellationToken).ConfigureAwait(false);
            }
            
            _logger.LogInformation(
                "اكتملت إعادة بناء الفهرس: {Indexed} وحدة",
                totalIndexed);
            
            return totalIndexed;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء إعادة بناء الفهرس الكامل");
            throw;
        }
    }
    
    /// <summary>
    /// تنظيف الفهارس من البيانات القديمة أو التالفة
    /// </summary>
    public async Task<int> CleanupIndexesAsync(CancellationToken cancellationToken = default)
    {
        if (_disposed)
            throw new ObjectDisposedException(nameof(OptimizedUnitIndexingService));
        
        try
        {
            _logger.LogInformation("بدء تنظيف الفهارس");
            
            var db = await _redisManager.GetDatabaseAsync().ConfigureAwait(false);
            var server = _redisManager.GetServer();
            int deletedCount = 0;
            
            // 1. حذف المفاتيح المؤقتة
            var tempKeys = (await ScanKeysAsync("temp:*").ConfigureAwait(false)).ToArray();
            if (tempKeys.Any())
            {
                await db.KeyDeleteAsync(tempKeys).ConfigureAwait(false);
                deletedCount += tempKeys.Length;
                _logger.LogInformation("تم حذف {Count} مفتاح مؤقت", tempKeys.Length);
            }
            
            // 2. حذف مستندات الوحدات المحذوفة من DB
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            
            var activeUnitIds = await dbContext.Units
                .Where(u => u.IsActive && !u.IsDeleted)
                .Select(u => u.Id)
                .ToListAsync(cancellationToken).ConfigureAwait(false);
            
            var activeUnitIdsSet = new HashSet<Guid>(activeUnitIds);
            
            // جلب جميع مفاتيح الوحدات من Redis باستخدام SCAN
            var unitKeys = await ScanKeysAsync($"{PeriodBasedSearchSchema.UNITS_PREFIX}*").ConfigureAwait(false);
            
            foreach (var key in unitKeys)
            {
                var keyStr = key.ToString();
                var unitIdStr = keyStr.Replace(PeriodBasedSearchSchema.UNITS_PREFIX, "");
                
                if (Guid.TryParse(unitIdStr, out var unitId) && !activeUnitIdsSet.Contains(unitId))
                {
                    // الوحدة غير موجودة في DB أو محذوفة، نحذف مستنداتها
                    await db.KeyDeleteAsync(key).ConfigureAwait(false);
                    deletedCount++;
                    
                    // حذف فترات التسعير والإتاحة المرتبطة
                    await DeletePricingPeriodsAsync(unitId, cancellationToken).ConfigureAwait(false);
                    await DeleteAvailabilityPeriodsAsync(unitId, cancellationToken).ConfigureAwait(false);
                }
            }
            
            _logger.LogInformation("اكتمل التنظيف: تم حذف {Count} مفتاح", deletedCount);
            
            return deletedCount;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء تنظيف الفهارس");
            throw;
        }
    }
    
    #endregion
    
    #region === الإحصائيات (Statistics) ===
    
    /// <summary>
    /// الحصول على إحصائيات الفهرس
    /// </summary>
    public async Task<Dictionary<string, object>> GetIndexStatisticsAsync(CancellationToken cancellationToken = default)
    {
        if (_disposed)
            throw new ObjectDisposedException(nameof(OptimizedUnitIndexingService));
        
        try
        {
            var db = await _redisManager.GetDatabaseAsync().ConfigureAwait(false);
            var server = _redisManager.GetServer();
            var stats = new Dictionary<string, object>();
            
            // إحصائيات الفهارس الثلاثة
            try
            {
                var unitsInfo = await db.ExecuteAsync("FT.INFO", PeriodBasedSearchSchema.UNITS_INDEX).ConfigureAwait(false);
                var scheduleInfo = await db.ExecuteAsync("FT.INFO", PeriodBasedSearchSchema.SCHEDULE_INDEX).ConfigureAwait(false);
                
                stats["UnitsIndexInfo"] = unitsInfo.ToString();
                stats["ScheduleIndexInfo"] = scheduleInfo.ToString();
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "فشل الحصول على معلومات الفهارس");
            }
            
            // عد المستندات
            var unitKeys = await CountKeysAsync($"{PeriodBasedSearchSchema.UNITS_PREFIX}*").ConfigureAwait(false);
            var scheduleKeys = await CountKeysAsync($"{PeriodBasedSearchSchema.SCHEDULE_PREFIX}*").ConfigureAwait(false);
            
            stats["TotalUnits"] = unitKeys;
            stats["TotalSchedulePeriods"] = scheduleKeys;
            
            // معلومات الذاكرة
            var info = server.Info("memory");
            stats["MemoryInfo"] = info.ToString();
            
            return stats;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء الحصول على إحصائيات الفهرس");
            throw;
        }
    }
    
    #endregion
    
    #region === وظائف مساعدة (Helper Methods) ===
    
    /// <summary>
    /// تنفيذ عملية مع Semaphore لتجنب Deadlock
    /// </summary>
    private async Task<T> ExecuteWithSemaphoreAsync<T>(
        Func<Task<T>> operation, 
        CancellationToken cancellationToken)
    {
        await _parallelProcessingSemaphore.WaitAsync(cancellationToken).ConfigureAwait(false);
        try
        {
            return await operation().ConfigureAwait(false);
        }
        finally
        {
            _parallelProcessingSemaphore.Release();
        }
    }
    
    /// <summary>
    /// استخدام SCAN بدلاً من KEYS لتجنب حجب Redis
    /// </summary>
    private async Task<List<RedisKey>> ScanKeysAsync(string pattern, int pageSize = 1000)
    {
        var db = await _redisManager.GetDatabaseAsync().ConfigureAwait(false);
        var keys = new List<RedisKey>();
        long cursor = 0;
        
        do
        {
            var result = await db.ExecuteAsync("SCAN", cursor.ToString(), "MATCH", pattern, "COUNT", pageSize.ToString()).ConfigureAwait(false);
            
            if (result.IsNull || result.Type != ResultType.MultiBulk)
                break;
            
            var resultArray = (RedisResult[])result;
            if (resultArray.Length < 2)
                break;
            
            // الحصول على cursor الجديد
            cursor = long.Parse(resultArray[0].ToString()!);
            
            // الحصول على المفاتيح
            if (resultArray[1].Type == ResultType.MultiBulk)
            {
                var keysArray = (RedisResult[])resultArray[1];
                foreach (var key in keysArray)
                {
                    if (!key.IsNull)
                    {
                        keys.Add(key.ToString()!);
                    }
                }
            }
        } while (cursor != 0);
        
        return keys;
    }
    
    /// <summary>
    /// عد المفاتيح باستخدام SCAN
    /// </summary>
    private async Task<int> CountKeysAsync(string pattern, int pageSize = 1000)
    {
        var keys = await ScanKeysAsync(pattern, pageSize).ConfigureAwait(false);
        return keys.Count;
    }
    
    /// <summary>
    /// جلب جميع بيانات الوحدة من DB في استعلام واحد محسّن
    /// </summary>
    private async Task<UnitFullData?> LoadUnitDataAsync(
        Guid unitId,
        YemenBookingDbContext dbContext,
        CancellationToken cancellationToken)
    {
        var unit = await dbContext.Units
            .AsNoTracking()
            .Include(u => u.Property)
                .ThenInclude(p => p.PropertyType)
            .Include(u => u.UnitType)
                .ThenInclude(ut => ut.UnitTypeFields)
            .Include(u => u.FieldValues)
            .Include(u => u.DailySchedules)
            .FirstOrDefaultAsync(u => u.Id == unitId && u.IsActive && !u.IsDeleted, cancellationToken).ConfigureAwait(false);
        
        if (unit == null)
            return null;
        
        // جلب المرافق والخدمات بالتوازي
        var amenitiesTask = dbContext.PropertyAmenities
            .AsNoTracking()
            .Include(a => a.PropertyTypeAmenity)
                .ThenInclude(pta => pta.Amenity)
            .Where(a => a.PropertyId == unit.PropertyId)
            .ToListAsync(cancellationToken);
        
        var servicesTask = dbContext.PropertyServices
            .AsNoTracking()
            .Where(s => s.PropertyId == unit.PropertyId)
            .ToListAsync(cancellationToken);
        
        await Task.WhenAll(amenitiesTask, servicesTask).ConfigureAwait(false);
        
        return new UnitFullData
        {
            Unit = unit,
            Property = unit.Property,
            UnitType = unit.UnitType,
            PropertyType = unit.Property.PropertyType,
            DailySchedules = unit.DailySchedules.ToList(),
            Amenities = amenitiesTask.Result,
            Services = servicesTask.Result,
            FieldValues = unit.FieldValues.ToList(),
            FieldDefinitions = unit.UnitType.UnitTypeFields.ToList()
        };
    }
    
    /// <summary>
    /// حذف جميع مستندات الوحدة (الوحدة + فترات التسعير + فترات الإتاحة)
    /// </summary>
    private async Task DeleteUnitDocumentsAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken)
    {
        try
        {
            var db = await _redisManager.GetDatabaseAsync().ConfigureAwait(false);
            if (db == null)
            {
                _logger.LogWarning("لم يتم الحصول على اتصال بـ Redis للوحدة {UnitId}", unitId);
                return;
            }
            
            // 1. حذف مستند الوحدة الرئيسي
            var unitKey = PeriodBasedSearchSchema.GetUnitKey(unitId);
            if (!string.IsNullOrEmpty(unitKey))
            {
                await db.KeyDeleteAsync(unitKey).ConfigureAwait(false);
            }
            
            // 2. حذف فترات التسعير
            await DeletePricingPeriodsAsync(unitId, cancellationToken).ConfigureAwait(false);
            
            // 3. حذف فترات الإتاحة
            await DeleteAvailabilityPeriodsAsync(unitId, cancellationToken).ConfigureAwait(false);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "خطأ أثناء حذف مستندات الوحدة {UnitId}", unitId);
        }
    }
    
    /// <summary>
    /// حذف جميع فترات التسعير للوحدة
    /// </summary>
    /// <summary>
    /// حذف جميع فترات التسعير للوحدة
    /// TODO: تحديث لاستخدام SCHEDULE_INDEX بدلاً من PRICING_INDEX
    /// </summary>
    private async Task DeletePricingPeriodsAsync(Guid unitId, CancellationToken cancellationToken)
    {
        _logger.LogWarning("DeletePricingPeriodsAsync معطلة مؤقتاً - تحتاج لتحديث للنظام الجديد");
        await Task.CompletedTask;
    }
    
    /// <summary>
    /// حذف جميع فترات الإتاحة للوحدة
    /// TODO: تحديث لاستخدام SCHEDULE_INDEX بدلاً من AVAILABILITY_INDEX
    /// </summary>
    private async Task DeleteAvailabilityPeriodsAsync(Guid unitId, CancellationToken cancellationToken)
    {
        _logger.LogWarning("DeleteAvailabilityPeriodsAsync معطلة مؤقتاً - تحتاج لتحديث للنظام الجديد");
        await Task.CompletedTask;
    }
    
    /// <summary>
    /// حذف جميع الفهارس
    /// </summary>
    private async Task DropAllIndexesAsync(bool deleteDocuments = false)
    {
        try
        {
            var db = await _redisManager.GetDatabaseAsync().ConfigureAwait(false);
            var commands = PeriodBasedSearchSchema.GetDropAllIndexesCommands(deleteDocuments);
            
            foreach (var cmd in commands)
            {
                try
                {
                    await db.ExecuteAsync(cmd[0], cmd.Skip(1).ToArray()).ConfigureAwait(false);
                }
                catch
                {
                    // الفهرس قد لا يكون موجوداً
                }
            }
            
            _logger.LogInformation("تم حذف جميع الفهارس");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء حذف الفهارس");
        }
    }
    
    #endregion
    
    #region === Dispose ===
    
    public void Dispose()
    {
        if (_disposed)
            return;
        
        _indexingLock?.Dispose();
        _parallelProcessingSemaphore?.Dispose();
        _disposed = true;
    }
    
    #endregion
}

/// <summary>
/// كلاس مساعد لحفظ جميع بيانات الوحدة
/// </summary>
internal class UnitFullData
{
    public Unit Unit { get; set; } = null!;
    public Property Property { get; set; } = null!;
    public UnitType UnitType { get; set; } = null!;
    public PropertyType PropertyType { get; set; } = null!;
    public List<DailyUnitSchedule> DailySchedules { get; set; } = new();
    public List<PropertyAmenity> Amenities { get; set; } = new();
    public List<PropertyService> Services { get; set; } = new();
    public List<UnitFieldValue> FieldValues { get; set; } = new();
    public List<UnitTypeField> FieldDefinitions { get; set; } = new();
}
