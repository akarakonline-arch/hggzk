using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using YemenBooking.Infrastructure.Data.Configurations.Indexes;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Data.Initialization;

/// <summary>
/// خدمة خلفية لتهيئة فهارس قاعدة البيانات تلقائياً عند بدء التطبيق
/// تضمن إنشاء جميع الفهارس المتقدمة حتى لو تم حذف Migrations
/// </summary>
public class DatabaseIndexInitializerService : IHostedService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<DatabaseIndexInitializerService> _logger;

    public DatabaseIndexInitializerService(
        IServiceProvider serviceProvider,
        ILogger<DatabaseIndexInitializerService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    public async Task StartAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("🚀 بدء تهيئة فهارس قاعدة البيانات...");

        try
        {
            using var scope = _serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            var indexInitializer = new PostgresIndexInitializer(
                context,
                scope.ServiceProvider.GetRequiredService<ILogger<PostgresIndexInitializer>>());

            // التأكد من وجود قاعدة البيانات
            await context.Database.EnsureCreatedAsync(cancellationToken);

            // تطبيق الفهارس
            await indexInitializer.ApplyIndexesAsync();

            _logger.LogInformation("✅ اكتملت تهيئة الفهارس بنجاح");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ خطأ أثناء تهيئة الفهارس");
            // لا نرمي الاستثناء لتجنب إيقاف التطبيق
        }
    }

    public Task StopAsync(CancellationToken cancellationToken)
    {
        return Task.CompletedTask;
    }
}
