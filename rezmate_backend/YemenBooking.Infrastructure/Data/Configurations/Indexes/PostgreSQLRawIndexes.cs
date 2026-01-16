using Microsoft.EntityFrameworkCore;

namespace YemenBooking.Infrastructure.Data.Configurations.Indexes;

/// <summary>
/// فهارس PostgreSQL المتقدمة
/// 
/// ملاحظة:
/// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/// الفهارس المتقدمة (GIN, GiST, Covering, Expression) يتم إنشاؤها تلقائياً
/// عبر PostgresIndexInitializer عند بدء التطبيق، وليس عبر Migrations
/// هذا يضمن إنشاء الفهارس حتى لو تم حذف مجلد Migrations
/// </summary>
public static class PostgreSQLRawIndexes
{
    /// <summary>
    /// تطبيق امتدادات PostgreSQL المطلوبة
    /// الفهارس نفسها يتم إنشاؤها عبر PostgresIndexInitializer
    /// </summary>
    public static void ApplyPostgreSQLIndexes(this ModelBuilder modelBuilder)
    {
        // تفعيل امتدادات PostgreSQL المطلوبة
        modelBuilder.HasPostgresExtension("pg_trgm");      // للـ Full-Text Search
        modelBuilder.HasPostgresExtension("btree_gist");   // للـ Range Indexes
        
        // ملاحظة: الفهارس المتقدمة يتم إنشاؤها تلقائياً عبر DatabaseIndexInitializerService
        // عند بدء التطبيق، مما يضمن إنشائها حتى لو تم حذف Migrations
    }
}
