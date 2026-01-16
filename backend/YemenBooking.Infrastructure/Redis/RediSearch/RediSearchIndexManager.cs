using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;
using YemenBooking.Core.Indexing.RediSearch;
using YemenBooking.Infrastructure.Redis.Core.Interfaces;

namespace YemenBooking.Infrastructure.Redis.RediSearch;

/// <summary>
/// مدير RediSearch Index - النظام الجديد
/// 
/// المسؤوليات:
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// • إنشاء الفهارس الثلاثة عند بدء التطبيق:
///   - idx:units:v3 (الوحدات)
///   - idx:periods:price (فترات التسعير)
///   - idx:periods:avail (فترات الإتاحة)
/// • التحقق من وجود الفهارس
/// • إعادة بناء الفهارس
/// • حذف الفهارس
/// • الحصول على إحصائيات الفهارس
/// </summary>
public interface IRediSearchIndexManager
{
    Task EnsureIndexesExistAsync(CancellationToken cancellationToken = default);
    Task<bool> AllIndexesExistAsync(CancellationToken cancellationToken = default);
    Task CreateIndexesAsync(bool recreate = false, CancellationToken cancellationToken = default);
    Task DropIndexesAsync(bool deleteDocuments = false, CancellationToken cancellationToken = default);
    Task<IndexesInfo?> GetIndexesInfoAsync(CancellationToken cancellationToken = default);
}

public sealed class RediSearchIndexManager : IRediSearchIndexManager
{
    private readonly IRedisConnectionManager _redisManager;
    private readonly ILogger<RediSearchIndexManager> _logger;
    private bool _indexesChecked;
    private readonly SemaphoreSlim _lock = new(1, 1);
    
    public RediSearchIndexManager(
        IRedisConnectionManager redisManager,
        ILogger<RediSearchIndexManager> logger)
    {
        _redisManager = redisManager ?? throw new ArgumentNullException(nameof(redisManager));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
    }
    
    /// <summary>
    /// التأكد من وجود الفهارس الثلاثة (يُستدعى عند بدء التطبيق)
    /// </summary>
    public async Task EnsureIndexesExistAsync(CancellationToken cancellationToken = default)
    {
        if (_indexesChecked)
            return;
        
        await _lock.WaitAsync(cancellationToken);
        try
        {
            if (_indexesChecked)
                return;
            
            var allExist = await AllIndexesExistAsync(cancellationToken);
            
            if (!allExist)
            {
                _logger.LogInformation("بعض الفهارس غير موجودة، سيتم إنشاؤها...");
                await CreateIndexesAsync(recreate: false, cancellationToken);
            }
            else
            {
                _logger.LogInformation("جميع الفهارس موجودة ومُجهزة للاستخدام");
            }
            
            _indexesChecked = true;
        }
        finally
        {
            _lock.Release();
        }
    }
    
    /// <summary>
    /// التحقق من وجود جميع الفهارس الثلاثة
    /// </summary>
    public async Task<bool> AllIndexesExistAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var db = await _redisManager.GetDatabaseAsync();
            
            // فحص فهرس الوحدات
            var unitsExists = await IndexExistsAsync(db, PeriodBasedSearchSchema.UNITS_INDEX);
            
            // فحص فهرس الجدول الموحد
            var scheduleExists = await IndexExistsAsync(db, PeriodBasedSearchSchema.SCHEDULE_INDEX);
            
            return unitsExists && scheduleExists;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "خطأ أثناء التحقق من وجود الفهارس");
            return false;
        }
    }
    
    /// <summary>
    /// فحص وجود فهرس واحد
    /// </summary>
    private async Task<bool> IndexExistsAsync(IDatabase db, string indexName)
    {
        try
        {
            var result = await db.ExecuteAsync("FT.INFO", indexName);
            return result != null && !result.IsNull;
        }
        catch (RedisServerException ex) when (ex.Message.Contains("Unknown Index"))
        {
            return false;
        }
    }
    
    /// <summary>
    /// إنشاء جميع الفهارس الثلاثة
    /// </summary>
    public async Task CreateIndexesAsync(bool recreate = false, CancellationToken cancellationToken = default)
    {
        try
        {
            var db = await _redisManager.GetDatabaseAsync();
            
            // حذف الفهارس القديمة إذا كان recreate = true
            if (recreate)
            {
                _logger.LogInformation("حذف الفهارس القديمة...");
                await DropIndexesAsync(deleteDocuments: false, cancellationToken);
            }
            
            // إنشاء فهرس الوحدات
            _logger.LogInformation("إنشاء فهرس الوحدات...");
            await CreateSingleIndexAsync(db, PeriodBasedSearchSchema.GetCreateUnitsIndexCommand(), 
                PeriodBasedSearchSchema.UNITS_INDEX);
            
            // إنشاء فهرس الجدول الموحد
            _logger.LogInformation("إنشاء فهرس الجدول اليومي الموحد...");
            await CreateSingleIndexAsync(db, PeriodBasedSearchSchema.BuildSchedulePeriodIndexSchema(), 
                PeriodBasedSearchSchema.SCHEDULE_INDEX);
            
            _logger.LogInformation("✅ تم إنشاء جميع الفهارس بنجاح");
            _indexesChecked = true;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ فشل إنشاء الفهارس");
            throw;
        }
    }
    
    /// <summary>
    /// إنشاء فهرس واحد
    /// </summary>
    private async Task CreateSingleIndexAsync(IDatabase db, string[] command, string indexName)
    {
        try
        {
            await db.ExecuteAsync(command[0], command.Skip(1).ToArray());
            _logger.LogInformation("✓ تم إنشاء الفهرس: {IndexName}", indexName);
        }
        catch (RedisServerException ex) when (ex.Message.Contains("Index already exists"))
        {
            _logger.LogWarning("الفهرس {IndexName} موجود بالفعل", indexName);
        }
    }
    
    /// <summary>
    /// حذف جميع الفهارس الثلاثة
    /// </summary>
    public async Task DropIndexesAsync(bool deleteDocuments = false, CancellationToken cancellationToken = default)
    {
        try
        {
            var db = await _redisManager.GetDatabaseAsync();
            var commands = PeriodBasedSearchSchema.GetDropAllIndexesCommands(deleteDocuments);
            
            foreach (var cmd in commands)
            {
                try
                {
                    await db.ExecuteAsync(cmd[0], cmd.Skip(1).ToArray());
                    _logger.LogInformation("تم حذف الفهرس");
                }
                catch (RedisServerException ex) when (ex.Message.Contains("Unknown Index"))
                {
                    // الفهرس غير موجود - تجاهل
                }
            }
            
            _logger.LogInformation("تم حذف جميع الفهارس");
            _indexesChecked = false;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء حذف الفهارس");
            throw;
        }
    }
    
    /// <summary>
    /// الحصول على معلومات جميع الفهارس
    /// </summary>
    public async Task<IndexesInfo?> GetIndexesInfoAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var db = await _redisManager.GetDatabaseAsync();
            
            var info = new IndexesInfo
            {
                UnitsIndex = await GetSingleIndexInfoAsync(db, PeriodBasedSearchSchema.UNITS_INDEX),
                ScheduleIndex = await GetSingleIndexInfoAsync(db, PeriodBasedSearchSchema.SCHEDULE_INDEX)
            };
            
            return info;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء جلب معلومات الفهارس");
            return null;
        }
    }
    
    /// <summary>
    /// الحصول على معلومات فهرس واحد
    /// </summary>
    private async Task<IndexInfo?> GetSingleIndexInfoAsync(IDatabase db, string indexName)
    {
        try
        {
            var result = await db.ExecuteAsync("FT.INFO", indexName);
            
            if (result == null || result.IsNull)
                return null;
            
            var resultArray = (RedisResult[])result!;
            var info = new IndexInfo { IndexName = indexName };
            
            for (int i = 0; i < resultArray.Length; i += 2)
            {
                if (i + 1 >= resultArray.Length) break;
                
                var key = resultArray[i].ToString();
                var value = resultArray[i + 1];
                
                switch (key)
                {
                    case "num_docs":
                        info.NumDocs = (long)value;
                        break;
                    case "num_records":
                        info.NumRecords = (long)value;
                        break;
                    case "num_terms":
                        info.NumTerms = (long)value;
                        break;
                    case "indexing":
                        info.IsIndexing = (int)value == 1;
                        break;
                }
            }
            
            return info;
        }
        catch
        {
            return null;
        }
    }
}

/// <summary>
/// معلومات فهرس واحد
/// </summary>
public sealed class IndexInfo
{
    public string IndexName { get; set; } = string.Empty;
    public long NumDocs { get; set; }
    public long NumRecords { get; set; }
    public long NumTerms { get; set; }
    public bool IsIndexing { get; set; }
    
    public override string ToString()
    {
        return $"{IndexName}: Documents={NumDocs}, Records={NumRecords}, Terms={NumTerms}, Indexing={IsIndexing}";
    }
}

/// <summary>
/// معلومات جميع الفهارس الثلاثة
/// </summary>
public sealed class IndexesInfo
{
    public IndexInfo? UnitsIndex { get; set; }
    public IndexInfo? ScheduleIndex { get; set; }
    
    public long TotalDocuments => 
        (UnitsIndex?.NumDocs ?? 0) + 
        (ScheduleIndex?.NumDocs ?? 0);
    
    public override string ToString()
    {
        return $"Total Documents: {TotalDocuments}\n" +
               $"  - {UnitsIndex}\n" +
               $"  - {ScheduleIndex}";
    }
}
