using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Seeds
{
    /// <summary>
    /// Seeder لربط المرافق بأنواع العقار (PropertyTypeAmenity)
    /// </summary>
    public class PropertyTypeAmenitySeeder : ISeeder<PropertyTypeAmenity>
    {
        private static readonly DateTime SeedDate = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc);

        // معرفات أنواع العقار (من PropertyTypeSeeder)
        private static readonly Guid HotelTypeId = PropertyTypeSeeder.DefaultPropertyTypeId;
        private static readonly Guid ChaletTypeId = Guid.Parse("30000000-0000-0000-0000-000000000002");
        private static readonly Guid RestTypeId = Guid.Parse("30000000-0000-0000-0000-000000000003");
        private static readonly Guid VillaTypeId = Guid.Parse("30000000-0000-0000-0000-000000000004");
        private static readonly Guid ApartmentTypeId = Guid.Parse("30000000-0000-0000-0000-000000000005");

        // معرفات المرافق (من AmenitySeeder)
        private static readonly Guid WifiAmenityId = Guid.Parse("50000000-0000-0000-0000-000000000001");
        private static readonly Guid AcAmenityId = Guid.Parse("50000000-0000-0000-0000-000000000002");
        private static readonly Guid TvAmenityId = Guid.Parse("50000000-0000-0000-0000-000000000003");
        private static readonly Guid KitchenAmenityId = Guid.Parse("50000000-0000-0000-0000-000000000004");
        private static readonly Guid WasherAmenityId = Guid.Parse("50000000-0000-0000-0000-000000000005");
        private static readonly Guid ParkingAmenityId = Guid.Parse("50000000-0000-0000-0000-000000000006");
        private static readonly Guid PoolAmenityId = Guid.Parse("50000000-0000-0000-0000-000000000007");
        private static readonly Guid SecurityAmenityId = Guid.Parse("50000000-0000-0000-0000-000000000008");
        private static readonly Guid CleaningAmenityId = Guid.Parse("50000000-0000-0000-0000-000000000009");
        private static readonly Guid BreakfastAmenityId = Guid.Parse("50000000-0000-0000-0000-000000000010");
        private static readonly Guid GardenAmenityId = Guid.Parse("50000000-0000-0000-0000-000000000011");
        private static readonly Guid BbqAmenityId = Guid.Parse("50000000-0000-0000-0000-000000000012");
        private static readonly Guid KidsAreaAmenityId = Guid.Parse("50000000-0000-0000-0000-000000000013");
        private static readonly Guid GymAmenityId = Guid.Parse("50000000-0000-0000-0000-000000000014");
        private static readonly Guid SeaViewAmenityId = Guid.Parse("50000000-0000-0000-0000-000000000015");
        private static readonly Guid PrivateBathAmenityId = Guid.Parse("50000000-0000-0000-0000-000000000016");
        private static readonly Guid BalconyAmenityId = Guid.Parse("50000000-0000-0000-0000-000000000017");
        private static readonly Guid ElevatorAmenityId = Guid.Parse("50000000-0000-0000-0000-000000000018");
        private static readonly Guid AccessibleAmenityId = Guid.Parse("50000000-0000-0000-0000-000000000019");
        private static readonly Guid PetsAmenityId = Guid.Parse("50000000-0000-0000-0000-000000000020");

        public IEnumerable<PropertyTypeAmenity> SeedData()
        {
            // نستخدم نطاق GUID منفصل لروابط PropertyTypeAmenity
            var seedDate = SeedDate;

            return new List<PropertyTypeAmenity>
            {
                // فندق: مجموعة واسعة من المرافق الفندقية
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000001"), PropertyTypeId = HotelTypeId, AmenityId = WifiAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000002"), PropertyTypeId = HotelTypeId, AmenityId = AcAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000003"), PropertyTypeId = HotelTypeId, AmenityId = TvAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000004"), PropertyTypeId = HotelTypeId, AmenityId = BreakfastAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000005"), PropertyTypeId = HotelTypeId, AmenityId = SecurityAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000006"), PropertyTypeId = HotelTypeId, AmenityId = ElevatorAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000007"), PropertyTypeId = HotelTypeId, AmenityId = GymAmenityId, IsDefault = false, CreatedAt = seedDate, IsActive = true, IsDeleted = false },

                // شاليه: مسبح، شواء، حديقة، ألعاب أطفال، إطلالة بحرية لبعضها
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000010"), PropertyTypeId = ChaletTypeId, AmenityId = WifiAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000011"), PropertyTypeId = ChaletTypeId, AmenityId = AcAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000012"), PropertyTypeId = ChaletTypeId, AmenityId = TvAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000013"), PropertyTypeId = ChaletTypeId, AmenityId = PoolAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000014"), PropertyTypeId = ChaletTypeId, AmenityId = GardenAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000015"), PropertyTypeId = ChaletTypeId, AmenityId = BbqAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000016"), PropertyTypeId = ChaletTypeId, AmenityId = KidsAreaAmenityId, IsDefault = false, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000017"), PropertyTypeId = ChaletTypeId, AmenityId = SeaViewAmenityId, IsDefault = false, CreatedAt = seedDate, IsActive = true, IsDeleted = false },

                // استراحة: حديقة، شواء، منطقة ألعاب، مواقف سيارات
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000020"), PropertyTypeId = RestTypeId, AmenityId = WifiAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000021"), PropertyTypeId = RestTypeId, AmenityId = AcAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000022"), PropertyTypeId = RestTypeId, AmenityId = GardenAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000023"), PropertyTypeId = RestTypeId, AmenityId = BbqAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000024"), PropertyTypeId = RestTypeId, AmenityId = KidsAreaAmenityId, IsDefault = false, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000025"), PropertyTypeId = RestTypeId, AmenityId = ParkingAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },

                // فيلا: مطبخ، غسالة، مواقف، حديقة، حمام خاص، شرفة، مسبح اختياري
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000030"), PropertyTypeId = VillaTypeId, AmenityId = WifiAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000031"), PropertyTypeId = VillaTypeId, AmenityId = AcAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000032"), PropertyTypeId = VillaTypeId, AmenityId = TvAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000033"), PropertyTypeId = VillaTypeId, AmenityId = KitchenAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000034"), PropertyTypeId = VillaTypeId, AmenityId = WasherAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000035"), PropertyTypeId = VillaTypeId, AmenityId = ParkingAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000036"), PropertyTypeId = VillaTypeId, AmenityId = GardenAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000037"), PropertyTypeId = VillaTypeId, AmenityId = PrivateBathAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000038"), PropertyTypeId = VillaTypeId, AmenityId = BalconyAmenityId, IsDefault = false, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000039"), PropertyTypeId = VillaTypeId, AmenityId = PoolAmenityId, IsDefault = false, CreatedAt = seedDate, IsActive = true, IsDeleted = false },

                // شقة: واي فاي، تكييف، تلفزيون، مطبخ، غسالة، مصعد، حمام خاص، مواقف
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000040"), PropertyTypeId = ApartmentTypeId, AmenityId = WifiAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000041"), PropertyTypeId = ApartmentTypeId, AmenityId = AcAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000042"), PropertyTypeId = ApartmentTypeId, AmenityId = TvAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000043"), PropertyTypeId = ApartmentTypeId, AmenityId = KitchenAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000044"), PropertyTypeId = ApartmentTypeId, AmenityId = WasherAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000045"), PropertyTypeId = ApartmentTypeId, AmenityId = ElevatorAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000046"), PropertyTypeId = ApartmentTypeId, AmenityId = PrivateBathAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false },
                new PropertyTypeAmenity { Id = Guid.Parse("60000000-0000-0000-0000-000000000047"), PropertyTypeId = ApartmentTypeId, AmenityId = ParkingAmenityId, IsDefault = true, CreatedAt = seedDate, IsActive = true, IsDeleted = false }
            };
        }
    }
}
