// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// استيراد المكتبات المطلوبة
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
using System;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Infrastructure.Redis.Core;
using YemenBooking.Infrastructure.Redis.Core.Interfaces;
using YemenBooking.Infrastructure.Redis.Cache;
using YemenBooking.Infrastructure.Redis.Indexing;
using YemenBooking.Infrastructure.Redis.Monitoring;
using YemenBooking.Infrastructure.Redis.HealthChecks;

namespace YemenBooking.Infrastructure.Redis.Configuration
{
    /// <summary>
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// تكوين وتسجيل خدمات Redis
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// 
    /// المسؤولية:
    /// • تسجيل جميع خدمات Redis في حاوية Dependency Injection
    /// • تكوين خيارات Redis من ملف الإعدادات
    /// • إضافة فحوصات الصحة (Health Checks)
    /// • التحقق من الاتصال بـ Redis عند بدء التطبيق
    /// 
    /// الخدمات المُسجَّلة:
    /// 1. IRedisConnectionManager - إدارة الاتصال بـ Redis
    /// 2. IRedisCache - خدمات التخزين المؤقت
    /// 3. IHealthCheckService - فحص صحة الخدمات
    /// 4. IUnitIndexingService - فهرسة الوحدات
    /// 5. IIndexingService - الفهرسة الرئيسية
    /// </summary>
    public static class RedisServiceConfiguration
    {
        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// إضافة خدمات Redis إلى حاوية الخدمات
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// 
        /// الاستخدام:
        /// في Program.cs أو Startup.cs:
        /// services.AddRedisServices(configuration);
        /// </summary>
        /// <param name="services">حاوية الخدمات</param>
        /// <param name="configuration">مصدر الإعدادات (appsettings.json)</param>
        /// <returns>نفس حاوية الخدمات للسلسلة (Method Chaining)</returns>
        /// <exception cref="InvalidOperationException">إذا لم تكن سلسلة اتصال Redis موجودة</exception>
        public static IServiceCollection AddRedisServices(
            this IServiceCollection services,
            IConfiguration configuration)
        {
            // ━━━ التحقق من وجود سلسلة اتصال Redis ━━━
            var redisConnectionString = configuration.GetConnectionString("Redis");
            if (string.IsNullOrWhiteSpace(redisConnectionString))
            {
                throw new InvalidOperationException("Redis connection string is not configured");
            }

            // ━━━ تسجيل الخدمات الأساسية (Singleton) ━━━
            // Singleton: نسخة واحدة لكامل التطبيق
            services.AddSingleton<IRedisConnectionManager, RedisConnectionManager>();
            services.AddSingleton<IRedisCache, RedisCache>();
            // تعطيل IHealthCheckService مؤقتاً لحل مشكلة DI
            // services.AddSingleton<IHealthCheckService, Monitoring.HealthCheckService>();
            
            // ━━━ تسجيل خدمات الفهرسة والبحث المحسّنة (Singleton) ━━━
            // UltraOptimizedSearchEngine: محرك البحث المحسّن باستخدام Lua Scripts
            services.AddSingleton<IUnitSearchEngine, UltraOptimizedSearchEngine>();
            services.AddSingleton<UltraOptimizedSearchEngine>();
            
            // OptimizedUnitIndexingService: خدمة الفهرسة + البحث (تستخدم UltraOptimizedSearchEngine)
            services.AddSingleton<OptimizedUnitIndexingService>();
            
            // ━━━ تسجيل الواجهة للخدمة الجديدة (Scoped) ━━━
            services.AddScoped<IUnitIndexingService>(sp => 
                sp.GetRequiredService<OptimizedUnitIndexingService>());
            
            // ━━━ إضافة فحوصات الصحة (Health Checks) ━━━
            services.AddHealthChecks()
                .AddCheck<IndexingHealthCheck>(
                    "indexing", // اسم الفحص
                    failureStatus: Microsoft.Extensions.Diagnostics.HealthChecks.HealthStatus.Unhealthy, // الحالة عند الفشل
                    tags: new[] { "redis", "indexing" } // علامات للتصنيف
                );

            // ━━━ تكوين خيارات Redis من ملف الإعدادات ━━━
            services.Configure<RedisOptions>(configuration.GetSection("Redis"));

            return services;
        }

        /// <summary>
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// تهيئة والتحقق من خدمات Redis
        /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        /// 
        /// الاستخدام:
        /// في Program.cs بعد بناء التطبيق:
        /// app.Services.InitializeRedisServices();
        /// 
        /// الغرض:
        /// التحقق من أن الاتصال بـ Redis يعمل قبل بدء التطبيق
        /// </summary>
        /// <param name="serviceProvider">مزود الخدمات المبني</param>
        /// <returns>نفس مزود الخدمات للسلسلة</returns>
        /// <exception cref="InvalidOperationException">إذا فشل الاتصال بـ Redis</exception>
        public static IServiceProvider InitializeRedisServices(this IServiceProvider serviceProvider)
        {
            // ━━━ الحصول على مدير اتصالات Redis ━━━
            var redisManager = serviceProvider.GetRequiredService<IRedisConnectionManager>();
            
            // ━━━ التحقق من الاتصال (بشكل متزامن) ━━━
            var isConnected = redisManager.IsConnectedAsync().GetAwaiter().GetResult();
            
            // ━━━ رمي استثناء إذا فشل الاتصال ━━━
            if (!isConnected)
            {
                throw new InvalidOperationException("Failed to connect to Redis");
            }

            return serviceProvider;
        }
    }

    /// <summary>
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// خيارات تكوين Redis
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// 
    /// يتم ملء هذه الخيارات من قسم "Redis" في appsettings.json
    /// 
    /// مثال من appsettings.json:
    /// {
    ///   "Redis": {
    ///     "ConnectionString": "localhost:6379",
    ///     "DatabaseNumber": 0,
    ///     "ConnectTimeout": 5000,
    ///     "DefaultExpiryMinutes": 60
    ///   }
    /// }
    /// </summary>
    public class RedisOptions
    {
        /// <summary>سلسلة الاتصال (host:port أو host:port,password=xyz)</summary>
        public string ConnectionString { get; set; }
        
        /// <summary>رقم قاعدة البيانات (0-15 في Redis الافتراضي)</summary>
        public int DatabaseNumber { get; set; } = 0;
        
        /// <summary>وقت انتظار الاتصال بالميلي ثانية</summary>
        public int ConnectTimeout { get; set; } = 5000;
        
        /// <summary>وقت انتهاء العمليات المتزامنة بالميلي ثانية</summary>
        public int SyncTimeout { get; set; } = 5000;
        
        /// <summary>وقت انتهاء العمليات غير المتزامنة بالميلي ثانية</summary>
        public int AsyncTimeout { get; set; } = 5000;
        
        /// <summary>فترة keep-alive بالثواني للحفاظ على الاتصال حياً</summary>
        public int KeepAlive { get; set; } = 60;
        
        /// <summary>عدد محاولات إعادة الاتصال</summary>
        public int ConnectRetry { get; set; } = 3;
        
        /// <summary>هل يتم إيقاف التطبيق عند فشل الاتصال الأولي</summary>
        public bool AbortOnConnectFail { get; set; } = false;
        
        /// <summary>السماح بأوامر الإدارة (KEYS, FLUSHALL, إلخ)</summary>
        public bool AllowAdmin { get; set; } = false;
        
        /// <summary>كلمة المرور (إذا كانت موجودة)</summary>
        public string Password { get; set; }
        
        /// <summary>استخدام SSL/TLS للاتصال الآمن</summary>
        public bool Ssl { get; set; } = false;
        
        /// <summary>اسم المضيف لشهادة SSL</summary>
        public string SslHost { get; set; }
        
        /// <summary>وقت انتهاء الصلاحية الافتراضي للمفاتيح (بالدقائق)</summary>
        public int DefaultExpiryMinutes { get; set; } = 60;
        
        /// <summary>تفعيل التسجيل التفصيلي</summary>
        public bool EnableLogging { get; set; } = true;
        
        /// <summary>تفعيل جمع المقاييس (Metrics)</summary>
        public bool EnableMetrics { get; set; } = true;
    }
}
