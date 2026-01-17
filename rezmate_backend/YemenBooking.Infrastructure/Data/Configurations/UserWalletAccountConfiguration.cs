using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Data.Configurations;

public class UserWalletAccountConfiguration : IEntityTypeConfiguration<UserWalletAccount>
{
    public void Configure(EntityTypeBuilder<UserWalletAccount> builder)
    {
        builder.ToTable("UserWalletAccounts");

        builder.HasKey(x => x.Id);

        builder.Property(b => b.Id)
            .HasColumnName("UserWalletAccountId")
            .IsRequired();

        builder.Property(b => b.IsDeleted).HasDefaultValue(false);
        builder.Property(b => b.DeletedAt).HasColumnType("timestamp with time zone");

        builder.Property(x => x.UserId).IsRequired();

        builder.Property(x => x.WalletType)
            .IsRequired();

        builder.Property(x => x.AccountNumber)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(x => x.AccountName)
            .HasMaxLength(150);

        builder.Property(x => x.IsDefault)
            .HasDefaultValue(false);

        builder.HasIndex(x => new { x.UserId, x.WalletType })
            .HasDatabaseName("IX_UserWalletAccounts_UserId_WalletType");

        builder.HasOne(x => x.User)
            .WithMany(u => u.WalletAccounts)
            .HasForeignKey(x => x.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasQueryFilter(x => !x.IsDeleted);
    }
}
