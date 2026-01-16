using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;

namespace YemenBooking.Core.Seeds
{
    public class UnitSeeder : ISeeder<Unit>
    {
        private static readonly DateTime SeedDate = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc);

        public IEnumerable<Unit> SeedData()
        {
            var units = new List<Unit>();

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // فندق الزهراء - صنعاء (3 وحدات فندقية)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000001"),
                PropertyId = PropertySeeder.Property1Id,
                UnitTypeId = UnitTypeSeeder.HotelStandardRoomId,
                Name = "غرفة عادية 101",
                MaxCapacity = 2,
                AdultsCapacity = 2,
                ChildrenCapacity = 1,
                CustomFeatures = "[]",
                ViewCount = 85,
                BookingCount = 34,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 0,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000002"),
                PropertyId = PropertySeeder.Property1Id,
                UnitTypeId = UnitTypeSeeder.HotelDeluxeRoomId,
                Name = "غرفة ديلوكس 201",
                MaxCapacity = 3,
                AdultsCapacity = 2,
                ChildrenCapacity = 1,
                CustomFeatures = "[]",
                ViewCount = 120,
                BookingCount = 48,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 10,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000003"),
                PropertyId = PropertySeeder.Property1Id,
                UnitTypeId = UnitTypeSeeder.HotelSuiteId,
                Name = "جناح 301",
                MaxCapacity = 4,
                AdultsCapacity = 3,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 95,
                BookingCount = 28,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 15,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // منتجع البحر - عدن (4 وحدات فندقية)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000004"),
                PropertyId = PropertySeeder.Property2Id,
                UnitTypeId = UnitTypeSeeder.HotelStandardRoomId,
                Name = "غرفة إطلالة بحرية 102",
                MaxCapacity = 2,
                AdultsCapacity = 2,
                ChildrenCapacity = 1,
                CustomFeatures = "[]",
                ViewCount = 145,
                BookingCount = 67,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 0,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000005"),
                PropertyId = PropertySeeder.Property2Id,
                UnitTypeId = UnitTypeSeeder.HotelDeluxeRoomId,
                Name = "غرفة ديلوكس بإطلالة 202",
                MaxCapacity = 3,
                AdultsCapacity = 2,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 178,
                BookingCount = 82,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 5,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000006"),
                PropertyId = PropertySeeder.Property2Id,
                UnitTypeId = UnitTypeSeeder.HotelSuiteId,
                Name = "جناح بريميوم 302",
                MaxCapacity = 4,
                AdultsCapacity = 3,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 210,
                BookingCount = 95,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 10,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000007"),
                PropertyId = PropertySeeder.Property2Id,
                UnitTypeId = UnitTypeSeeder.HotelSuiteId,
                Name = "جناح رويال 401",
                MaxCapacity = 4,
                AdultsCapacity = 3,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 189,
                BookingCount = 73,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 20,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // شقق النخيل - تعز (3 شقق)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000008"),
                PropertyId = PropertySeeder.Property3Id,
                UnitTypeId = UnitTypeSeeder.ApartmentStudioId,
                Name = "استوديو A1",
                MaxCapacity = 2,
                AdultsCapacity = 2,
                ChildrenCapacity = 0,
                CustomFeatures = "[]",
                ViewCount = 67,
                BookingCount = 23,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 0,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000009"),
                PropertyId = PropertySeeder.Property3Id,
                UnitTypeId = UnitTypeSeeder.ApartmentOneBedroomId,
                Name = "شقة غرفة واحدة B2",
                MaxCapacity = 3,
                AdultsCapacity = 2,
                ChildrenCapacity = 1,
                CustomFeatures = "[]",
                ViewCount = 92,
                BookingCount = 38,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 5,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000010"),
                PropertyId = PropertySeeder.Property3Id,
                UnitTypeId = UnitTypeSeeder.ApartmentTwoBedroomId,
                Name = "شقة غرفتين C3",
                MaxCapacity = 5,
                AdultsCapacity = 3,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 115,
                BookingCount = 47,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 10,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // فيلا الياسمين - صنعاء (2 فيلات)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000011"),
                PropertyId = PropertySeeder.Property4Id,
                UnitTypeId = UnitTypeSeeder.VillaStandardId,
                Name = "فيلا عائلية",
                MaxCapacity = 6,
                AdultsCapacity = 4,
                ChildrenCapacity = 3,
                CustomFeatures = "[]",
                ViewCount = 78,
                BookingCount = 19,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 0,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000012"),
                PropertyId = PropertySeeder.Property4Id,
                UnitTypeId = UnitTypeSeeder.VillaLuxuryId,
                Name = "فيلا فاخرة بمسبح",
                MaxCapacity = 10,
                AdultsCapacity = 6,
                ChildrenCapacity = 4,
                CustomFeatures = "[]",
                ViewCount = 156,
                BookingCount = 31,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 15,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // استراحة الجبل - صنعاء (2 استراحات)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000013"),
                PropertyId = PropertySeeder.Property5Id,
                UnitTypeId = UnitTypeSeeder.RestStandardId,
                Name = "استراحة الوادي",
                MaxCapacity = 6,
                AdultsCapacity = 4,
                ChildrenCapacity = 3,
                CustomFeatures = "[]",
                ViewCount = 89,
                BookingCount = 34,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 0,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000014"),
                PropertyId = PropertySeeder.Property5Id,
                UnitTypeId = UnitTypeSeeder.RestLargeId,
                Name = "استراحة الجبل الكبيرة",
                MaxCapacity = 10,
                AdultsCapacity = 6,
                ChildrenCapacity = 5,
                CustomFeatures = "[]",
                ViewCount = 112,
                BookingCount = 42,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 10,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // فندق المرجان - عدن (3 وحدات فندقية)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000015"),
                PropertyId = PropertySeeder.Property6Id,
                UnitTypeId = UnitTypeSeeder.HotelStandardRoomId,
                Name = "غرفة اقتصادية 103",
                MaxCapacity = 2,
                AdultsCapacity = 2,
                ChildrenCapacity = 0,
                CustomFeatures = "[]",
                ViewCount = 198,
                BookingCount = 89,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 0,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000016"),
                PropertyId = PropertySeeder.Property6Id,
                UnitTypeId = UnitTypeSeeder.HotelDeluxeRoomId,
                Name = "غرفة ديلوكس 203",
                MaxCapacity = 3,
                AdultsCapacity = 2,
                ChildrenCapacity = 1,
                CustomFeatures = "[]",
                ViewCount = 167,
                BookingCount = 73,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 5,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000017"),
                PropertyId = PropertySeeder.Property6Id,
                UnitTypeId = UnitTypeSeeder.HotelSuiteId,
                Name = "جناح 303",
                MaxCapacity = 4,
                AdultsCapacity = 3,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 145,
                BookingCount = 61,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 10,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // منتجع الوادي السياحي - تعز (5 وحدات فندقية)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000018"),
                PropertyId = PropertySeeder.Property7Id,
                UnitTypeId = UnitTypeSeeder.HotelStandardRoomId,
                Name = "غرفة عادية 104",
                MaxCapacity = 2,
                AdultsCapacity = 2,
                ChildrenCapacity = 1,
                CustomFeatures = "[]",
                ViewCount = 234,
                BookingCount = 98,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 0,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000019"),
                PropertyId = PropertySeeder.Property7Id,
                UnitTypeId = UnitTypeSeeder.HotelDeluxeRoomId,
                Name = "غرفة ديلوكس بإطلالة جبلية 204",
                MaxCapacity = 3,
                AdultsCapacity = 2,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 267,
                BookingCount = 112,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 5,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000020"),
                PropertyId = PropertySeeder.Property7Id,
                UnitTypeId = UnitTypeSeeder.HotelSuiteId,
                Name = "جناح الوادي 304",
                MaxCapacity = 4,
                AdultsCapacity = 3,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 289,
                BookingCount = 123,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 10,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000021"),
                PropertyId = PropertySeeder.Property7Id,
                UnitTypeId = UnitTypeSeeder.HotelSuiteId,
                Name = "جناح بريميوم 404",
                MaxCapacity = 4,
                AdultsCapacity = 3,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 312,
                BookingCount = 134,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 15,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000022"),
                PropertyId = PropertySeeder.Property7Id,
                UnitTypeId = UnitTypeSeeder.HotelSuiteId,
                Name = "جناح رويال 504",
                MaxCapacity = 4,
                AdultsCapacity = 3,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 278,
                BookingCount = 117,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 20,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // شقق السعيد المفروشة - صنعاء (4 شقق)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000023"),
                PropertyId = PropertySeeder.Property8Id,
                UnitTypeId = UnitTypeSeeder.ApartmentStudioId,
                Name = "استوديو D1",
                MaxCapacity = 2,
                AdultsCapacity = 2,
                ChildrenCapacity = 0,
                CustomFeatures = "[]",
                ViewCount = 98,
                BookingCount = 45,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 0,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000024"),
                PropertyId = PropertySeeder.Property8Id,
                UnitTypeId = UnitTypeSeeder.ApartmentOneBedroomId,
                Name = "شقة غرفة واحدة E2",
                MaxCapacity = 3,
                AdultsCapacity = 2,
                ChildrenCapacity = 1,
                CustomFeatures = "[]",
                ViewCount = 124,
                BookingCount = 58,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 5,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000025"),
                PropertyId = PropertySeeder.Property8Id,
                UnitTypeId = UnitTypeSeeder.ApartmentTwoBedroomId,
                Name = "شقة غرفتين F3",
                MaxCapacity = 5,
                AdultsCapacity = 3,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 156,
                BookingCount = 71,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 10,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000026"),
                PropertyId = PropertySeeder.Property8Id,
                UnitTypeId = UnitTypeSeeder.ApartmentTwoBedroomId,
                Name = "شقة عائلية G4",
                MaxCapacity = 5,
                AdultsCapacity = 3,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 142,
                BookingCount = 65,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 8,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // فيلا البحر الأحمر - عدن (3 شاليهات)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000027"),
                PropertyId = PropertySeeder.Property9Id,
                UnitTypeId = UnitTypeSeeder.ChaletStandardId,
                Name = "شاليه بحري A",
                MaxCapacity = 4,
                AdultsCapacity = 3,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 289,
                BookingCount = 56,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 0,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000028"),
                PropertyId = PropertySeeder.Property9Id,
                UnitTypeId = UnitTypeSeeder.ChaletFamilyId,
                Name = "شاليه عائلي كبير B",
                MaxCapacity = 8,
                AdultsCapacity = 5,
                ChildrenCapacity = 3,
                CustomFeatures = "[]",
                ViewCount = 356,
                BookingCount = 67,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 10,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000029"),
                PropertyId = PropertySeeder.Property9Id,
                UnitTypeId = UnitTypeSeeder.ChaletFamilyId,
                Name = "شاليه VIP بمسبح",
                MaxCapacity = 8,
                AdultsCapacity = 5,
                ChildrenCapacity = 3,
                CustomFeatures = "[]",
                ViewCount = 412,
                BookingCount = 78,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 15,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // بيت الضيافة التراثي - صنعاء (3 وحدات فندقية)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000030"),
                PropertyId = PropertySeeder.Property10Id,
                UnitTypeId = UnitTypeSeeder.HotelStandardRoomId,
                Name = "غرفة تراثية 105",
                MaxCapacity = 2,
                AdultsCapacity = 2,
                ChildrenCapacity = 1,
                CustomFeatures = "[]",
                ViewCount = 234,
                BookingCount = 98,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 0,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000031"),
                PropertyId = PropertySeeder.Property10Id,
                UnitTypeId = UnitTypeSeeder.HotelDeluxeRoomId,
                Name = "غرفة تراثية ديلوكس 205",
                MaxCapacity = 3,
                AdultsCapacity = 2,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 267,
                BookingCount = 112,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 5,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000032"),
                PropertyId = PropertySeeder.Property10Id,
                UnitTypeId = UnitTypeSeeder.HotelSuiteId,
                Name = "جناح تراثي 305",
                MaxCapacity = 4,
                AdultsCapacity = 3,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 289,
                BookingCount = 123,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 10,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // استوديوهات النهضة - تعز (4 شقق استوديو)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000033"),
                PropertyId = PropertySeeder.Property11Id,
                UnitTypeId = UnitTypeSeeder.ApartmentStudioId,
                Name = "استوديو H1",
                MaxCapacity = 2,
                AdultsCapacity = 2,
                ChildrenCapacity = 0,
                CustomFeatures = "[]",
                ViewCount = 78,
                BookingCount = 34,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 0,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000034"),
                PropertyId = PropertySeeder.Property11Id,
                UnitTypeId = UnitTypeSeeder.ApartmentStudioId,
                Name = "استوديو I2",
                MaxCapacity = 2,
                AdultsCapacity = 2,
                ChildrenCapacity = 0,
                CustomFeatures = "[]",
                ViewCount = 82,
                BookingCount = 37,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 0,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000035"),
                PropertyId = PropertySeeder.Property11Id,
                UnitTypeId = UnitTypeSeeder.ApartmentOneBedroomId,
                Name = "شقة غرفة واحدة J3",
                MaxCapacity = 3,
                AdultsCapacity = 2,
                ChildrenCapacity = 1,
                CustomFeatures = "[]",
                ViewCount = 95,
                BookingCount = 42,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 5,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000036"),
                PropertyId = PropertySeeder.Property11Id,
                UnitTypeId = UnitTypeSeeder.ApartmentTwoBedroomId,
                Name = "شقة غرفتين K4",
                MaxCapacity = 5,
                AdultsCapacity = 3,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 112,
                BookingCount = 51,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 10,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // فندق القصر الذهبي - عدن (5 وحدات فندقية)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000037"),
                PropertyId = PropertySeeder.Property12Id,
                UnitTypeId = UnitTypeSeeder.HotelStandardRoomId,
                Name = "غرفة قياسية 106",
                MaxCapacity = 2,
                AdultsCapacity = 2,
                ChildrenCapacity = 1,
                CustomFeatures = "[]",
                ViewCount = 312,
                BookingCount = 145,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 0,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000038"),
                PropertyId = PropertySeeder.Property12Id,
                UnitTypeId = UnitTypeSeeder.HotelDeluxeRoomId,
                Name = "غرفة ديلوكس 206",
                MaxCapacity = 3,
                AdultsCapacity = 2,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 378,
                BookingCount = 167,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 5,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000039"),
                PropertyId = PropertySeeder.Property12Id,
                UnitTypeId = UnitTypeSeeder.HotelSuiteId,
                Name = "جناح فاخر 306",
                MaxCapacity = 4,
                AdultsCapacity = 3,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 423,
                BookingCount = 189,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 10,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000040"),
                PropertyId = PropertySeeder.Property12Id,
                UnitTypeId = UnitTypeSeeder.HotelSuiteId,
                Name = "جناح رويال 406",
                MaxCapacity = 4,
                AdultsCapacity = 3,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 456,
                BookingCount = 201,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 15,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000041"),
                PropertyId = PropertySeeder.Property12Id,
                UnitTypeId = UnitTypeSeeder.HotelSuiteId,
                Name = "جناح بريزيدنتال 506",
                MaxCapacity = 4,
                AdultsCapacity = 3,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 489,
                BookingCount = 213,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 20,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // شاليهات الريف - صنعاء (3 شاليهات)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000042"),
                PropertyId = PropertySeeder.Property13Id,
                UnitTypeId = UnitTypeSeeder.ChaletStandardId,
                Name = "شاليه الريف C",
                MaxCapacity = 4,
                AdultsCapacity = 3,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 145,
                BookingCount = 67,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 0,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000043"),
                PropertyId = PropertySeeder.Property13Id,
                UnitTypeId = UnitTypeSeeder.ChaletFamilyId,
                Name = "شاليه عائلي D",
                MaxCapacity = 8,
                AdultsCapacity = 5,
                ChildrenCapacity = 3,
                CustomFeatures = "[]",
                ViewCount = 178,
                BookingCount = 82,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 10,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000044"),
                PropertyId = PropertySeeder.Property13Id,
                UnitTypeId = UnitTypeSeeder.ChaletFamilyId,
                Name = "شاليه كبير E",
                MaxCapacity = 8,
                AdultsCapacity = 5,
                ChildrenCapacity = 3,
                CustomFeatures = "[]",
                ViewCount = 156,
                BookingCount = 73,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 8,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // أجنحة الأندلس - تعز (5 شقق)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000045"),
                PropertyId = PropertySeeder.Property14Id,
                UnitTypeId = UnitTypeSeeder.ApartmentStudioId,
                Name = "استوديو L1",
                MaxCapacity = 2,
                AdultsCapacity = 2,
                ChildrenCapacity = 0,
                CustomFeatures = "[]",
                ViewCount = 123,
                BookingCount = 56,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 0,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000046"),
                PropertyId = PropertySeeder.Property14Id,
                UnitTypeId = UnitTypeSeeder.ApartmentOneBedroomId,
                Name = "شقة غرفة واحدة M2",
                MaxCapacity = 3,
                AdultsCapacity = 2,
                ChildrenCapacity = 1,
                CustomFeatures = "[]",
                ViewCount = 156,
                BookingCount = 71,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 5,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000047"),
                PropertyId = PropertySeeder.Property14Id,
                UnitTypeId = UnitTypeSeeder.ApartmentTwoBedroomId,
                Name = "شقة غرفتين N3",
                MaxCapacity = 5,
                AdultsCapacity = 3,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 189,
                BookingCount = 87,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 10,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000048"),
                PropertyId = PropertySeeder.Property14Id,
                UnitTypeId = UnitTypeSeeder.ApartmentTwoBedroomId,
                Name = "شقة عائلية O4",
                MaxCapacity = 5,
                AdultsCapacity = 3,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 167,
                BookingCount = 78,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 8,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000049"),
                PropertyId = PropertySeeder.Property14Id,
                UnitTypeId = UnitTypeSeeder.ApartmentTwoBedroomId,
                Name = "شقة فاخرة P5",
                MaxCapacity = 5,
                AdultsCapacity = 3,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 201,
                BookingCount = 93,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 12,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // منتجع السياحة الساحلي - عدن (3 شاليهات)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000050"),
                PropertyId = PropertySeeder.Property15Id,
                UnitTypeId = UnitTypeSeeder.ChaletStandardId,
                Name = "شاليه بحري F",
                MaxCapacity = 4,
                AdultsCapacity = 3,
                ChildrenCapacity = 2,
                CustomFeatures = "[]",
                ViewCount = 423,
                BookingCount = 156,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 0,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000051"),
                PropertyId = PropertySeeder.Property15Id,
                UnitTypeId = UnitTypeSeeder.ChaletFamilyId,
                Name = "شاليه عائلي بمسبح G",
                MaxCapacity = 8,
                AdultsCapacity = 5,
                ChildrenCapacity = 3,
                CustomFeatures = "[]",
                ViewCount = 512,
                BookingCount = 189,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 10,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            units.Add(new Unit
            {
                Id = Guid.Parse("20000000-0000-0000-0000-000000000052"),
                PropertyId = PropertySeeder.Property15Id,
                UnitTypeId = UnitTypeSeeder.ChaletFamilyId,
                Name = "شاليه VIP بإطلالة بحرية H",
                MaxCapacity = 8,
                AdultsCapacity = 5,
                ChildrenCapacity = 3,
                CustomFeatures = "[]",
                ViewCount = 589,
                BookingCount = 217,
                PricingMethod = PricingMethod.Daily,
                DiscountPercentage = 15,
                IsActive = true,
                IsDeleted = false,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate
            });

            return units;
        }
    }
}
