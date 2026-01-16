namespace YemenBooking.Infrastructure.Data.Configurations;

using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

/// <summary>
/// إعدادات كيان الجدول اليومي الموحد للوحدة
/// Configuration for Daily Unit Schedule entity
/// </summary>
public class DailyUnitScheduleConfiguration : IEntityTypeConfiguration<DailyUnitSchedule>
{
    public void Configure(EntityTypeBuilder<DailyUnitSchedule> builder)
    {
        // اسم الجدول / Table name
        builder.ToTable("DailyUnitSchedules");

        // المفتاح الأساسي / Primary key
        builder.HasKey(d => d.Id);

        // خصائص مطلوبة / Required properties
        builder.Property(d => d.UnitId)
            .IsRequired();

        builder.Property(d => d.Date)
            .IsRequired()
            .HasColumnType("date"); // يخزن التاريخ فقط بدون وقت

        builder.Property(d => d.Status)
            .IsRequired()
            .HasMaxLength(50)
            .HasDefaultValue("Available");

        // خصائص اختيارية / Optional properties
        builder.Property(d => d.Reason)
            .HasMaxLength(200);

        builder.Property(d => d.Notes)
            .HasMaxLength(1000);

        builder.Property(d => d.PriceAmount)
            .HasColumnType("decimal(18,2)");

        builder.Property(d => d.Currency)
            .HasMaxLength(3); // ISO 4217 currency code

        builder.Property(d => d.PriceType)
            .HasMaxLength(50);

        builder.Property(d => d.PricingTier)
            .HasMaxLength(50);

        builder.Property(d => d.PercentageChange)
            .HasColumnType("decimal(5,2)");

        builder.Property(d => d.MinPrice)
            .HasColumnType("decimal(18,2)");

        builder.Property(d => d.MaxPrice)
            .HasColumnType("decimal(18,2)");

        builder.Property(d => d.CreatedBy)
            .HasMaxLength(100);

        builder.Property(d => d.ModifiedBy)
            .HasMaxLength(100);

        // العلاقات / Relationships
        
        // علاقة مع الوحدة / Relationship with Unit
        builder.HasOne(d => d.Unit)
            .WithMany(u => u.DailySchedules)
            .HasForeignKey(d => d.UnitId)
            .OnDelete(DeleteBehavior.Cascade);

        // علاقة مع الحجز / Relationship with Booking
        builder.HasOne(d => d.Booking)
            .WithMany()
            .HasForeignKey(d => d.BookingId)
            .OnDelete(DeleteBehavior.SetNull);

        // علاقة مع العملة / Relationship with Currency
        builder.HasOne(d => d.CurrencyRef)
            .WithMany()
            .HasForeignKey(d => d.Currency)
            .HasPrincipalKey(c => c.Code)
            .OnDelete(DeleteBehavior.NoAction);

        // الفهارس / Indexes
        
        // فهرس مركب فريد: وحدة + تاريخ (لا يمكن تكرار نفس اليوم لنفس الوحدة)
        // Unique composite index: unit + date
        builder.HasIndex(d => new { d.UnitId, d.Date })
            .IsUnique()
            .HasDatabaseName("IX_DailyUnitSchedules_UnitId_Date");

        // فهرس للبحث بالتاريخ
        // Index for searching by date
        builder.HasIndex(d => d.Date)
            .HasDatabaseName("IX_DailyUnitSchedules_Date");

        // فهرس للبحث بالحالة
        // Index for searching by status
        builder.HasIndex(d => d.Status)
            .HasDatabaseName("IX_DailyUnitSchedules_Status");

        // فهرس للبحث بالحجز
        // Index for searching by booking
        builder.HasIndex(d => d.BookingId)
            .HasDatabaseName("IX_DailyUnitSchedules_BookingId");

        // فهرس مركب للبحث الفعال: وحدة + تاريخ + حالة
        // Composite index for efficient searching: unit + date + status
        builder.HasIndex(d => new { d.UnitId, d.Date, d.Status })
            .HasDatabaseName("IX_DailyUnitSchedules_UnitId_Date_Status");

        // فهرس للأسعار (للاستعلامات التحليلية)
        // Index for prices (for analytical queries)
        builder.HasIndex(d => new { d.UnitId, d.PriceAmount })
            .HasDatabaseName("IX_DailyUnitSchedules_UnitId_PriceAmount")
            .HasFilter("\"PriceAmount\" IS NOT NULL");
        
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // فهارس متقدمة للبحث والفلترة السريعة
        // Advanced indexes for fast search and filtering
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        // Covering Index شامل للإتاحة والتسعير (يحتوي على جميع الأعمدة المستخدمة في البحث)
        // يسمح بـ Index-Only Scans بدون الحاجة للرجوع للجدول الأصلي
        builder.HasIndex(d => new { d.UnitId, d.Date, d.Status, d.PriceAmount, d.Currency })
            .HasDatabaseName("IX_DailyUnitSchedules_Covering")
            .HasFilter("\"PriceAmount\" IS NOT NULL");
        
        // فهرس مركب للبحث حسب التاريخ أولاً (للاستعلامات التي تبدأ بتصفية التاريخ)
        builder.HasIndex(d => new { d.Date, d.Status, d.UnitId })
            .HasDatabaseName("IX_DailyUnitSchedules_Date_Status_UnitId");
        
        // فهرس للعملة والسعر (للفلترة متعددة العملات)
        builder.HasIndex(d => new { d.Currency, d.PriceAmount })
            .HasDatabaseName("IX_DailyUnitSchedules_Currency_Price")
            .HasFilter("\"PriceAmount\" IS NOT NULL AND \"Currency\" IS NOT NULL");

        // خصائص الوراثة من BaseEntity
        // Inherited properties from BaseEntity
        builder.Property(d => d.CreatedAt)
            .IsRequired()
            .HasDefaultValueSql("NOW()");

        builder.Property(d => d.UpdatedAt)
            .IsRequired()
            .HasDefaultValueSql("NOW()");

        // Global Query Filter
        builder.HasQueryFilter(d => !d.IsDeleted);
    }
}
