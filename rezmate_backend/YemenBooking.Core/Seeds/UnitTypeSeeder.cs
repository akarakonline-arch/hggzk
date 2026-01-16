using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Seeds
{
    public class UnitTypeSeeder : ISeeder<UnitType>
    {
        private static readonly DateTime SeedDate = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc);

        public static readonly Guid HotelStandardRoomId = Guid.Parse("fe0d6c5d-eac9-4977-ae8f-bcd3d0ec6ace");
        public static readonly Guid HotelDeluxeRoomId = Guid.Parse("fe0d6c5d-eac9-4977-ae8f-bcd3d0ec6acf");
        public static readonly Guid HotelSuiteId = Guid.Parse("fe0d6c5d-eac9-4977-ae8f-bcd3d0ec6ad0");
        
        public static readonly Guid ChaletStandardId = Guid.Parse("fa565456-2069-4d63-a6ad-40dd7164cf31");
        public static readonly Guid ChaletFamilyId = Guid.Parse("fa565456-2069-4d63-a6ad-40dd7164cf32");
        
        public static readonly Guid RestStandardId = Guid.Parse("97f62c61-b241-40ee-ab75-b27f3e62d211");
        public static readonly Guid RestLargeId = Guid.Parse("97f62c61-b241-40ee-ab75-b27f3e62d212");
        
        public static readonly Guid VillaStandardId = Guid.Parse("5d145063-0007-4111-a0e4-288117d3b5cf");
        public static readonly Guid VillaLuxuryId = Guid.Parse("5d145063-0007-4111-a0e4-288117d3b5d0");
        
        public static readonly Guid ApartmentStudioId = Guid.Parse("8392c299-c0cd-4a6c-9de9-b19e72f77945");
        public static readonly Guid ApartmentOneBedroomId = Guid.Parse("8392c299-c0cd-4a6c-9de9-b19e72f77946");
        public static readonly Guid ApartmentTwoBedroomId = Guid.Parse("8392c299-c0cd-4a6c-9de9-b19e72f77947");

        public IEnumerable<UnitType> SeedData()
        {
            return new List<UnitType>
            {
                new UnitType
                {
                    Id = HotelStandardRoomId,
                    PropertyTypeId = PropertyTypeSeeder.DefaultPropertyTypeId,
                    Name = "غرفة عادية",
                    Description = "غرفة فندقية عادية",
                    DefaultPricingRules = "[]",
                    MaxCapacity = 2,
                    Icon = "bed",
                    IsHasAdults = true,
                    IsHasChildren = true,
                    IsMultiDays = true,
                    IsRequiredToDetermineTheHour = false,
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new UnitType
                {
                    Id = HotelDeluxeRoomId,
                    PropertyTypeId = PropertyTypeSeeder.DefaultPropertyTypeId,
                    Name = "غرفة ديلوكس",
                    Description = "غرفة فندقية ديلوكس",
                    DefaultPricingRules = "[]",
                    MaxCapacity = 3,
                    Icon = "bed-double",
                    IsHasAdults = true,
                    IsHasChildren = true,
                    IsMultiDays = true,
                    IsRequiredToDetermineTheHour = false,
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new UnitType
                {
                    Id = HotelSuiteId,
                    PropertyTypeId = PropertyTypeSeeder.DefaultPropertyTypeId,
                    Name = "جناح",
                    Description = "جناح فندقي فاخر",
                    DefaultPricingRules = "[]",
                    MaxCapacity = 4,
                    Icon = "hotel",
                    IsHasAdults = true,
                    IsHasChildren = true,
                    IsMultiDays = true,
                    IsRequiredToDetermineTheHour = false,
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new UnitType
                {
                    Id = ChaletStandardId,
                    PropertyTypeId = Guid.Parse("30000000-0000-0000-0000-000000000002"),
                    Name = "شاليه عادي",
                    Description = "شاليه عائلي عادي",
                    DefaultPricingRules = "[]",
                    MaxCapacity = 4,
                    Icon = "home",
                    IsHasAdults = true,
                    IsHasChildren = true,
                    IsMultiDays = true,
                    IsRequiredToDetermineTheHour = false,
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new UnitType
                {
                    Id = ChaletFamilyId,
                    PropertyTypeId = Guid.Parse("30000000-0000-0000-0000-000000000002"),
                    Name = "شاليه عائلي كبير",
                    Description = "شاليه عائلي كبير",
                    DefaultPricingRules = "[]",
                    MaxCapacity = 8,
                    Icon = "home-heart",
                    IsHasAdults = true,
                    IsHasChildren = true,
                    IsMultiDays = true,
                    IsRequiredToDetermineTheHour = false,
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new UnitType
                {
                    Id = RestStandardId,
                    PropertyTypeId = Guid.Parse("30000000-0000-0000-0000-000000000003"),
                    Name = "استراحة عادية",
                    Description = "استراحة عائلية عادية",
                    DefaultPricingRules = "[]",
                    MaxCapacity = 6,
                    Icon = "home-modern",
                    IsHasAdults = true,
                    IsHasChildren = true,
                    IsMultiDays = true,
                    IsRequiredToDetermineTheHour = false,
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new UnitType
                {
                    Id = RestLargeId,
                    PropertyTypeId = Guid.Parse("30000000-0000-0000-0000-000000000003"),
                    Name = "استراحة كبيرة",
                    Description = "استراحة عائلية كبيرة",
                    DefaultPricingRules = "[]",
                    MaxCapacity = 10,
                    Icon = "home-group",
                    IsHasAdults = true,
                    IsHasChildren = true,
                    IsMultiDays = true,
                    IsRequiredToDetermineTheHour = false,
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new UnitType
                {
                    Id = VillaStandardId,
                    PropertyTypeId = Guid.Parse("30000000-0000-0000-0000-000000000004"),
                    Name = "فيلا عادية",
                    Description = "فيلا عائلية عادية",
                    DefaultPricingRules = "[]",
                    MaxCapacity = 6,
                    Icon = "building",
                    IsHasAdults = true,
                    IsHasChildren = true,
                    IsMultiDays = true,
                    IsRequiredToDetermineTheHour = false,
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new UnitType
                {
                    Id = VillaLuxuryId,
                    PropertyTypeId = Guid.Parse("30000000-0000-0000-0000-000000000004"),
                    Name = "فيلا فاخرة",
                    Description = "فيلا فاخرة",
                    DefaultPricingRules = "[]",
                    MaxCapacity = 10,
                    Icon = "building-columns",
                    IsHasAdults = true,
                    IsHasChildren = true,
                    IsMultiDays = true,
                    IsRequiredToDetermineTheHour = false,
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new UnitType
                {
                    Id = ApartmentStudioId,
                    PropertyTypeId = Guid.Parse("30000000-0000-0000-0000-000000000005"),
                    Name = "استوديو",
                    Description = "شقة استوديو",
                    DefaultPricingRules = "[]",
                    MaxCapacity = 2,
                    Icon = "door-closed",
                    IsHasAdults = true,
                    IsHasChildren = false,
                    IsMultiDays = true,
                    IsRequiredToDetermineTheHour = false,
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new UnitType
                {
                    Id = ApartmentOneBedroomId,
                    PropertyTypeId = Guid.Parse("30000000-0000-0000-0000-000000000005"),
                    Name = "شقة غرفة نوم واحدة",
                    Description = "شقة بغرفة نوم واحدة",
                    DefaultPricingRules = "[]",
                    MaxCapacity = 3,
                    Icon = "door-open",
                    IsHasAdults = true,
                    IsHasChildren = true,
                    IsMultiDays = true,
                    IsRequiredToDetermineTheHour = false,
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new UnitType
                {
                    Id = ApartmentTwoBedroomId,
                    PropertyTypeId = Guid.Parse("30000000-0000-0000-0000-000000000005"),
                    Name = "شقة غرفتي نوم",
                    Description = "شقة بغرفتي نوم",
                    DefaultPricingRules = "[]",
                    MaxCapacity = 5,
                    Icon = "building-user",
                    IsHasAdults = true,
                    IsHasChildren = true,
                    IsMultiDays = true,
                    IsRequiredToDetermineTheHour = false,
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                }
            };
        }
    }
}
