using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using System.IO;

namespace YemenBooking.Infrastructure.Data.Context;

/// <summary>
/// Factory for design-time DbContext creation.
/// مولد سياق قاعدة البيانات في وقت التصميم
/// 
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// الاستخدام:
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// • يُستخدم فقط في Design-Time لأدوات EF Core مثل:
///   - dotnet ef migrations add
///   - dotnet ef database update
///   - Update-Database في Package Manager Console
/// 
/// • لا يُستخدم في Runtime - الـDI Container يقوم بإنشاء DbContext تلقائياً
/// 
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// المميزات:
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// ✅ قراءة Connection String من appsettings.json تلقائياً
/// ✅ دعم بيئات متعددة (Development, Production)
/// ✅ لا تأثير على Runtime أو البحث/الفلترة
/// ✅ يستخدم Constructor المخصص للـDesign-Time (بدون HttpContext)
/// </summary>
public class YemenBookingDbContextFactory : IDesignTimeDbContextFactory<YemenBookingDbContext>
{
    public YemenBookingDbContext CreateDbContext(string[] args)
    {
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // قراءة Configuration من appsettings.json
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        // تحديد مسار مجلد YemenBooking.Api
        var apiProjectPath = Path.Combine(
            Directory.GetCurrentDirectory(),
            "..",
            "YemenBooking.Api"
        );
        
        // إذا لم يكن المسار صحيح، استخدم المسار الحالي
        if (!Directory.Exists(apiProjectPath))
        {
            apiProjectPath = Directory.GetCurrentDirectory();
        }
        
        // بناء Configuration من appsettings.json و appsettings.Development.json
        var configuration = new ConfigurationBuilder()
            .SetBasePath(apiProjectPath)
            .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
            .AddJsonFile("appsettings.Development.json", optional: true, reloadOnChange: true)
            .AddEnvironmentVariables()
            .Build();
        
        // قراءة Connection String من Configuration
        var connectionString = configuration.GetConnectionString("DefaultConnection");
        
        // التحقق من وجود Connection String
        if (string.IsNullOrEmpty(connectionString))
        {
            throw new InvalidOperationException(
                "❌ لم يتم العثور على Connection String في appsettings.json\n" +
                "تأكد من وجود 'ConnectionStrings:DefaultConnection' في ملف الإعدادات");
        }
        
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // إنشاء DbContext Options
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        var optionsBuilder = new DbContextOptionsBuilder<YemenBookingDbContext>();
        
        optionsBuilder.UseNpgsql(
            connectionString,
            npgsqlOptions =>
            {
                // تفعيل Retry للـMigrations
                npgsqlOptions.EnableRetryOnFailure(
                    maxRetryCount: 3,
                    maxRetryDelay: TimeSpan.FromSeconds(5),
                    errorCodesToAdd: null);
                
                // تعيين Assembly للـMigrations
                npgsqlOptions.MigrationsAssembly("YemenBooking.Infrastructure");
            });
        
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // إنشاء DbContext بدون IHttpContextAccessor
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // ⚠️ يستخدم Constructor المخصص للـDesign-Time
        // HttpContext غير متوفر في Design-Time وهذا طبيعي
        
        return new YemenBookingDbContext(optionsBuilder.Options);
    }
} 