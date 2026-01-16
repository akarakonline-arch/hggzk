using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Seeds
{
    public class AmenitySeeder : ISeeder<Amenity>
    {
        private static readonly DateTime SeedDate = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc);

        public IEnumerable<Amenity> SeedData()
        {
            return new List<Amenity>
            {
                // مرافق الإنترنت والاتصالات
                new Amenity
                {
                    Id = Guid.Parse("50000000-0000-0000-0000-000000000001"),
                    Name = "Wi-Fi مجاني",
                    Description = "إنترنت لاسلكي مجاني",
                    Icon = "wifi",
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                
                // مرافق التكييف والتدفئة
                new Amenity
                {
                    Id = Guid.Parse("50000000-0000-0000-0000-000000000002"),
                    Name = "تكييف هواء",
                    Description = "مكيف هواء في جميع الغرف",
                    Icon = "snowflake",
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                
                // مرافق التلفزيون
                new Amenity
                {
                    Id = Guid.Parse("50000000-0000-0000-0000-000000000003"),
                    Name = "تلفزيون",
                    Description = "شاشة تلفزيون في الغرفة",
                    Icon = "tv",
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                
                // مرافق المطبخ
                new Amenity
                {
                    Id = Guid.Parse("50000000-0000-0000-0000-000000000004"),
                    Name = "مطبخ مجهز",
                    Description = "مطبخ كامل مع الأجهزة",
                    Icon = "kitchen-set",
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                
                // مرافق الغسيل
                new Amenity
                {
                    Id = Guid.Parse("50000000-0000-0000-0000-000000000005"),
                    Name = "غسالة ملابس",
                    Description = "غسالة ملابس متاحة",
                    Icon = "shirt",
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                
                // مرافق موقف السيارات
                new Amenity
                {
                    Id = Guid.Parse("50000000-0000-0000-0000-000000000006"),
                    Name = "موقف سيارات مجاني",
                    Description = "موقف سيارات مجاني في الموقع",
                    Icon = "car",
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                
                // مرافق المسبح
                new Amenity
                {
                    Id = Guid.Parse("50000000-0000-0000-0000-000000000007"),
                    Name = "مسبح",
                    Description = "مسبح خاص أو مشترك",
                    Icon = "water",
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                
                // مرافق الأمن
                new Amenity
                {
                    Id = Guid.Parse("50000000-0000-0000-0000-000000000008"),
                    Name = "حراسة أمنية",
                    Description = "حراسة أمنية على مدار 24 ساعة",
                    Icon = "shield",
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                
                // مرافق النظافة
                new Amenity
                {
                    Id = Guid.Parse("50000000-0000-0000-0000-000000000009"),
                    Name = "خدمة تنظيف يومية",
                    Description = "تنظيف يومي للغرف",
                    Icon = "broom",
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                
                // مرافق الإفطار
                new Amenity
                {
                    Id = Guid.Parse("50000000-0000-0000-0000-000000000010"),
                    Name = "إفطار مجاني",
                    Description = "وجبة إفطار مجانية",
                    Icon = "utensils",
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                
                // مرافق الحديقة
                new Amenity
                {
                    Id = Guid.Parse("50000000-0000-0000-0000-000000000011"),
                    Name = "حديقة",
                    Description = "حديقة خارجية",
                    Icon = "tree",
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                
                // مرافق الشواء
                new Amenity
                {
                    Id = Guid.Parse("50000000-0000-0000-0000-000000000012"),
                    Name = "منطقة شواء",
                    Description = "منطقة شواء خارجية",
                    Icon = "fire",
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                
                // مرافق الألعاب
                new Amenity
                {
                    Id = Guid.Parse("50000000-0000-0000-0000-000000000013"),
                    Name = "منطقة ألعاب أطفال",
                    Description = "منطقة ألعاب للأطفال",
                    Icon = "gamepad",
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                
                // مرافق الصالة الرياضية
                new Amenity
                {
                    Id = Guid.Parse("50000000-0000-0000-0000-000000000014"),
                    Name = "صالة رياضية",
                    Description = "صالة رياضية مجهزة",
                    Icon = "dumbbell",
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                
                // مرافق الإطلالة
                new Amenity
                {
                    Id = Guid.Parse("50000000-0000-0000-0000-000000000015"),
                    Name = "إطلالة بحرية",
                    Description = "إطلالة على البحر",
                    Icon = "water",
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                
                // مرافق الحمام
                new Amenity
                {
                    Id = Guid.Parse("50000000-0000-0000-0000-000000000016"),
                    Name = "حمام خاص",
                    Description = "حمام خاص في الغرفة",
                    Icon = "bath",
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                
                // مرافق الشرفة
                new Amenity
                {
                    Id = Guid.Parse("50000000-0000-0000-0000-000000000017"),
                    Name = "شرفة",
                    Description = "شرفة خاصة",
                    Icon = "door-open",
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                
                // مرافق المصعد
                new Amenity
                {
                    Id = Guid.Parse("50000000-0000-0000-0000-000000000018"),
                    Name = "مصعد",
                    Description = "مصعد كهربائي",
                    Icon = "arrow-up",
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                
                // مرافق ذوي الاحتياجات الخاصة
                new Amenity
                {
                    Id = Guid.Parse("50000000-0000-0000-0000-000000000019"),
                    Name = "مناسب لذوي الاحتياجات الخاصة",
                    Description = "مرافق مخصصة لذوي الاحتياجات الخاصة",
                    Icon = "wheelchair",
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                
                // مرافق الحيوانات
                new Amenity
                {
                    Id = Guid.Parse("50000000-0000-0000-0000-000000000020"),
                    Name = "يسمح بالحيوانات الأليفة",
                    Description = "مسموح إحضار الحيوانات الأليفة",
                    Icon = "paw",
                    CreatedAt = SeedDate,
                    UpdatedAt = SeedDate,
                    IsActive = true,
                    IsDeleted = false
                }
            };
        }
    }
}
