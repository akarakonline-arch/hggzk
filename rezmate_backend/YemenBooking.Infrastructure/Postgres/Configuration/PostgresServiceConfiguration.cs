using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Infrastructure.Postgres.Indexing;

namespace YemenBooking.Infrastructure.Postgres.Configuration;

/// <summary>
/// تكوين خدمات PostgreSQL للبحث والفلترة
/// 
/// الاستخدام:
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// في Program.cs أو Startup.cs:
/// 
/// // استخدام PostgreSQL بدلاً من Redis:
/// builder.Services.AddPostgresSearchServices(builder.Configuration);
/// 
/// أو:
/// 
/// // استخدام Redis إذا كان متاحاً، وإلا استخدم PostgreSQL:
/// if (builder.Configuration.GetValue<bool>("UseRedis"))
/// {
///     builder.Services.AddRedisServices(builder.Configuration);
/// }
/// else
/// {
///     builder.Services.AddPostgresSearchServices(builder.Configuration);
/// }
/// </summary>
public static class PostgresServiceConfiguration
{
    /// <summary>
    /// إضافة خدمات PostgreSQL للبحث والفهرسة
    /// </summary>
    /// <param name="services">مجموعة الخدمات</param>
    /// <param name="configuration">التكوين</param>
    /// <returns>مجموعة الخدمات المحدثة</returns>
    public static IServiceCollection AddPostgresSearchServices(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // تسجيل خدمات البحث والفهرسة
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        // تسجيل محرك البحث (Scoped لاستخدام DbContext من DbContextPool)
        services.AddScoped<IUnitSearchEngine, PostgresUnitSearchEngine>();
        
        // تسجيل خدمة الفهرسة (Scoped لاستخدام DbContext من DbContextPool)
        services.AddScoped<IUnitIndexingService, PostgresUnitIndexingService>();
        
        // تسجيل التنفيذات المباشرة أيضاً للاستخدام المباشر
        services.AddScoped<PostgresUnitSearchEngine>();
        services.AddScoped<PostgresUnitIndexingService>();
        
        return services;
    }
    
    /// <summary>
    /// إضافة خدمات PostgreSQL مع تكوين متقدم
    /// </summary>
    /// <param name="services">مجموعة الخدمات</param>
    /// <param name="configuration">التكوين</param>
    /// <param name="configureOptions">تكوين إضافي (اختياري)</param>
    /// <returns>مجموعة الخدمات المحدثة</returns>
    public static IServiceCollection AddPostgresSearchServices(
        this IServiceCollection services,
        IConfiguration configuration,
        Action<PostgresSearchOptions>? configureOptions = null)
    {
        // تسجيل الخيارات
        var options = new PostgresSearchOptions();
        configureOptions?.Invoke(options);
        services.AddSingleton(options);
        
        // تسجيل الخدمات الأساسية
        services.AddPostgresSearchServices(configuration);
        
        return services;
    }
}

/// <summary>
/// خيارات تكوين البحث في PostgreSQL
/// </summary>
public class PostgresSearchOptions
{
    /// <summary>
    /// تفعيل التخزين المؤقت للنتائج
    /// </summary>
    public bool EnableCaching { get; set; } = false;
    
    /// <summary>
    /// مدة التخزين المؤقت بالدقائق
    /// </summary>
    public int CacheDurationMinutes { get; set; } = 5;
    
    /// <summary>
    /// تفعيل التسجيل التفصيلي
    /// </summary>
    public bool EnableDetailedLogging { get; set; } = false;
    
    /// <summary>
    /// الحد الأقصى لحجم الصفحة
    /// </summary>
    public int MaxPageSize { get; set; } = 100;
    
    /// <summary>
    /// الحد الأقصى للنتائج الإجمالية
    /// </summary>
    public int MaxTotalResults { get; set; } = 10000;
    
    /// <summary>
    /// تفعيل Full-Text Search
    /// </summary>
    public bool EnableFullTextSearch { get; set; } = true;
    
    /// <summary>
    /// تفعيل البحث الجغرافي
    /// </summary>
    public bool EnableGeographicSearch { get; set; } = true;
    
    /// <summary>
    /// لغة Full-Text Search (english, arabic, etc.)
    /// </summary>
    public string FullTextSearchLanguage { get; set; } = "english";
}
