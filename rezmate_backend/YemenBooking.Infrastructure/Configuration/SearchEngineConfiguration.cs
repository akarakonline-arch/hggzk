using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using YemenBooking.Infrastructure.Postgres.Configuration;
using YemenBooking.Infrastructure.Redis.Configuration;

namespace YemenBooking.Infrastructure.Configuration;

/// <summary>
/// تكوين محرك البحث الديناميكي
/// 
/// الاستخدام في Program.cs:
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// builder.Services.AddSearchEngine(builder.Configuration);
/// 
/// التحكم من appsettings.json:
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// {
///   "SearchEngine": {
///     "Provider": "Redis",  // أو "Postgres"
///     "AutoFallback": true  // التبديل التلقائي لـ Postgres إذا فشل Redis
///   }
/// }
/// </summary>
public static class SearchEngineConfiguration
{
    /// <summary>
    /// إضافة محرك البحث حسب التكوين
    /// </summary>
    public static IServiceCollection AddSearchEngine(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        var searchEngineConfig = configuration
            .GetSection("SearchEngine")
            .Get<SearchEngineOptions>() ?? new SearchEngineOptions();
        
        // تسجيل الخيارات
        services.AddSingleton(searchEngineConfig);
        
        var provider = searchEngineConfig.Provider?.ToLowerInvariant() ?? "postgres";
        
        switch (provider)
        {
            case "redis":
                return services.AddRedisSearchEngine(configuration, searchEngineConfig);
            
            case "postgres":
            case "postgresql":
                return services.AddPostgresSearchEngine(configuration);
            
            case "auto":
                return services.AddAutoSearchEngine(configuration, searchEngineConfig);
            
            default:
                throw new InvalidOperationException(
                    $"مزود محرك البحث غير مدعوم: {searchEngineConfig.Provider}. " +
                    $"القيم المسموحة: Redis, Postgres, Auto");
        }
    }
    
    /// <summary>
    /// إضافة محرك بحث Redis
    /// </summary>
    private static IServiceCollection AddRedisSearchEngine(
        this IServiceCollection services,
        IConfiguration configuration,
        SearchEngineOptions options)
    {
        try
        {
            var redisConnectionString = configuration.GetConnectionString("Redis");
            
            if (string.IsNullOrWhiteSpace(redisConnectionString))
            {
                if (options.AutoFallback)
                {
                    Console.WriteLine("⚠️  سلسلة اتصال Redis غير موجودة - التبديل إلى PostgreSQL");
                    return services.AddPostgresSearchEngine(configuration);
                }
                
                throw new InvalidOperationException(
                    "سلسلة اتصال Redis مطلوبة عند استخدام Provider=Redis. " +
                    "أو فعّل AutoFallback للتبديل التلقائي إلى PostgreSQL.");
            }
            
            services.AddRedisServices(configuration);
            
            Console.WriteLine("✅ تم تفعيل محرك البحث: Redis (UltraOptimizedSearchEngine)");
            
            return services;
        }
        catch (Exception ex)
        {
            if (options.AutoFallback)
            {
                Console.WriteLine($"⚠️  فشل تفعيل Redis: {ex.Message}");
                Console.WriteLine("🔄 التبديل إلى PostgreSQL...");
                return services.AddPostgresSearchEngine(configuration);
            }
            
            throw;
        }
    }
    
    /// <summary>
    /// إضافة محرك بحث PostgreSQL
    /// </summary>
    private static IServiceCollection AddPostgresSearchEngine(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.AddPostgresSearchServices(configuration);
        
        Console.WriteLine("✅ تم تفعيل محرك البحث: PostgreSQL (PostgresUnitSearchEngine)");
        
        return services;
    }
    
    /// <summary>
    /// اختيار تلقائي بناءً على توفر Redis
    /// </summary>
    private static IServiceCollection AddAutoSearchEngine(
        this IServiceCollection services,
        IConfiguration configuration,
        SearchEngineOptions options)
    {
        var redisConnectionString = configuration.GetConnectionString("Redis");
        
        if (!string.IsNullOrWhiteSpace(redisConnectionString))
        {
            try
            {
                // محاولة استخدام Redis
                services.AddRedisServices(configuration);
                Console.WriteLine("✅ تم اختيار محرك البحث تلقائياً: Redis");
                return services;
            }
            catch
            {
                Console.WriteLine("⚠️  فشل الاتصال بـ Redis - استخدام PostgreSQL");
            }
        }
        
        // استخدام PostgreSQL كبديل
        services.AddPostgresSearchServices(configuration);
        Console.WriteLine("✅ تم اختيار محرك البحث تلقائياً: PostgreSQL");
        
        return services;
    }
}

/// <summary>
/// خيارات تكوين محرك البحث
/// </summary>
public class SearchEngineOptions
{
    /// <summary>
    /// المزود المستخدم
    /// القيم المسموحة: Redis, Postgres, Auto
    /// </summary>
    public string Provider { get; set; } = "Postgres";
    
    /// <summary>
    /// التبديل التلقائي إلى PostgreSQL إذا فشل Redis
    /// </summary>
    public bool AutoFallback { get; set; } = true;
    
    /// <summary>
    /// تفعيل التسجيل التفصيلي
    /// </summary>
    public bool EnableDetailedLogging { get; set; } = false;
}
