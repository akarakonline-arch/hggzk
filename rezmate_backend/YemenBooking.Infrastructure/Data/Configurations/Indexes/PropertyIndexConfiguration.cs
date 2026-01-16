using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations.Indexes;

/// <summary>
/// تكوين فهارس جدول Properties
/// </summary>
public class PropertyIndexConfiguration : IEntityTypeConfiguration<Property>
{
    public void Configure(EntityTypeBuilder<Property> builder)
    {
        // فهرس على City + IsApproved
        builder.HasIndex(p => new { p.City, p.IsApproved })
            .HasDatabaseName("IX_Properties_City_IsApproved");
        
        // فهرس على TypeId + IsApproved
        builder.HasIndex(p => new { p.TypeId, p.IsApproved })
            .HasDatabaseName("IX_Properties_TypeId_IsApproved");
        
        // فهرس على AverageRating (تنازلي)
        builder.HasIndex(p => p.AverageRating)
            .HasDatabaseName("IX_Properties_AverageRating")
            .IsDescending();
        
        // فهرس على StarRating (تنازلي)
        builder.HasIndex(p => p.StarRating)
            .HasDatabaseName("IX_Properties_StarRating")
            .IsDescending();
        
        // فهرس على OwnerId + IsApproved
        builder.HasIndex(p => new { p.OwnerId, p.IsApproved })
            .HasDatabaseName("IX_Properties_OwnerId_IsApproved");
        
        // فهرس على CreatedAt (تنازلي)
        builder.HasIndex(p => p.CreatedAt)
            .HasDatabaseName("IX_Properties_CreatedAt")
            .IsDescending();
        
        // فهرس على Latitude و Longitude (للبحث الجغرافي)
        builder.HasIndex(p => new { p.Latitude, p.Longitude })
            .HasDatabaseName("IX_Properties_Location");
    }
}
