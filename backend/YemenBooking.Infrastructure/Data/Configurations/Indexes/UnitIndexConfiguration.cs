using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations.Indexes;

/// <summary>
/// تكوين فهارس جدول Units
/// يضمن إنشاء الفهارس تلقائياً حتى بدون Migrations
/// </summary>
public class UnitIndexConfiguration : IEntityTypeConfiguration<Unit>
{
    public void Configure(EntityTypeBuilder<Unit> builder)
    {
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // 1. فهارس B-Tree الأساسية
        // ملاحظة: تم إزالة جميع الفهارس التي تحتوي على IsAvailable
        // السبب: البحث يعتمد على UnitAvailabilities فقط، وليس على IsAvailable
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        
        // فهرس على PropertyId فقط (بدون IsAvailable)
        builder.HasIndex(u => u.PropertyId)
            .HasDatabaseName("IX_Units_PropertyId");
        
        // فهرس على UnitTypeId فقط (بدون IsAvailable)
        builder.HasIndex(u => u.UnitTypeId)
            .HasDatabaseName("IX_Units_UnitTypeId");
        
        // فهرس على MaxCapacity
        builder.HasIndex(u => u.MaxCapacity)
            .HasDatabaseName("IX_Units_MaxCapacity");
        
        // فهرس على AdultsCapacity و ChildrenCapacity
        builder.HasIndex(u => new { u.AdultsCapacity, u.ChildrenCapacity })
            .HasDatabaseName("IX_Units_Capacity");
        
        // فهرس على CreatedAt (تنازلي)
        builder.HasIndex(u => u.CreatedAt)
            .HasDatabaseName("IX_Units_CreatedAt")
            .IsDescending();
        
        // فهرس على BookingCount و ViewCount
        builder.HasIndex(u => new { u.BookingCount, u.ViewCount })
            .HasDatabaseName("IX_Units_Popularity")
            .IsDescending();
        
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // ملاحظة: تم إزالة BasePrice - نعتمد الآن على DailySchedules فقط
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    }
}
