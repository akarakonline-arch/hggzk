using Microsoft.Extensions.DependencyInjection;
using YemenBooking.Infrastructure.Data.Initialization;

namespace YemenBooking.Infrastructure.Data.Configurations.Indexes;

/// <summary>
/// امتدادات لتسجيل خدمات تهيئة الفهارس
/// </summary>
public static class IndexInitializationExtensions
{
    /// <summary>
    /// تسجيل خدمة تهيئة الفهارس التلقائية
    /// تُستدعى عند بدء التطبيق لإنشاء جميع الفهارس المتقدمة
    /// </summary>
    public static IServiceCollection AddDatabaseIndexInitialization(this IServiceCollection services)
    {
        services.AddHostedService<DatabaseIndexInitializerService>();
        return services;
    }
}
