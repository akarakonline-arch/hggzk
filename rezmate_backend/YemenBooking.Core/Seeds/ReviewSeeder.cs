using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Seeds
{
    /// <summary>
    /// مولد البيانات الأولية للمراجعات
    /// Review seeder for initial data
    /// </summary>
    public class ReviewSeeder : ISeeder<Review>
    {
        // معرفات الحجوزات المكتملة (من BookingSeeder)
        private static readonly Guid Booking1Id = Guid.Parse("B0000000-0000-0000-0000-000000000001");
        private static readonly Guid Booking2Id = Guid.Parse("B0000000-0000-0000-0000-000000000002");
        private static readonly Guid Booking3Id = Guid.Parse("B0000000-0000-0000-0000-000000000003");
        private static readonly Guid Booking4Id = Guid.Parse("B0000000-0000-0000-0000-000000000004");
        private static readonly Guid Booking5Id = Guid.Parse("B0000000-0000-0000-0000-000000000005");
        private static readonly Guid Booking6Id = Guid.Parse("B0000000-0000-0000-0000-000000000006");
        private static readonly Guid Booking7Id = Guid.Parse("B0000000-0000-0000-0000-000000000007");
        private static readonly Guid Booking8Id = Guid.Parse("B0000000-0000-0000-0000-000000000008");
        private static readonly Guid Booking9Id = Guid.Parse("B0000000-0000-0000-0000-000000000009");
        private static readonly Guid Booking10Id = Guid.Parse("B0000000-0000-0000-0000-000000000010");

        // ═══════════════════════════════════════════════════════════════════════
        // معرفات العقارات مُحسَّنة بناءً على الـ Unit المستخدم في الحجز
        // Booking → Unit → Property mapping:
        // B1 → Unit001 → Property1
        // B2 → Unit004 → Property2  
        // B3 → Unit008 → Property3
        // B4 → Unit003 → Property1
        // B5 → Unit005 → Property2
        // B6 → Unit002 → Property1
        // B7 → Unit006 → Property2
        // B8 → Unit007 → Property2
        // B9 → Unit009 → Property3
        // B10 → Unit001 → Property1
        // ═══════════════════════════════════════════════════════════════════════
        private static readonly Guid Property1Id = Guid.Parse("10000000-0000-0000-0000-000000000001");
        private static readonly Guid Property2Id = Guid.Parse("10000000-0000-0000-0000-000000000002");
        private static readonly Guid Property3Id = Guid.Parse("10000000-0000-0000-0000-000000000003");

        private static readonly DateTime BaseDate = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc);

        public IEnumerable<Review> SeedData()
        {
            return new List<Review>
            {
                // مراجعة 1: فندق الزهراء - تقييم ممتاز (B1 → Unit001 → Property1)
                new Review
                {
                    Id = Guid.Parse("70000000-0000-0000-0000-000000000001"),
                    BookingId = Booking1Id,
                    PropertyId = Property1Id, // Unit001 → Property1 ✅
                    Cleanliness = 5,
                    Service = 5,
                    Location = 4,
                    Value = 4,
                    AverageRating = 4.5m,
                    Comment = "فندق رائع في موقع ممتاز. الخدمة احترافية والنظافة ممتازة. أنصح بشدة بالإقامة هنا.",
                    CreatedAt = BaseDate.AddDays(-40),
                    IsPendingApproval = false,
                    IsDisabled = false
                },

                // مراجعة 2: منتجع البحر - تقييم ممتاز جداً (B2 → Unit004 → Property2)
                new Review
                {
                    Id = Guid.Parse("70000000-0000-0000-0000-000000000002"),
                    BookingId = Booking2Id,
                    PropertyId = Property2Id, // Unit004 → Property2 ✅
                    Cleanliness = 5,
                    Service = 5,
                    Location = 5,
                    Value = 5,
                    AverageRating = 5.0m,
                    Comment = "منتجع رائع جداً! الإطلالة البحرية خيالية والمرافق عالية الجودة. تجربة لا تنسى.",
                    CreatedAt = BaseDate.AddDays(-32),
                    IsPendingApproval = false,
                    IsDisabled = false
                },

                // مراجعة 3: شقق النخيل - تقييم جيد (B3 → Unit008 → Property3)
                new Review
                {
                    Id = Guid.Parse("70000000-0000-0000-0000-000000000003"),
                    BookingId = Booking3Id,
                    PropertyId = Property3Id, // Unit008 → Property3 ✅
                    Cleanliness = 4,
                    Service = 4,
                    Location = 3,
                    Value = 4,
                    AverageRating = 3.75m,
                    Comment = "شقق نظيفة ومريحة. الموقع مقبول. القيمة جيدة مقابل السعر.",
                    CreatedAt = BaseDate.AddDays(-33),
                    IsPendingApproval = false,
                    IsDisabled = false
                },

                // مراجعة 4: فندق الزهراء - جناح (B4 → Unit003 → Property1)
                new Review
                {
                    Id = Guid.Parse("70000000-0000-0000-0000-000000000004"),
                    BookingId = Booking4Id,
                    PropertyId = Property1Id, // Unit003 → Property1 ✅ (كان Property4 خطأ)
                    Cleanliness = 5,
                    Service = 5,
                    Location = 5,
                    Value = 4,
                    AverageRating = 4.75m,
                    Comment = "جناح فاخر ونظيف جداً. مثالي للعائلات. الخدمة ممتازة والموقع رائع.",
                    CreatedAt = BaseDate.AddDays(-26),
                    IsPendingApproval = false,
                    IsDisabled = false
                },

                // مراجعة 5: منتجع البحر - غرفة ديلوكس (B5 → Unit005 → Property2)
                new Review
                {
                    Id = Guid.Parse("70000000-0000-0000-0000-000000000005"),
                    BookingId = Booking5Id,
                    PropertyId = Property2Id, // Unit005 → Property2 ✅ (كان Property5 خطأ)
                    Cleanliness = 4,
                    Service = 4,
                    Location = 5,
                    Value = 4,
                    AverageRating = 4.25m,
                    Comment = "غرفة ديلوكس رائعة بإطلالة بحرية. الموقع ممتاز للاسترخاء. النظافة جيدة والخدمة ممتازة.",
                    CreatedAt = BaseDate.AddDays(-13),
                    IsPendingApproval = false,
                    IsDisabled = false
                },

                // مراجعة 6: فندق الزهراء - غرفة ديلوكس (B6 → Unit002 → Property1)
                new Review
                {
                    Id = Guid.Parse("70000000-0000-0000-0000-000000000006"),
                    BookingId = Booking6Id,
                    PropertyId = Property1Id, // Unit002 → Property1 ✅ (كان Property6 خطأ)
                    Cleanliness = 4,
                    Service = 3,
                    Location = 4,
                    Value = 4,
                    AverageRating = 3.75m,
                    Comment = "غرفة ديلوكس جيدة. الموقع ممتاز. النظافة مقبولة والسعر معقول.",
                    CreatedAt = BaseDate.AddDays(-10),
                    IsPendingApproval = false,
                    IsDisabled = false
                },

                // مراجعة 7: منتجع البحر - جناح بريميوم (B7 → Unit006 → Property2)
                new Review
                {
                    Id = Guid.Parse("70000000-0000-0000-0000-000000000007"),
                    BookingId = Booking7Id,
                    PropertyId = Property2Id, // Unit006 → Property2 ✅ (كان Property7 خطأ)
                    Cleanliness = 5,
                    Service = 5,
                    Location = 5,
                    Value = 4,
                    AverageRating = 4.75m,
                    Comment = "جناح بريميوم رائع مع إطلالة خلابة. الخدمة والنظافة ممتازة. أنصح به للعائلات.",
                    CreatedAt = BaseDate.AddDays(-8),
                    IsPendingApproval = false,
                    IsDisabled = false
                },

                // مراجعة 8: منتجع البحر - جناح رويال (B8 → Unit007 → Property2)
                new Review
                {
                    Id = Guid.Parse("70000000-0000-0000-0000-000000000008"),
                    BookingId = Booking8Id,
                    PropertyId = Property2Id, // Unit007 → Property2 ✅ (كان Property8 خطأ)
                    Cleanliness = 4,
                    Service = 4,
                    Location = 4,
                    Value = 4,
                    AverageRating = 4.0m,
                    Comment = "جناح رويال حديث ونظيف. مناسب للإقامات الفاخرة. الخدمة جيدة والموقع ممتاز.",
                    CreatedAt = BaseDate.AddDays(-5),
                    IsPendingApproval = false,
                    IsDisabled = false
                },

                // مراجعة 9: شقق النخيل - شقة غرفة واحدة (B9 → Unit009 → Property3)
                new Review
                {
                    Id = Guid.Parse("70000000-0000-0000-0000-000000000009"),
                    BookingId = Booking9Id,
                    PropertyId = Property3Id, // Unit009 → Property3 ✅ (كان Property9 خطأ)
                    Cleanliness = 5,
                    Service = 5,
                    Location = 5,
                    Value = 5,
                    AverageRating = 5.0m,
                    Comment = "شقة رائعة جداً ونظيفة. الخدمات ممتازة. تجربة استثنائية!",
                    CreatedAt = BaseDate.AddDays(-2),
                    IsPendingApproval = false,
                    IsDisabled = false
                },

                // مراجعة 10: فندق الزهراء - غرفة عادية (B10 → Unit001 → Property1)
                new Review
                {
                    Id = Guid.Parse("70000000-0000-0000-0000-000000000010"),
                    BookingId = Booking10Id,
                    PropertyId = Property1Id, // Unit001 → Property1 ✅ (كان Property10 خطأ)
                    Cleanliness = 5,
                    Service = 4,
                    Location = 5,
                    Value = 4,
                    AverageRating = 4.5m,
                    Comment = "غرفة عادية جيدة جداً. تجربة مريحة. النظافة والموقع ممتازين.",
                    CreatedAt = BaseDate.AddDays(-1),
                    IsPendingApproval = false,
                    IsDisabled = false
                }
            };
        }
    }
}
