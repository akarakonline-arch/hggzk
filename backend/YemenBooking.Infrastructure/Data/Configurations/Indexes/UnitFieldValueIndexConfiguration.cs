using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations.Indexes;

/// <summary>
/// تكوين فهارس جدول UnitFieldValues
/// </summary>
public class UnitFieldValueIndexConfiguration : IEntityTypeConfiguration<UnitFieldValue>
{
    public void Configure(EntityTypeBuilder<UnitFieldValue> builder)
    {
        // فهرس على UnitId + UnitTypeFieldId
        builder.HasIndex(fv => new { fv.UnitId, fv.UnitTypeFieldId })
            .HasDatabaseName("IX_UnitFieldValues_UnitId_UnitTypeFieldId");
        
        // فهرس على UnitTypeFieldId + FieldValue
        builder.HasIndex(fv => new { fv.UnitTypeFieldId, fv.FieldValue })
            .HasDatabaseName("IX_UnitFieldValues_UnitTypeFieldId_FieldValue");
    }
}
