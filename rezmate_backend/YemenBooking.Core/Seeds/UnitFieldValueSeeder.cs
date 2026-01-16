using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Seeds
{
    public class UnitFieldValueSeeder : ISeeder<UnitFieldValue>
    {
        private static readonly DateTime SeedDate = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc);

        public IEnumerable<UnitFieldValue> SeedData()
        {
            var values = new List<UnitFieldValue>();

            // سيتم ملء القيم بواسطة DataSeedingService بعد إنشاء UnitTypeFields
            // لأننا نحتاج إلى UnitTypeFieldId الفعلي من قاعدة البيانات
            
            return values;
        }

        // هذه الدالة سيتم استدعاؤها من DataSeedingService بعد إنشاء UnitTypeFields
        public static List<UnitFieldValue> GenerateValuesForUnits(
            List<Unit> units,
            List<UnitTypeField> fields)
        {
            var values = new List<UnitFieldValue>();
            
            foreach (var unit in units)
            {
                var unitFields = fields.Where(f => f.UnitTypeId == unit.UnitTypeId).ToList();
                
                foreach (var field in unitFields)
                {
                    var value = GenerateValueForField(unit, field);
                    if (value != null)
                    {
                        values.Add(value);
                    }
                }
            }
            
            return values;
        }

        private static UnitFieldValue GenerateValueForField(Unit unit, UnitTypeField field)
        {
            string fieldValue = field.FieldName switch
            {
                // مساحات الغرف الفندقية
                "room_size" when unit.UnitTypeId == UnitTypeSeeder.HotelStandardRoomId => 
                    GetRandomNumber(20, 35).ToString(),
                "room_size" when unit.UnitTypeId == UnitTypeSeeder.HotelDeluxeRoomId => 
                    GetRandomNumber(35, 50).ToString(),
                "room_size" when unit.UnitTypeId == UnitTypeSeeder.HotelSuiteId => 
                    GetRandomNumber(60, 120).ToString(),
                
                // إطلالة بحرية للغرف الفندقية
                "sea_view" when unit.Name.Contains("بحر") || unit.Name.Contains("إطلالة") => "true",
                "sea_view" => GetRandomBoolean(30),
                
                // نوع السرير للغرف العادية
                "bed_type" => GetBedType(unit.MaxCapacity),
                
                // عدد الأسرة
                "beds_count" => Math.Min(unit.MaxCapacity, 3).ToString(),
                
                // شرفة للديلوكس
                "has_balcony" => GetRandomBoolean(70),
                
                // عدد غرف النوم للأجنحة
                "bedrooms_count" when unit.UnitTypeId == UnitTypeSeeder.HotelSuiteId =>
                    Math.Min((unit.MaxCapacity / 2) + 1, 3).ToString(),
                
                // صالة معيشة للأجنحة
                "has_living_room" => "true",
                
                // مساحات الشاليهات
                "chalet_size" when unit.UnitTypeId == UnitTypeSeeder.ChaletStandardId =>
                    GetRandomNumber(80, 150).ToString(),
                "chalet_size" when unit.UnitTypeId == UnitTypeSeeder.ChaletFamilyId =>
                    GetRandomNumber(180, 350).ToString(),
                
                // مسبح للشاليهات
                "has_pool" when unit.Name.Contains("مسبح") || unit.Name.Contains("VIP") => "true",
                "has_pool" when unit.UnitTypeId == UnitTypeSeeder.ChaletStandardId => GetRandomBoolean(40),
                "has_pool" when unit.UnitTypeId == UnitTypeSeeder.ChaletFamilyId => GetRandomBoolean(70),
                
                "has_garden" => GetRandomBoolean(80),
                
                // عدد غرف النوم للشاليهات العائلية
                "bedrooms_count" when unit.UnitTypeId == UnitTypeSeeder.ChaletFamilyId =>
                    Math.Min((unit.MaxCapacity / 2), 5).ToString(),
                
                // مساحات الاستراحات
                "rest_size" when unit.UnitTypeId == UnitTypeSeeder.RestStandardId =>
                    GetRandomNumber(150, 300).ToString(),
                "rest_size" when unit.UnitTypeId == UnitTypeSeeder.RestLargeId =>
                    GetRandomNumber(350, 600).ToString(),
                
                // منطقة شواء للاستراحات
                "has_bbq_area" => "true",
                
                // عدد غرف النوم للاستراحات الكبيرة
                "bedrooms_count" when unit.UnitTypeId == UnitTypeSeeder.RestLargeId =>
                    Math.Min((unit.MaxCapacity / 2) + 1, 6).ToString(),
                
                // مساحات الفيلات
                "villa_size" when unit.UnitTypeId == UnitTypeSeeder.VillaStandardId =>
                    GetRandomNumber(200, 400).ToString(),
                "villa_size" when unit.UnitTypeId == UnitTypeSeeder.VillaLuxuryId =>
                    GetRandomNumber(450, 800).ToString(),
                
                // عدد غرف النوم للفيلات
                "bedrooms_count" when unit.UnitTypeId == UnitTypeSeeder.VillaStandardId =>
                    Math.Min((unit.MaxCapacity / 2), 4).ToString(),
                "bedrooms_count" when unit.UnitTypeId == UnitTypeSeeder.VillaLuxuryId =>
                    Math.Min((unit.MaxCapacity / 2) + 1, 7).ToString(),
                
                // مسبح للفيلات
                "has_pool" when unit.UnitTypeId == UnitTypeSeeder.VillaStandardId => GetRandomBoolean(50),
                "has_pool" when unit.UnitTypeId == UnitTypeSeeder.VillaLuxuryId => "true",
                
                // مساحات الشقق
                "apartment_size" when unit.UnitTypeId == UnitTypeSeeder.ApartmentStudioId =>
                    GetRandomNumber(30, 50).ToString(),
                "apartment_size" when unit.UnitTypeId == UnitTypeSeeder.ApartmentOneBedroomId =>
                    GetRandomNumber(60, 90).ToString(),
                "apartment_size" when unit.UnitTypeId == UnitTypeSeeder.ApartmentTwoBedroomId =>
                    GetRandomNumber(100, 150).ToString(),
                                // حديقة للشاليهات

                // مطبخ للشقق
                "has_kitchen" when unit.UnitTypeId == UnitTypeSeeder.ApartmentStudioId => GetRandomBoolean(60),
                "has_kitchen" when unit.UnitTypeId == UnitTypeSeeder.ApartmentOneBedroomId => "true",
                "has_kitchen" when unit.UnitTypeId == UnitTypeSeeder.ApartmentTwoBedroomId => "true",
                
                // عدد دورات المياه للشقق
                "bathrooms_count" => Math.Min((unit.MaxCapacity / 2), 3).ToString(),
                
                _ => null
            };

            if (string.IsNullOrEmpty(fieldValue))
                return null;

            return new UnitFieldValue
            {
                Id = Guid.NewGuid(),
                UnitId = unit.Id,
                UnitTypeFieldId = field.Id,
                FieldValue = fieldValue,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            };
        }

        private static int GetRandomNumber(int min, int max)
        {
            var random = new Random(Guid.NewGuid().GetHashCode());
            return random.Next(min, max + 1);
        }

        private static string GetRandomBoolean(int truePercentage)
        {
            var random = new Random(Guid.NewGuid().GetHashCode());
            return (random.Next(100) < truePercentage) ? "true" : "false";
        }

        private static string GetBedType(int capacity)
        {
            if (capacity == 1)
                return "سرير مفرد";
            else if (capacity == 2)
                return new Random(Guid.NewGuid().GetHashCode()).Next(2) == 0 ? "سرير مزدوج" : "سريرين مفردين";
            else
                return "سريرين مفردين";
        }
    }
}
