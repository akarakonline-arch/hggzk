using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Seeds
{
    public class UnitTypeFieldSeeder : ISeeder<UnitTypeField>
    {
        private static readonly DateTime SeedDate = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc);

        public IEnumerable<UnitTypeField> SeedData()
        {
            var fields = new List<UnitTypeField>();

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // حقول نوع الفندق (Hotel)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            
            // حقل رقمي: مساحة الغرفة
            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000001"),
                UnitTypeId = UnitTypeSeeder.HotelStandardRoomId,
                Description = "مساحة الغرفة بالمتر المربع", FieldOptions = "", FieldName = "room_size",
                DisplayName = "مساحة الغرفة (م²)",
                FieldTypeId = "number",
                IsRequired = true,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{\"min\": 15, \"max\": 100}",
                Category = "basic",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            // حقل منطقي: إطلالة بحرية
            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000002"),
                UnitTypeId = UnitTypeSeeder.HotelStandardRoomId,
                Description = "هل الغرفة لها إطلالة على البحر", FieldOptions = "", FieldName = "sea_view",
                DisplayName = "إطلالة بحرية",
                FieldTypeId = "boolean",
                IsRequired = false,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{}",
                Category = "features",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            // حقل نصي: نوع السرير
            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000003"),
                UnitTypeId = UnitTypeSeeder.HotelStandardRoomId,
                Description = "نوع السرير المتوفر", FieldOptions = "", FieldName = "bed_type",
                DisplayName = "نوع السرير",
                FieldTypeId = "select",
                IsRequired = true,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{\"options\": [\"سرير مفرد\", \"سرير مزدوج\", \"سريرين مفردين\"]}",
                Category = "basic",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            // حقل رقمي: عدد الأسرة
            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000004"),
                UnitTypeId = UnitTypeSeeder.HotelStandardRoomId,
                Description = "عدد الأسرة في الغرفة", FieldOptions = "", FieldName = "beds_count",
                DisplayName = "عدد الأسرة",
                FieldTypeId = "number",
                IsRequired = true,
                IsPrimaryFilter = false,
                IsSearchable = false,
                ValidationRules = "{\"min\": 1, \"max\": 4}",
                Category = "basic",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            // نفس الحقول لغرفة ديلوكس
            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000005"),
                UnitTypeId = UnitTypeSeeder.HotelDeluxeRoomId,
                Description = "مساحة الغرفة بالمتر المربع", FieldOptions = "", FieldName = "room_size",
                DisplayName = "مساحة الغرفة (م²)",
                FieldTypeId = "number",
                IsRequired = true,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{\"min\": 25, \"max\": 150}",
                Category = "basic",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000006"),
                UnitTypeId = UnitTypeSeeder.HotelDeluxeRoomId,
                Description = "هل الغرفة لها إطلالة على البحر", FieldOptions = "", FieldName = "sea_view",
                DisplayName = "إطلالة بحرية",
                FieldTypeId = "boolean",
                IsRequired = false,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{}",
                Category = "features",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000007"),
                UnitTypeId = UnitTypeSeeder.HotelDeluxeRoomId,
                Description = "حقل إضافي", FieldOptions = "", FieldName = "has_balcony",
                DisplayName = "يحتوي على شرفة",
                FieldTypeId = "boolean",
                IsRequired = false,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{}",
                Category = "features",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            // حقول الجناح
            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000008"),
                UnitTypeId = UnitTypeSeeder.HotelSuiteId,
                Description = "مساحة الغرفة بالمتر المربع", FieldOptions = "", FieldName = "room_size",
                DisplayName = "مساحة الجناح (م²)",
                FieldTypeId = "number",
                IsRequired = true,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{\"min\": 50, \"max\": 300}",
                Category = "basic",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000009"),
                UnitTypeId = UnitTypeSeeder.HotelSuiteId,
                Description = "عدد غرف النوم", FieldOptions = "", FieldName = "bedrooms_count",
                DisplayName = "عدد غرف النوم",
                FieldTypeId = "number",
                IsRequired = true,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{\"min\": 1, \"max\": 5}",
                Category = "basic",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000010"),
                UnitTypeId = UnitTypeSeeder.HotelSuiteId,
                Description = "حقل إضافي", FieldOptions = "", FieldName = "has_living_room",
                DisplayName = "يحتوي على صالة معيشة",
                FieldTypeId = "boolean",
                IsRequired = false,
                IsPrimaryFilter = false,
                IsSearchable = false,
                ValidationRules = "{}",
                Category = "features",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // حقول نوع الشاليه (Chalet)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            
            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000011"),
                UnitTypeId = UnitTypeSeeder.ChaletStandardId,
                Description = "حقل إضافي", FieldOptions = "", FieldName = "chalet_size",
                DisplayName = "مساحة الشاليه (م²)",
                FieldTypeId = "number",
                IsRequired = true,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{\"min\": 60, \"max\": 300}",
                Category = "basic",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000012"),
                UnitTypeId = UnitTypeSeeder.ChaletStandardId,
                Description = "حقل إضافي", FieldOptions = "", FieldName = "has_pool",
                DisplayName = "يحتوي على مسبح خاص",
                FieldTypeId = "boolean",
                IsRequired = false,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{}",
                Category = "amenities",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000013"),
                UnitTypeId = UnitTypeSeeder.ChaletStandardId,
                Description = "حقل إضافي", FieldOptions = "", FieldName = "has_garden",
                DisplayName = "يحتوي على حديقة",
                FieldTypeId = "boolean",
                IsRequired = false,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{}",
                Category = "amenities",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000014"),
                UnitTypeId = UnitTypeSeeder.ChaletFamilyId,
                Description = "حقل إضافي", FieldOptions = "", FieldName = "chalet_size",
                DisplayName = "مساحة الشاليه (م²)",
                FieldTypeId = "number",
                IsRequired = true,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{\"min\": 150, \"max\": 500}",
                Category = "basic",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000015"),
                UnitTypeId = UnitTypeSeeder.ChaletFamilyId,
                Description = "حقل إضافي", FieldOptions = "", FieldName = "has_pool",
                DisplayName = "يحتوي على مسبح خاص",
                FieldTypeId = "boolean",
                IsRequired = false,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{}",
                Category = "amenities",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000016"),
                UnitTypeId = UnitTypeSeeder.ChaletFamilyId,
                Description = "عدد غرف النوم", FieldOptions = "", FieldName = "bedrooms_count",
                DisplayName = "عدد غرف النوم",
                FieldTypeId = "number",
                IsRequired = true,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{\"min\": 2, \"max\": 8}",
                Category = "basic",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // حقول نوع الاستراحة (Rest)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            
            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000017"),
                UnitTypeId = UnitTypeSeeder.RestStandardId,
                Description = "حقل إضافي", FieldOptions = "", FieldName = "rest_size",
                DisplayName = "مساحة الاستراحة (م²)",
                FieldTypeId = "number",
                IsRequired = true,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{\"min\": 100, \"max\": 400}",
                Category = "basic",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000018"),
                UnitTypeId = UnitTypeSeeder.RestStandardId,
                Description = "حقل إضافي", FieldOptions = "", FieldName = "has_bbq_area",
                DisplayName = "منطقة شواء",
                FieldTypeId = "boolean",
                IsRequired = false,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{}",
                Category = "amenities",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000019"),
                UnitTypeId = UnitTypeSeeder.RestLargeId,
                Description = "حقل إضافي", FieldOptions = "", FieldName = "rest_size",
                DisplayName = "مساحة الاستراحة (م²)",
                FieldTypeId = "number",
                IsRequired = true,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{\"min\": 200, \"max\": 800}",
                Category = "basic",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000020"),
                UnitTypeId = UnitTypeSeeder.RestLargeId,
                Description = "عدد غرف النوم", FieldOptions = "", FieldName = "bedrooms_count",
                DisplayName = "عدد غرف النوم",
                FieldTypeId = "number",
                IsRequired = true,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{\"min\": 3, \"max\": 10}",
                Category = "basic",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // حقول نوع الفيلا (Villa)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            
            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000021"),
                UnitTypeId = UnitTypeSeeder.VillaStandardId,
                Description = "حقل إضافي", FieldOptions = "", FieldName = "villa_size",
                DisplayName = "مساحة الفيلا (م²)",
                FieldTypeId = "number",
                IsRequired = true,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{\"min\": 150, \"max\": 600}",
                Category = "basic",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000022"),
                UnitTypeId = UnitTypeSeeder.VillaStandardId,
                Description = "عدد غرف النوم", FieldOptions = "", FieldName = "bedrooms_count",
                DisplayName = "عدد غرف النوم",
                FieldTypeId = "number",
                IsRequired = true,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{\"min\": 2, \"max\": 6}",
                Category = "basic",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000023"),
                UnitTypeId = UnitTypeSeeder.VillaStandardId,
                Description = "حقل إضافي", FieldOptions = "", FieldName = "has_pool",
                DisplayName = "يحتوي على مسبح خاص",
                FieldTypeId = "boolean",
                IsRequired = false,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{}",
                Category = "amenities",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000024"),
                UnitTypeId = UnitTypeSeeder.VillaLuxuryId,
                Description = "حقل إضافي", FieldOptions = "", FieldName = "villa_size",
                DisplayName = "مساحة الفيلا (م²)",
                FieldTypeId = "number",
                IsRequired = true,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{\"min\": 300, \"max\": 1200}",
                Category = "basic",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000025"),
                UnitTypeId = UnitTypeSeeder.VillaLuxuryId,
                Description = "عدد غرف النوم", FieldOptions = "", FieldName = "bedrooms_count",
                DisplayName = "عدد غرف النوم",
                FieldTypeId = "number",
                IsRequired = true,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{\"min\": 4, \"max\": 12}",
                Category = "basic",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000026"),
                UnitTypeId = UnitTypeSeeder.VillaLuxuryId,
                Description = "حقل إضافي", FieldOptions = "", FieldName = "has_pool",
                DisplayName = "يحتوي على مسبح خاص",
                FieldTypeId = "boolean",
                IsRequired = true,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{}",
                Category = "amenities",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // حقول نوع الشقة (Apartment)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            
            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000027"),
                UnitTypeId = UnitTypeSeeder.ApartmentStudioId,
                Description = "حقل إضافي", FieldOptions = "", FieldName = "apartment_size",
                DisplayName = "مساحة الاستوديو (م²)",
                FieldTypeId = "number",
                IsRequired = true,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{\"min\": 25, \"max\": 60}",
                Category = "basic",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000028"),
                UnitTypeId = UnitTypeSeeder.ApartmentStudioId,
                Description = "حقل إضافي", FieldOptions = "", FieldName = "has_kitchen",
                DisplayName = "يحتوي على مطبخ",
                FieldTypeId = "boolean",
                IsRequired = false,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{}",
                Category = "amenities",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000029"),
                UnitTypeId = UnitTypeSeeder.ApartmentOneBedroomId,
                Description = "حقل إضافي", FieldOptions = "", FieldName = "apartment_size",
                DisplayName = "مساحة الشقة (م²)",
                FieldTypeId = "number",
                IsRequired = true,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{\"min\": 50, \"max\": 120}",
                Category = "basic",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000030"),
                UnitTypeId = UnitTypeSeeder.ApartmentOneBedroomId,
                Description = "حقل إضافي", FieldOptions = "", FieldName = "has_kitchen",
                DisplayName = "يحتوي على مطبخ كامل",
                FieldTypeId = "boolean",
                IsRequired = true,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{}",
                Category = "amenities",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000031"),
                UnitTypeId = UnitTypeSeeder.ApartmentTwoBedroomId,
                Description = "حقل إضافي", FieldOptions = "", FieldName = "apartment_size",
                DisplayName = "مساحة الشقة (م²)",
                FieldTypeId = "number",
                IsRequired = true,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{\"min\": 80, \"max\": 200}",
                Category = "basic",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000032"),
                UnitTypeId = UnitTypeSeeder.ApartmentTwoBedroomId,
                Description = "حقل إضافي", FieldOptions = "", FieldName = "has_kitchen",
                DisplayName = "يحتوي على مطبخ كامل",
                FieldTypeId = "boolean",
                IsRequired = true,
                IsPrimaryFilter = true,
                IsSearchable = false,
                ValidationRules = "{}",
                Category = "amenities",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            fields.Add(new UnitTypeField
            {
                Id = Guid.Parse("40000000-0000-0000-0000-000000000033"),
                UnitTypeId = UnitTypeSeeder.ApartmentTwoBedroomId,
                Description = "عدد الحمامات", FieldOptions = "", FieldName = "bathrooms_count",
                DisplayName = "عدد دورات المياه",
                FieldTypeId = "number",
                IsRequired = true,
                IsPrimaryFilter = false,
                IsSearchable = false,
                ValidationRules = "{\"min\": 1, \"max\": 4}",
                Category = "basic",
                // DisplayOrder removed,
                CreatedAt = SeedDate,
                UpdatedAt = SeedDate,
                IsActive = true,
                IsDeleted = false
            });

            return fields;
        }
    }
}
