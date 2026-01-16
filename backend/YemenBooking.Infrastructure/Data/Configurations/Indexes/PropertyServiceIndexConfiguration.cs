using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations.Indexes;

/// <summary>
/// تكوين فهارس جدول PropertyServices
/// </summary>
public class PropertyServiceIndexConfiguration : IEntityTypeConfiguration<PropertyService>
{
    public void Configure(EntityTypeBuilder<PropertyService> builder)
    {
        // فهرس على PropertyId + Name (لأن PropertyService ليس لديها ServiceId منفصل)
        builder.HasIndex(ps => new { ps.PropertyId, ps.Name })
            .HasDatabaseName("IX_PropertyServices_PropertyId_Name");
        
        // فهرس على Name (للبحث العكسي)
        builder.HasIndex(ps => ps.Name)
            .HasDatabaseName("IX_PropertyServices_Name");
    }
}
