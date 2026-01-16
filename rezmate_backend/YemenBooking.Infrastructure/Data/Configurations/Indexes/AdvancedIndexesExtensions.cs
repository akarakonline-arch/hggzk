using Microsoft.EntityFrameworkCore;
using Npgsql.EntityFrameworkCore.PostgreSQL.Infrastructure;

namespace YemenBooking.Infrastructure.Data.Configurations.Indexes;

/// <summary>
/// امتدادات لإضافة الفهارس المتقدمة التي لا يدعمها EF Core Fluent API
/// يتم استدعاؤها تلقائياً في OnModelCreating
/// </summary>
public static class AdvancedIndexesExtensions
{
    /// <summary>
    /// إضافة جميع الفهارس المتقدمة لتحسين الأداء
    /// يتم تطبيقها تلقائياً حتى بدون Migrations
    /// </summary>
    public static void ConfigureAdvancedIndexes(this ModelBuilder modelBuilder)
    {
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // 1. فهارس Units المتقدمة
        // ⚠️ تم إزالة جميع الفهارس المعتمدة على IsAvailable
        // السبب: البحث يعتمد على UnitAvailabilities فقط، وليس على IsAvailable
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        // ملاحظة: الفهارس التي تحتوي على BasePrice_Amount يتم إنشاؤها في UnitIndexConfiguration
        // باستخدام OwnsOne() للحصول على Type-Safe indexes
        
        // Composite Index شامل (بدون IsAvailable)
        modelBuilder.Entity<Core.Entities.Unit>()
            .HasIndex("UnitTypeId", "PropertyId", "MaxCapacity")
            .HasDatabaseName("IX_Units_Composite_Advanced");
        
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // 2. فهارس Properties المتقدمة
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        // Composite Index شامل
        modelBuilder.Entity<Core.Entities.Property>()
            .HasIndex("City", "TypeId", "IsApproved", "AverageRating", "StarRating")
            .HasDatabaseName("IX_Properties_Composite_Main");
        
        // Partial Index على العقارات المعتمدة فقط
        modelBuilder.Entity<Core.Entities.Property>()
            .HasIndex("AverageRating")
            .HasDatabaseName("IX_Properties_AverageRating_Approved")
            .HasFilter("\"IsApproved\" = true")
            .IsDescending();
        
        // Partial Index على العقارات المميزة
        modelBuilder.Entity<Core.Entities.Property>()
            .HasIndex("IsFeatured", "AverageRating", "StarRating")
            .HasDatabaseName("IX_Properties_Featured")
            .HasFilter("\"IsFeatured\" = true AND \"IsApproved\" = true")
            .IsDescending();
        
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // 3. فهارس DailyUnitSchedule المتقدمة (الكيان الموحد الجديد)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        // Partial Index على الأيام المحجوزة أو المحظورة فقط (تحسين فلتر الإتاحة)
        modelBuilder.Entity<Core.Entities.DailyUnitSchedule>()
            .HasIndex("UnitId", "Date", "Status")
            .HasDatabaseName("IX_DailyUnitSchedules_Unavailable")
            .HasFilter("\"Status\" != 'Available'");
        
        // Partial Index على الأيام المتاحة مع الأسعار (تحسين فلتر السعر)
        modelBuilder.Entity<Core.Entities.DailyUnitSchedule>()
            .HasIndex("Date", "PriceAmount", "Currency")
            .HasDatabaseName("IX_DailyUnitSchedules_Available_Price")
            .HasFilter("\"Status\" = 'Available' AND \"PriceAmount\" IS NOT NULL");
        
        // فهرس مركب للبحث السريع في نطاقات التاريخ
        // يستخدم في الاستعلامات التي تبحث عن الوحدات المتاحة في فترة معينة
        modelBuilder.Entity<Core.Entities.DailyUnitSchedule>()
            .HasIndex("Date", "UnitId")
            .HasDatabaseName("IX_DailyUnitSchedules_Date_UnitId")
            .IsDescending(true, false);
        
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // 4. فهارس PropertyImages
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        // فهرس على PropertyId + DisplayOrder
        modelBuilder.Entity<Core.Entities.PropertyImage>()
            .HasIndex("PropertyId", "DisplayOrder")
            .HasDatabaseName("IX_PropertyImages_PropertyId_DisplayOrder");
        
        // Partial Index على صور الوحدات فقط
        modelBuilder.Entity<Core.Entities.PropertyImage>()
            .HasIndex("UnitId", "DisplayOrder")
            .HasDatabaseName("IX_PropertyImages_UnitId_DisplayOrder")
            .HasFilter("\"UnitId\" IS NOT NULL");
    }
    
    /// <summary>
    /// إضافة الفهارس المتقدمة جداً (Full-Text, GiST, Covering)
    /// التي تحتاج Raw SQL
    /// </summary>
    public static void ConfigurePostgreSQLSpecificIndexes(this ModelBuilder modelBuilder)
    {
        // ملاحظة: هذه الفهارس تحتاج تنفيذ عبر Raw SQL
        // سيتم إضافتها في OnModelCreating باستخدام relational API
        
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // 1. Full-Text Search Indexes (GIN)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        // Units - Full-Text على Name
        modelBuilder.Entity<Core.Entities.Unit>()
            .HasIndex("Name")
            .HasDatabaseName("IX_Units_Name_FTS")
            .HasMethod("gin")
            .HasOperators("gin_trgm_ops");
        
        // Properties - Full-Text على Name, Description, Address
        // ملاحظة: EF Core لا يدعم expression indexes، يجب استخدام Raw SQL
        
        // UnitFieldValues - Full-Text على Value
        modelBuilder.Entity<Core.Entities.UnitFieldValue>()
            .HasIndex("Value")
            .HasDatabaseName("IX_UnitFieldValues_Value_FTS")
            .HasMethod("gin")
            .HasOperators("gin_trgm_ops");
        
        // UnitTypes - Full-Text على Name
        modelBuilder.Entity<Core.Entities.UnitType>()
            .HasIndex("Name")
            .HasDatabaseName("IX_UnitTypes_Name_FTS")
            .HasMethod("gin")
            .HasOperators("gin_trgm_ops");
    }
}
