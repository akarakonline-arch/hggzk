using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations.Indexes;

/// <summary>
/// تكوين فهارس جدول PropertyAmenities
/// </summary>
public class PropertyAmenityIndexConfiguration : IEntityTypeConfiguration<PropertyAmenity>
{
    public void Configure(EntityTypeBuilder<PropertyAmenity> builder)
    {
        // فهرس على PropertyId + PtaId (PropertyTypeAmenityId)
        builder.HasIndex(pa => new { pa.PropertyId, pa.PtaId })
            .HasDatabaseName("IX_PropertyAmenities_PropertyId_PtaId");
        
        // فهرس على PtaId (للبحث العكسي)
        builder.HasIndex(pa => pa.PtaId)
            .HasDatabaseName("IX_PropertyAmenities_PtaId");
    }
}
