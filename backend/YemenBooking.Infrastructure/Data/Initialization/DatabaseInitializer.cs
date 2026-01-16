using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using YemenBooking.Infrastructure.Data.Context;
using System.Reflection;
using Npgsql;

namespace YemenBooking.Infrastructure.Data.Initialization;

public class DatabaseInitializer
{
    private readonly YemenBookingDbContext _context;
    private readonly ILogger<DatabaseInitializer> _logger;

    public DatabaseInitializer(
        YemenBookingDbContext context,
        ILogger<DatabaseInitializer> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task InitializeAsync()
    {
        try
        {
            _logger.LogInformation("🔧 بدء تهيئة قاعدة البيانات...");

            await _context.Database.MigrateAsync();
            _logger.LogInformation("✅ تم تطبيق Migrations بنجاح");

            await ExecuteEmbeddedSqlScriptsAsync();
            
            _logger.LogInformation("✅ اكتملت تهيئة قاعدة البيانات بنجاح");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ خطأ أثناء تهيئة قاعدة البيانات");
            throw;
        }
    }

    private async Task ExecuteEmbeddedSqlScriptsAsync()
    {
        try
        {
            var assembly = typeof(DatabaseInitializer).Assembly;
            
            var orderedFolders = new[]
            {
                "Functions",
                "Views",
                "Indexes",
                "Fixes"
            };

            var totalFilesExecuted = 0;

            foreach (var folder in orderedFolders)
            {
                var resourceNames = assembly.GetManifestResourceNames()
                    .Where(r => r.Contains($".SQL.{folder}.") && r.EndsWith(".sql"))
                    .OrderBy(r => r)
                    .ToList();

                if (!resourceNames.Any())
                {
                    _logger.LogDebug("⏭️ لا توجد ملفات SQL في مجلد: {Folder}", folder);
                    continue;
                }

                _logger.LogInformation("📁 معالجة مجلد: {Folder} ({Count} ملفات)", folder, resourceNames.Count);

                foreach (var resourceName in resourceNames)
                {
                    await ExecuteEmbeddedResourceAsync(assembly, resourceName);
                    totalFilesExecuted++;
                }
            }

            _logger.LogInformation("✅ تم تنفيذ {Count} ملف SQL من الموارد المضمنة", totalFilesExecuted);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "❌ خطأ أثناء تنفيذ SQL Scripts من الموارد المضمنة");
            throw;
        }
    }

    private async Task ExecuteEmbeddedResourceAsync(Assembly assembly, string resourceName)
    {
        try
        {
            var fileName = resourceName.Split('.').TakeLast(2).First();
            _logger.LogInformation("  📄 تنفيذ: {FileName}.sql", fileName);

            using var stream = assembly.GetManifestResourceStream(resourceName);
            if (stream == null)
            {
                _logger.LogWarning("  ⚠️ لا يمكن قراءة المورد: {ResourceName}", resourceName);
                return;
            }

            using var reader = new StreamReader(stream);
            var sqlContent = await reader.ReadToEndAsync();

            if (string.IsNullOrWhiteSpace(sqlContent))
            {
                _logger.LogWarning("  ⚠️ المورد فارغ: {FileName}", fileName);
                return;
            }

            var connectionString = _context.Database.GetConnectionString();
            await using var connection = new NpgsqlConnection(connectionString);
            await connection.OpenAsync();

            await using var command = new NpgsqlCommand(sqlContent, connection);
            command.CommandTimeout = 60;
            await command.ExecuteNonQueryAsync();
            
            _logger.LogInformation("  ✅ تم تنفيذ {FileName}.sql بنجاح", fileName);
        }
        catch (Exception ex)
        {
            var fileName = resourceName.Split('.').TakeLast(2).First();
            _logger.LogError(ex, "  ❌ خطأ أثناء تنفيذ {FileName}.sql", fileName);
        }
    }
}
