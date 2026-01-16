using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using System;
using YemenBooking.Core.Seeds;
using System.Linq;

namespace YemenBooking.Core.Seeds
{
    /// <summary>
    /// فئة لتجميع وتشغيل جميع مولدات البيانات الأولية
    /// </summary>
    public static class DatabaseSeeder
    {
        public static void Seed(ModelBuilder modelBuilder)
        {
            var userSeeder = new UserSeeder();
            modelBuilder.Entity<User>().HasData(userSeeder.SeedData());

            // Static seeding for bookings removed to avoid owned type seed issues

            // Seed default currencies
            // Fixed: Use static date instead of DateTime.UtcNow for PostgreSQL compatibility
            var seedDate = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc);
            modelBuilder.Entity<Currency>().HasData(
                new Currency { Code = "YER", ArabicCode = "ريال", Name = "Yemeni Rial", ArabicName = "الريال اليمني", IsDefault = true, ExchangeRate = null, LastUpdated = null },
                new Currency { Code = "USD", ArabicCode = "دولار", Name = "US Dollar", ArabicName = "الدولار الأمريكي", IsDefault = false, ExchangeRate = 250m, LastUpdated = seedDate }
            );

            // Seed some cities
            modelBuilder.Entity<City>().HasData(
                new City { Name = "صنعاء", Country = "اليمن", ImagesJson = "[]" },
                new City { Name = "عدن", Country = "اليمن", ImagesJson = "[]" },
                new City { Name = "تعز", Country = "اليمن", ImagesJson = "[]" }
            );
            
            // Seed user roles
            // Fixed: Use static date instead of DateTime.UtcNow for PostgreSQL compatibility
            modelBuilder.Entity<UserRole>().HasData(
                // Admin
                new
                {
                    Id = Guid.Parse("CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"),
                    UserId = Guid.Parse("AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"),
                    RoleId = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                    AssignedAt = seedDate,
                    CreatedAt = seedDate,
                    UpdatedAt = seedDate,
                    IsActive = true,
                    IsDeleted = false
                },

                // Owners (one owner per property)
                new
                {
                    Id = Guid.Parse("DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDD001"),
                    UserId = Guid.Parse("BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBB01"),
                    RoleId = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                    AssignedAt = seedDate,
                    CreatedAt = seedDate,
                    UpdatedAt = seedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new
                {
                    Id = Guid.Parse("DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDD002"),
                    UserId = Guid.Parse("BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBB02"),
                    RoleId = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                    AssignedAt = seedDate,
                    CreatedAt = seedDate,
                    UpdatedAt = seedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new
                {
                    Id = Guid.Parse("DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDD003"),
                    UserId = Guid.Parse("BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBB03"),
                    RoleId = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                    AssignedAt = seedDate,
                    CreatedAt = seedDate,
                    UpdatedAt = seedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new
                {
                    Id = Guid.Parse("DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDD004"),
                    UserId = Guid.Parse("BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBB04"),
                    RoleId = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                    AssignedAt = seedDate,
                    CreatedAt = seedDate,
                    UpdatedAt = seedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new
                {
                    Id = Guid.Parse("DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDD005"),
                    UserId = Guid.Parse("BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBB05"),
                    RoleId = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                    AssignedAt = seedDate,
                    CreatedAt = seedDate,
                    UpdatedAt = seedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new
                {
                    Id = Guid.Parse("DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDD006"),
                    UserId = Guid.Parse("BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBB06"),
                    RoleId = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                    AssignedAt = seedDate,
                    CreatedAt = seedDate,
                    UpdatedAt = seedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new
                {
                    Id = Guid.Parse("DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDD007"),
                    UserId = Guid.Parse("BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBB07"),
                    RoleId = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                    AssignedAt = seedDate,
                    CreatedAt = seedDate,
                    UpdatedAt = seedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new
                {
                    Id = Guid.Parse("DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDD008"),
                    UserId = Guid.Parse("BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBB08"),
                    RoleId = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                    AssignedAt = seedDate,
                    CreatedAt = seedDate,
                    UpdatedAt = seedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new
                {
                    Id = Guid.Parse("DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDD009"),
                    UserId = Guid.Parse("BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBB09"),
                    RoleId = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                    AssignedAt = seedDate,
                    CreatedAt = seedDate,
                    UpdatedAt = seedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new
                {
                    Id = Guid.Parse("DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDD010"),
                    UserId = Guid.Parse("BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBB10"),
                    RoleId = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                    AssignedAt = seedDate,
                    CreatedAt = seedDate,
                    UpdatedAt = seedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new
                {
                    Id = Guid.Parse("DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDD011"),
                    UserId = Guid.Parse("BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBB11"),
                    RoleId = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                    AssignedAt = seedDate,
                    CreatedAt = seedDate,
                    UpdatedAt = seedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new
                {
                    Id = Guid.Parse("DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDD012"),
                    UserId = Guid.Parse("BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBB12"),
                    RoleId = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                    AssignedAt = seedDate,
                    CreatedAt = seedDate,
                    UpdatedAt = seedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new
                {
                    Id = Guid.Parse("DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDD013"),
                    UserId = Guid.Parse("BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBB13"),
                    RoleId = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                    AssignedAt = seedDate,
                    CreatedAt = seedDate,
                    UpdatedAt = seedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new
                {
                    Id = Guid.Parse("DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDD014"),
                    UserId = Guid.Parse("BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBB14"),
                    RoleId = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                    AssignedAt = seedDate,
                    CreatedAt = seedDate,
                    UpdatedAt = seedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new
                {
                    Id = Guid.Parse("DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDD015"),
                    UserId = Guid.Parse("BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBB15"),
                    RoleId = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                    AssignedAt = seedDate,
                    CreatedAt = seedDate,
                    UpdatedAt = seedDate,
                    IsActive = true,
                    IsDeleted = false
                }
            );
            
            // Seed property types with Arabic names
            var propertyTypeSeeder = new PropertyTypeSeeder();
            modelBuilder.Entity<PropertyType>().HasData(propertyTypeSeeder.SeedData());
            
            // Seed properties with Arabic names
            var propertySeeder = new PropertySeeder();
            modelBuilder.Entity<Property>().HasData(propertySeeder.SeedData());
            
            // Seed property policies in Arabic
            var policySeeder = new PropertyPolicySeeder();
            modelBuilder.Entity<PropertyPolicy>().HasData(policySeeder.SeedData());
        }
    }
} 