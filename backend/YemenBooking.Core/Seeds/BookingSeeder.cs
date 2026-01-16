using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.ValueObjects;

namespace YemenBooking.Core.Seeds
{
    /// <summary>
    /// بيانات أولية يدوية للحجوزات - 40 حجز بسيناريوهات واقعية متنوعة
    /// Manual seed data for bookings - 40 bookings with realistic scenarios
    /// </summary>
    public class BookingSeeder : ISeeder<Booking>
    {
        // معرفات المستخدمين
        private static readonly Guid AdminUserId = Guid.Parse("AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA");
        // Removed single owner user id in favor of multiple owners (owner01..owner15)
        
        // معرفات إضافية لمستخدمين افتراضيين (سيتم إنشاؤهم في UserSeeder)
        private static readonly Guid User1Id = Guid.Parse("C0000000-0000-0000-0000-000000000001");
        private static readonly Guid User2Id = Guid.Parse("C0000000-0000-0000-0000-000000000002");
        private static readonly Guid User3Id = Guid.Parse("C0000000-0000-0000-0000-000000000003");
        private static readonly Guid User4Id = Guid.Parse("C0000000-0000-0000-0000-000000000004");
        private static readonly Guid User5Id = Guid.Parse("C0000000-0000-0000-0000-000000000005");

    // Use a stable date so migrations/seeding are deterministic and PostgreSQL-safe
    private static readonly DateTime BaseDate = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc);

        public IEnumerable<Booking> SeedData()
        {
            var bookings = new List<Booking>();

            // ═══════════════════════════════════════════════════════════════════════
            // القسم 1: حجوزات مكتملة (Completed) - 15 حجزاً
            // ═══════════════════════════════════════════════════════════════════════

            // 1. حجز مكتمل - فندق الزهراء - غرفة عادية
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000001"),
                UserId = User1Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000001"), // غرفة عادية 101
                CheckIn = BaseDate.AddDays(-45),
                CheckOut = BaseDate.AddDays(-42),
                ActualCheckInDate = BaseDate.AddDays(-45).AddHours(14),
                ActualCheckOutDate = BaseDate.AddDays(-42).AddHours(11),
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 90000m, Currency = "YER" },
                Status = BookingStatus.Completed,
                BookedAt = BaseDate.AddDays(-50),
                PlatformCommissionAmount = 9000m,
                FinalAmount = 90000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-50),
                UpdatedAt = BaseDate.AddDays(-42),
                IsActive = true,
                IsDeleted = false
            });

            // 2. حجز مكتمل - منتجع البحر - غرفة إطلالة بحرية
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000002"),
                UserId = User2Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000004"),
                CheckIn = BaseDate.AddDays(-40),
                CheckOut = BaseDate.AddDays(-35),
                ActualCheckInDate = BaseDate.AddDays(-40).AddHours(15),
                ActualCheckOutDate = BaseDate.AddDays(-35).AddHours(10),
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 500000m, Currency = "YER" },
                Status = BookingStatus.Completed,
                BookedAt = BaseDate.AddDays(-48),
                PlatformCommissionAmount = 50000m,
                FinalAmount = 500000m,
                BookingSource = "MobileApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-48),
                UpdatedAt = BaseDate.AddDays(-35),
                IsActive = true,
                IsDeleted = false
            });

            // 3. حجز مكتمل - شقق النخيل - شقة غرفة نوم واحدة
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000003"),
                UserId = User3Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000008"),
                CheckIn = BaseDate.AddDays(-38),
                CheckOut = BaseDate.AddDays(-36),
                ActualCheckInDate = BaseDate.AddDays(-38).AddHours(13),
                ActualCheckOutDate = BaseDate.AddDays(-36).AddHours(12),
                GuestsCount = 3,
                TotalPrice = new Money { Amount = 120000m, Currency = "YER" },
                Status = BookingStatus.Completed,
                BookedAt = BaseDate.AddDays(-42),
                PlatformCommissionAmount = 12000m,
                FinalAmount = 120000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-42),
                UpdatedAt = BaseDate.AddDays(-36),
                IsActive = true,
                IsDeleted = false
            });

            // 4. حجز مكتمل - فندق الزهراء - جناح
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000004"),
                UserId = User4Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000003"), // جناح 301
                CheckIn = BaseDate.AddDays(-35),
                CheckOut = BaseDate.AddDays(-32),
                ActualCheckInDate = BaseDate.AddDays(-35).AddHours(14),
                ActualCheckOutDate = BaseDate.AddDays(-32).AddHours(11),
                GuestsCount = 4,
                TotalPrice = new Money { Amount = 135000m, Currency = "YER" },
                Status = BookingStatus.Completed,
                BookedAt = BaseDate.AddDays(-40),
                PlatformCommissionAmount = 13500m,
                FinalAmount = 135000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-40),
                UpdatedAt = BaseDate.AddDays(-32),
                IsActive = true,
                IsDeleted = false
            });

            // 5. حجز مكتمل - منتجع البحر - غرفة ديلوكس
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000005"),
                UserId = User5Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000005"),
                CheckIn = BaseDate.AddDays(-33),
                CheckOut = BaseDate.AddDays(-30),
                ActualCheckInDate = BaseDate.AddDays(-33).AddHours(15),
                ActualCheckOutDate = BaseDate.AddDays(-30).AddHours(10),
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 360000m, Currency = "YER" },
                Status = BookingStatus.Completed,
                BookedAt = BaseDate.AddDays(-38),
                PlatformCommissionAmount = 36000m,
                FinalAmount = 360000m,
                BookingSource = "MobileApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-38),
                UpdatedAt = BaseDate.AddDays(-30),
                IsActive = true,
                IsDeleted = false
            });

            // 6-15: حجوزات مكتملة إضافية
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000006"),
                UserId = User1Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000002"), // غرفة ديلوكس 201
                CheckIn = BaseDate.AddDays(-30),
                CheckOut = BaseDate.AddDays(-28),
                ActualCheckInDate = BaseDate.AddDays(-30).AddHours(14),
                ActualCheckOutDate = BaseDate.AddDays(-28).AddHours(11),
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 108000m, Currency = "YER" },
                Status = BookingStatus.Completed,
                BookedAt = BaseDate.AddDays(-35),
                PlatformCommissionAmount = 10800m,
                FinalAmount = 108000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-35),
                UpdatedAt = BaseDate.AddDays(-28),
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000007"),
                UserId = User2Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000006"),
                CheckIn = BaseDate.AddDays(-28),
                CheckOut = BaseDate.AddDays(-25),
                ActualCheckInDate = BaseDate.AddDays(-28).AddHours(15),
                ActualCheckOutDate = BaseDate.AddDays(-25).AddHours(11),
                GuestsCount = 3,
                TotalPrice = new Money { Amount = 450000m, Currency = "YER" },
                Status = BookingStatus.Completed,
                BookedAt = BaseDate.AddDays(-32),
                PlatformCommissionAmount = 45000m,
                FinalAmount = 450000m,
                BookingSource = "MobileApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-32),
                UpdatedAt = BaseDate.AddDays(-25),
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000008"),
                UserId = User3Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000007"),
                CheckIn = BaseDate.AddDays(-26),
                CheckOut = BaseDate.AddDays(-23),
                ActualCheckInDate = BaseDate.AddDays(-26).AddHours(14),
                ActualCheckOutDate = BaseDate.AddDays(-23).AddHours(12),
                GuestsCount = 4,
                TotalPrice = new Money { Amount = 540000m, Currency = "YER" },
                Status = BookingStatus.Completed,
                BookedAt = BaseDate.AddDays(-30),
                PlatformCommissionAmount = 54000m,
                FinalAmount = 540000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-30),
                UpdatedAt = BaseDate.AddDays(-23),
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000009"),
                UserId = User4Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000009"),
                CheckIn = BaseDate.AddDays(-24),
                CheckOut = BaseDate.AddDays(-22),
                ActualCheckInDate = BaseDate.AddDays(-24).AddHours(13),
                ActualCheckOutDate = BaseDate.AddDays(-22).AddHours(11),
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 100000m, Currency = "YER" },
                Status = BookingStatus.Completed,
                BookedAt = BaseDate.AddDays(-28),
                PlatformCommissionAmount = 10000m,
                FinalAmount = 100000m,
                BookingSource = "MobileApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-28),
                UpdatedAt = BaseDate.AddDays(-22),
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000010"),
                UserId = User5Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000001"),
                CheckIn = BaseDate.AddDays(-22),
                CheckOut = BaseDate.AddDays(-19),
                ActualCheckInDate = BaseDate.AddDays(-22).AddHours(14),
                ActualCheckOutDate = BaseDate.AddDays(-19).AddHours(11),
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 90000m, Currency = "YER" },
                Status = BookingStatus.Completed,
                BookedAt = BaseDate.AddDays(-26),
                PlatformCommissionAmount = 9000m,
                FinalAmount = 90000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-26),
                UpdatedAt = BaseDate.AddDays(-19),
                IsActive = true,
                IsDeleted = false
            });

            // 11-15: مزيد من الحجوزات المكتملة
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000011"),
                UserId = User1Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000004"),
                CheckIn = BaseDate.AddDays(-20),
                CheckOut = BaseDate.AddDays(-17),
                ActualCheckInDate = BaseDate.AddDays(-20).AddHours(15),
                ActualCheckOutDate = BaseDate.AddDays(-17).AddHours(10),
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 300000m, Currency = "YER" },
                Status = BookingStatus.Completed,
                BookedAt = BaseDate.AddDays(-24),
                PlatformCommissionAmount = 30000m,
                FinalAmount = 300000m,
                BookingSource = "MobileApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-24),
                UpdatedAt = BaseDate.AddDays(-17),
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000012"),
                UserId = User2Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000008"),
                CheckIn = BaseDate.AddDays(-18),
                CheckOut = BaseDate.AddDays(-16),
                ActualCheckInDate = BaseDate.AddDays(-18).AddHours(13),
                ActualCheckOutDate = BaseDate.AddDays(-16).AddHours(12),
                GuestsCount = 3,
                TotalPrice = new Money { Amount = 120000m, Currency = "YER" },
                Status = BookingStatus.Completed,
                BookedAt = BaseDate.AddDays(-22),
                PlatformCommissionAmount = 12000m,
                FinalAmount = 120000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-22),
                UpdatedAt = BaseDate.AddDays(-16),
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000013"),
                UserId = User3Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000002"),
                CheckIn = BaseDate.AddDays(-16),
                CheckOut = BaseDate.AddDays(-14),
                ActualCheckInDate = BaseDate.AddDays(-16).AddHours(14),
                ActualCheckOutDate = BaseDate.AddDays(-14).AddHours(11),
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 108000m, Currency = "YER" },
                Status = BookingStatus.Completed,
                BookedAt = BaseDate.AddDays(-20),
                PlatformCommissionAmount = 10800m,
                FinalAmount = 108000m,
                BookingSource = "MobileApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-20),
                UpdatedAt = BaseDate.AddDays(-14),
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000014"),
                UserId = User4Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000005"),
                CheckIn = BaseDate.AddDays(-14),
                CheckOut = BaseDate.AddDays(-11),
                ActualCheckInDate = BaseDate.AddDays(-14).AddHours(15),
                ActualCheckOutDate = BaseDate.AddDays(-11).AddHours(10),
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 360000m, Currency = "YER" },
                Status = BookingStatus.Completed,
                BookedAt = BaseDate.AddDays(-18),
                PlatformCommissionAmount = 36000m,
                FinalAmount = 360000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-18),
                UpdatedAt = BaseDate.AddDays(-11),
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000015"),
                UserId = User5Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000003"),
                CheckIn = BaseDate.AddDays(-12),
                CheckOut = BaseDate.AddDays(-9),
                ActualCheckInDate = BaseDate.AddDays(-12).AddHours(14),
                ActualCheckOutDate = BaseDate.AddDays(-9).AddHours(11),
                GuestsCount = 4,
                TotalPrice = new Money { Amount = 135000m, Currency = "YER" },
                Status = BookingStatus.Completed,
                BookedAt = BaseDate.AddDays(-16),
                PlatformCommissionAmount = 13500m,
                FinalAmount = 135000m,
                BookingSource = "MobileApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-16),
                UpdatedAt = BaseDate.AddDays(-9),
                IsActive = true,
                IsDeleted = false
            });

            // ═══════════════════════════════════════════════════════════════════════
            // القسم 2: حجوزات قيد التنفيذ (CheckedIn) - 7 حجوزات
            // ═══════════════════════════════════════════════════════════════════════

            // 16. حجز قيد التنفيذ - فندق الزهراء
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000016"),
                UserId = User1Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000001"),
                CheckIn = BaseDate.AddDays(-2),
                CheckOut = BaseDate.AddDays(2),
                ActualCheckInDate = BaseDate.AddDays(-2).AddHours(14),
                ActualCheckOutDate = null,
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 120000m, Currency = "YER" },
                Status = BookingStatus.CheckedIn,
                BookedAt = BaseDate.AddDays(-10),
                PlatformCommissionAmount = 12000m,
                FinalAmount = 120000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-10),
                UpdatedAt = BaseDate.AddDays(-2),
                IsActive = true,
                IsDeleted = false
            });

            // 17. حجز قيد التنفيذ - منتجع البحر
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000017"),
                UserId = User2Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000004"),
                CheckIn = BaseDate.AddDays(-1),
                CheckOut = BaseDate.AddDays(3),
                ActualCheckInDate = BaseDate.AddDays(-1).AddHours(15),
                ActualCheckOutDate = null,
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 400000m, Currency = "YER" },
                Status = BookingStatus.CheckedIn,
                BookedAt = BaseDate.AddDays(-8),
                PlatformCommissionAmount = 40000m,
                FinalAmount = 400000m,
                BookingSource = "MobileApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-8),
                UpdatedAt = BaseDate.AddDays(-1),
                IsActive = true,
                IsDeleted = false
            });

            // 18-22: مزيد من الحجوزات قيد التنفيذ
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000018"),
                UserId = User3Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000008"),
                CheckIn = BaseDate.AddDays(-1),
                CheckOut = BaseDate.AddDays(1),
                ActualCheckInDate = BaseDate.AddDays(-1).AddHours(13),
                ActualCheckOutDate = null,
                GuestsCount = 3,
                TotalPrice = new Money { Amount = 120000m, Currency = "YER" },
                Status = BookingStatus.CheckedIn,
                BookedAt = BaseDate.AddDays(-6),
                PlatformCommissionAmount = 12000m,
                FinalAmount = 120000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-6),
                UpdatedAt = BaseDate.AddDays(-1),
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000019"),
                UserId = User4Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000002"),
                CheckIn = BaseDate,
                CheckOut = BaseDate.AddDays(2),
                ActualCheckInDate = BaseDate.AddHours(14),
                ActualCheckOutDate = null,
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 108000m, Currency = "YER" },
                Status = BookingStatus.CheckedIn,
                BookedAt = BaseDate.AddDays(-5),
                PlatformCommissionAmount = 10800m,
                FinalAmount = 108000m,
                BookingSource = "MobileApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-5),
                UpdatedAt = BaseDate,
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000020"),
                UserId = User5Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000005"),
                CheckIn = BaseDate,
                CheckOut = BaseDate.AddDays(4),
                ActualCheckInDate = BaseDate.AddHours(15),
                ActualCheckOutDate = null,
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 480000m, Currency = "YER" },
                Status = BookingStatus.CheckedIn,
                BookedAt = BaseDate.AddDays(-7),
                PlatformCommissionAmount = 48000m,
                FinalAmount = 480000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-7),
                UpdatedAt = BaseDate,
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000021"),
                UserId = User1Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000007"),
                CheckIn = BaseDate.AddDays(-1),
                CheckOut = BaseDate.AddDays(2),
                ActualCheckInDate = BaseDate.AddDays(-1).AddHours(14),
                ActualCheckOutDate = null,
                GuestsCount = 4,
                TotalPrice = new Money { Amount = 540000m, Currency = "YER" },
                Status = BookingStatus.CheckedIn,
                BookedAt = BaseDate.AddDays(-9),
                PlatformCommissionAmount = 54000m,
                FinalAmount = 540000m,
                BookingSource = "MobileApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-9),
                UpdatedAt = BaseDate.AddDays(-1),
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000022"),
                UserId = User2Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000009"),
                CheckIn = BaseDate.AddDays(-2),
                CheckOut = BaseDate.AddDays(1),
                ActualCheckInDate = BaseDate.AddDays(-2).AddHours(13),
                ActualCheckOutDate = null,
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 150000m, Currency = "YER" },
                Status = BookingStatus.CheckedIn,
                BookedAt = BaseDate.AddDays(-8),
                PlatformCommissionAmount = 15000m,
                FinalAmount = 150000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-8),
                UpdatedAt = BaseDate.AddDays(-2),
                IsActive = true,
                IsDeleted = false
            });

            // ═══════════════════════════════════════════════════════════════════════
            // القسم 3: حجوزات ملغاة (Cancelled) مع مردودات - 8 حجوزات
            // ═══════════════════════════════════════════════════════════════════════

            // 23. حجز ملغى - استرداد كامل
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000023"),
                UserId = User3Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000001"),
                CheckIn = BaseDate.AddDays(15),
                CheckOut = BaseDate.AddDays(18),
                ActualCheckInDate = null,
                ActualCheckOutDate = null,
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 90000m, Currency = "YER" },
                Status = BookingStatus.Cancelled,
                BookedAt = BaseDate.AddDays(-5),
                CancellationReason = "طلب العميل - ظروف طارئة",
                PlatformCommissionAmount = 9000m,
                FinalAmount = 90000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-5),
                UpdatedAt = BaseDate.AddDays(-2),
                IsActive = true,
                IsDeleted = false
            });

            // 24. حجز ملغى - استرداد جزئي (50%)
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000024"),
                UserId = User4Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000004"),
                CheckIn = BaseDate.AddDays(10),
                CheckOut = BaseDate.AddDays(14),
                ActualCheckInDate = null,
                ActualCheckOutDate = null,
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 400000m, Currency = "YER" },
                Status = BookingStatus.Cancelled,
                BookedAt = BaseDate.AddDays(-12),
                CancellationReason = "تغيير خطط السفر",
                PlatformCommissionAmount = 40000m,
                FinalAmount = 400000m,
                BookingSource = "MobileApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-12),
                UpdatedAt = BaseDate.AddDays(-3),
                IsActive = true,
                IsDeleted = false
            });

            // 25-30: مزيد من الحجوزات الملغاة
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000025"),
                UserId = User5Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000008"),
                CheckIn = BaseDate.AddDays(20),
                CheckOut = BaseDate.AddDays(22),
                ActualCheckInDate = null,
                ActualCheckOutDate = null,
                GuestsCount = 3,
                TotalPrice = new Money { Amount = 120000m, Currency = "YER" },
                Status = BookingStatus.Cancelled,
                BookedAt = BaseDate.AddDays(-4),
                CancellationReason = "وجد عقار أفضل",
                PlatformCommissionAmount = 12000m,
                FinalAmount = 120000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-4),
                UpdatedAt = BaseDate.AddDays(-1),
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000026"),
                UserId = User1Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000003"),
                CheckIn = BaseDate.AddDays(8),
                CheckOut = BaseDate.AddDays(11),
                ActualCheckInDate = null,
                ActualCheckOutDate = null,
                GuestsCount = 4,
                TotalPrice = new Money { Amount = 135000m, Currency = "YER" },
                Status = BookingStatus.Cancelled,
                BookedAt = BaseDate.AddDays(-8),
                CancellationReason = "إلغاء رحلة العمل",
                PlatformCommissionAmount = 13500m,
                FinalAmount = 135000m,
                BookingSource = "MobileApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-8),
                UpdatedAt = BaseDate.AddDays(-6),
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000027"),
                UserId = User2Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000005"),
                CheckIn = BaseDate.AddDays(12),
                CheckOut = BaseDate.AddDays(15),
                ActualCheckInDate = null,
                ActualCheckOutDate = null,
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 360000m, Currency = "YER" },
                Status = BookingStatus.Cancelled,
                BookedAt = BaseDate.AddDays(-10),
                CancellationReason = "مشكلة في الدفع",
                PlatformCommissionAmount = 36000m,
                FinalAmount = 360000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-10),
                UpdatedAt = BaseDate.AddDays(-8),
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000028"),
                UserId = User3Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000002"),
                CheckIn = BaseDate.AddDays(25),
                CheckOut = BaseDate.AddDays(27),
                ActualCheckInDate = null,
                ActualCheckOutDate = null,
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 108000m, Currency = "YER" },
                Status = BookingStatus.Cancelled,
                BookedAt = BaseDate.AddDays(-3),
                CancellationReason = "حجز مكرر بالخطأ",
                PlatformCommissionAmount = 10800m,
                FinalAmount = 108000m,
                BookingSource = "MobileApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-3),
                UpdatedAt = BaseDate.AddDays(-2),
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000029"),
                UserId = User4Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000007"),
                CheckIn = BaseDate.AddDays(18),
                CheckOut = BaseDate.AddDays(21),
                ActualCheckInDate = null,
                ActualCheckOutDate = null,
                GuestsCount = 4,
                TotalPrice = new Money { Amount = 540000m, Currency = "YER" },
                Status = BookingStatus.Cancelled,
                BookedAt = BaseDate.AddDays(-7),
                CancellationReason = "تأجيل الحدث",
                PlatformCommissionAmount = 54000m,
                FinalAmount = 540000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-7),
                UpdatedAt = BaseDate.AddDays(-4),
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000030"),
                UserId = User5Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000006"),
                CheckIn = BaseDate.AddDays(22),
                CheckOut = BaseDate.AddDays(25),
                ActualCheckInDate = null,
                ActualCheckOutDate = null,
                GuestsCount = 3,
                TotalPrice = new Money { Amount = 450000m, Currency = "YER" },
                Status = BookingStatus.Cancelled,
                BookedAt = BaseDate.AddDays(-6),
                CancellationReason = "عدم توفر تأشيرة",
                PlatformCommissionAmount = 45000m,
                FinalAmount = 450000m,
                BookingSource = "MobileApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-6),
                UpdatedAt = BaseDate.AddDays(-3),
                IsActive = true,
                IsDeleted = false
            });

            // ═══════════════════════════════════════════════════════════════════════
            // القسم 4: حجوزات مؤكدة ونشطة (Confirmed) - 10 حجوزات
            // ═══════════════════════════════════════════════════════════════════════

            // 31. حجز مؤكد - فندق الزهراء
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000031"),
                UserId = User1Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000001"),
                CheckIn = BaseDate.AddDays(5),
                CheckOut = BaseDate.AddDays(8),
                ActualCheckInDate = null,
                ActualCheckOutDate = null,
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 90000m, Currency = "YER" },
                Status = BookingStatus.Confirmed,
                BookedAt = BaseDate.AddDays(-2),
                PlatformCommissionAmount = 9000m,
                FinalAmount = 90000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-2),
                UpdatedAt = BaseDate.AddDays(-2),
                IsActive = true,
                IsDeleted = false
            });

            // 32-40: مزيد من الحجوزات المؤكدة
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000032"),
                UserId = User2Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000004"),
                CheckIn = BaseDate.AddDays(7),
                CheckOut = BaseDate.AddDays(11),
                ActualCheckInDate = null,
                ActualCheckOutDate = null,
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 400000m, Currency = "YER" },
                Status = BookingStatus.Confirmed,
                BookedAt = BaseDate.AddDays(-3),
                PlatformCommissionAmount = 40000m,
                FinalAmount = 400000m,
                BookingSource = "MobileApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-3),
                UpdatedAt = BaseDate.AddDays(-3),
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000033"),
                UserId = User3Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000008"),
                CheckIn = BaseDate.AddDays(10),
                CheckOut = BaseDate.AddDays(12),
                ActualCheckInDate = null,
                ActualCheckOutDate = null,
                GuestsCount = 3,
                TotalPrice = new Money { Amount = 120000m, Currency = "YER" },
                Status = BookingStatus.Confirmed,
                BookedAt = BaseDate.AddDays(-4),
                PlatformCommissionAmount = 12000m,
                FinalAmount = 120000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-4),
                UpdatedAt = BaseDate.AddDays(-4),
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000034"),
                UserId = User4Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000002"),
                CheckIn = BaseDate.AddDays(14),
                CheckOut = BaseDate.AddDays(16),
                ActualCheckInDate = null,
                ActualCheckOutDate = null,
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 108000m, Currency = "YER" },
                Status = BookingStatus.Confirmed,
                BookedAt = BaseDate.AddDays(-1),
                PlatformCommissionAmount = 10800m,
                FinalAmount = 108000m,
                BookingSource = "MobileApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-1),
                UpdatedAt = BaseDate.AddDays(-1),
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000035"),
                UserId = User5Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000005"),
                CheckIn = BaseDate.AddDays(16),
                CheckOut = BaseDate.AddDays(20),
                ActualCheckInDate = null,
                ActualCheckOutDate = null,
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 480000m, Currency = "YER" },
                Status = BookingStatus.Confirmed,
                BookedAt = BaseDate.AddDays(-5),
                PlatformCommissionAmount = 48000m,
                FinalAmount = 480000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-5),
                UpdatedAt = BaseDate.AddDays(-5),
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000036"),
                UserId = User1Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000003"),
                CheckIn = BaseDate.AddDays(28),
                CheckOut = BaseDate.AddDays(31),
                ActualCheckInDate = null,
                ActualCheckOutDate = null,
                GuestsCount = 4,
                TotalPrice = new Money { Amount = 135000m, Currency = "YER" },
                Status = BookingStatus.Confirmed,
                BookedAt = BaseDate.AddDays(-1),
                PlatformCommissionAmount = 13500m,
                FinalAmount = 135000m,
                BookingSource = "MobileApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-1),
                UpdatedAt = BaseDate.AddDays(-1),
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000037"),
                UserId = User2Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000007"),
                CheckIn = BaseDate.AddDays(30),
                CheckOut = BaseDate.AddDays(33),
                ActualCheckInDate = null,
                ActualCheckOutDate = null,
                GuestsCount = 4,
                TotalPrice = new Money { Amount = 540000m, Currency = "YER" },
                Status = BookingStatus.Confirmed,
                BookedAt = BaseDate.AddDays(-2),
                PlatformCommissionAmount = 54000m,
                FinalAmount = 540000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-2),
                UpdatedAt = BaseDate.AddDays(-2),
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000038"),
                UserId = User3Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000009"),
                CheckIn = BaseDate.AddDays(35),
                CheckOut = BaseDate.AddDays(37),
                ActualCheckInDate = null,
                ActualCheckOutDate = null,
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 100000m, Currency = "YER" },
                Status = BookingStatus.Confirmed,
                BookedAt = BaseDate,
                PlatformCommissionAmount = 10000m,
                FinalAmount = 100000m,
                BookingSource = "MobileApp",
                IsWalkIn = false,
                CreatedAt = BaseDate,
                UpdatedAt = BaseDate,
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000039"),
                UserId = User4Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000006"),
                CheckIn = BaseDate.AddDays(40),
                CheckOut = BaseDate.AddDays(43),
                ActualCheckInDate = null,
                ActualCheckOutDate = null,
                GuestsCount = 3,
                TotalPrice = new Money { Amount = 450000m, Currency = "YER" },
                Status = BookingStatus.Confirmed,
                BookedAt = BaseDate.AddDays(-1),
                PlatformCommissionAmount = 45000m,
                FinalAmount = 450000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-1),
                UpdatedAt = BaseDate.AddDays(-1),
                IsActive = true,
                IsDeleted = false
            });

            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000040"),
                UserId = User5Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000001"),
                CheckIn = BaseDate.AddDays(45),
                CheckOut = BaseDate.AddDays(48),
                ActualCheckInDate = null,
                ActualCheckOutDate = null,
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 90000m, Currency = "YER" },
                Status = BookingStatus.Confirmed,
                BookedAt = BaseDate,
                PlatformCommissionAmount = 9000m,
                FinalAmount = 90000m,
                BookingSource = "MobileApp",
                IsWalkIn = false,
                CreatedAt = BaseDate,
                UpdatedAt = BaseDate,
                IsActive = true,
                IsDeleted = false
            });

            // ─────────────────────────────────────────────────────────────────────
            // القسم 5: حجوزات إضافية بسيناريوهات متنوعة (41 - 50)
            // ─────────────────────────────────────────────────────────────────────

            // 41. حجز قيد التنفيذ (CheckedIn) - ديلوكس 202 - مستخدم 1
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000041"),
                UserId = User1Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000005"),
                CheckIn = BaseDate.AddDays(-1),
                CheckOut = BaseDate.AddDays(2),
                ActualCheckInDate = BaseDate.AddDays(-1).AddHours(15),
                ActualCheckOutDate = null,
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 450000m, Currency = "YER" },
                Status = BookingStatus.CheckedIn,
                BookedAt = BaseDate.AddDays(-3),
                PlatformCommissionAmount = 45000m,
                FinalAmount = 450000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-3),
                UpdatedAt = BaseDate,
                IsActive = true,
                IsDeleted = false
            });

            // 42. حجز ملغي قبل الوصول - استوديو A1 - مستخدم 2
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000042"),
                UserId = User2Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000008"),
                CheckIn = BaseDate.AddDays(3),
                CheckOut = BaseDate.AddDays(5),
                ActualCheckInDate = null,
                ActualCheckOutDate = null,
                GuestsCount = 1,
                TotalPrice = new Money { Amount = 60000m, Currency = "YER" },
                Status = BookingStatus.Cancelled,
                BookedAt = BaseDate.AddDays(-2),
                PlatformCommissionAmount = 6000m,
                FinalAmount = 60000m,
                BookingSource = "MobileApp",
                IsWalkIn = false,
                CancellationReason = "إلغاء من العميل قبل الوصول",
                CreatedAt = BaseDate.AddDays(-2),
                UpdatedAt = BaseDate.AddDays(-1),
                IsActive = true,
                IsDeleted = false
            });

            // 43. حجز مكتمل Walk-In - جناح 301 - مستخدم 3
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000043"),
                UserId = User3Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000003"),
                CheckIn = BaseDate.AddDays(-6),
                CheckOut = BaseDate.AddDays(-4),
                ActualCheckInDate = BaseDate.AddDays(-6).AddHours(16),
                ActualCheckOutDate = BaseDate.AddDays(-4).AddHours(11),
                GuestsCount = 4,
                TotalPrice = new Money { Amount = 180000m, Currency = "YER" },
                Status = BookingStatus.Completed,
                BookedAt = BaseDate.AddDays(-6),
                PlatformCommissionAmount = 18000m,
                FinalAmount = 180000m,
                BookingSource = "WalkIn",
                IsWalkIn = true,
                CreatedAt = BaseDate.AddDays(-6),
                UpdatedAt = BaseDate.AddDays(-4),
                IsActive = true,
                IsDeleted = false
            });

            // 44. حجز مؤكد مستقبلي - جناح 303 - مستخدم 4
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000044"),
                UserId = User4Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000017"),
                CheckIn = BaseDate.AddDays(10),
                CheckOut = BaseDate.AddDays(13),
                ActualCheckInDate = null,
                ActualCheckOutDate = null,
                GuestsCount = 3,
                TotalPrice = new Money { Amount = 380000m, Currency = "YER" },
                Status = BookingStatus.Confirmed,
                BookedAt = BaseDate.AddDays(-1),
                PlatformCommissionAmount = 38000m,
                FinalAmount = 380000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-1),
                UpdatedAt = BaseDate.AddDays(-1),
                IsActive = true,
                IsDeleted = false
            });

            // 45. حجز قيد التنفيذ (CheckedIn) - جناح رويال 404 - مستخدم 5
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000045"),
                UserId = User5Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000021"),
                CheckIn = BaseDate.AddDays(-2),
                CheckOut = BaseDate.AddDays(1),
                ActualCheckInDate = BaseDate.AddDays(-2).AddHours(14),
                ActualCheckOutDate = null,
                GuestsCount = 3,
                TotalPrice = new Money { Amount = 520000m, Currency = "YER" },
                Status = BookingStatus.CheckedIn,
                BookedAt = BaseDate.AddDays(-5),
                PlatformCommissionAmount = 52000m,
                FinalAmount = 520000m,
                BookingSource = "MobileApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-5),
                UpdatedAt = BaseDate,
                IsActive = true,
                IsDeleted = false
            });

            // 46. حجز مكتمل - شقة غرفتين C3 - مستخدم 1
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000046"),
                UserId = User1Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000010"),
                CheckIn = BaseDate.AddDays(-12),
                CheckOut = BaseDate.AddDays(-9),
                ActualCheckInDate = BaseDate.AddDays(-12).AddHours(13),
                ActualCheckOutDate = BaseDate.AddDays(-9).AddHours(12),
                GuestsCount = 4,
                TotalPrice = new Money { Amount = 300000m, Currency = "YER" },
                Status = BookingStatus.Completed,
                BookedAt = BaseDate.AddDays(-15),
                PlatformCommissionAmount = 30000m,
                FinalAmount = 300000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-15),
                UpdatedAt = BaseDate.AddDays(-9),
                IsActive = true,
                IsDeleted = false
            });

            // 47. حجز مؤكد عبر الموبايل - استوديو H1 - مستخدم 2
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000047"),
                UserId = User2Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000033"),
                CheckIn = BaseDate.AddDays(7),
                CheckOut = BaseDate.AddDays(8),
                ActualCheckInDate = null,
                ActualCheckOutDate = null,
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 60000m, Currency = "YER" },
                Status = BookingStatus.Confirmed,
                BookedAt = BaseDate,
                PlatformCommissionAmount = 6000m,
                FinalAmount = 60000m,
                BookingSource = "MobileApp",
                IsWalkIn = false,
                CreatedAt = BaseDate,
                UpdatedAt = BaseDate,
                IsActive = true,
                IsDeleted = false
            });

            // 48. حجز ملغي يوم الوصول - شاليه بحري A - مستخدم 3
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000048"),
                UserId = User3Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000027"),
                CheckIn = BaseDate.AddDays(1),
                CheckOut = BaseDate.AddDays(3),
                ActualCheckInDate = null,
                ActualCheckOutDate = null,
                GuestsCount = 4,
                TotalPrice = new Money { Amount = 220000m, Currency = "YER" },
                Status = BookingStatus.Cancelled,
                BookedAt = BaseDate.AddDays(-1),
                PlatformCommissionAmount = 22000m,
                FinalAmount = 220000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CancellationReason = "إلغاء يوم الوصول بسبب ظرف طارئ",
                CreatedAt = BaseDate.AddDays(-1),
                UpdatedAt = BaseDate,
                IsActive = true,
                IsDeleted = false
            });

            // 49. حجز مكتمل - جناح الوادي 304 - مستخدم 4
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000049"),
                UserId = User4Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000020"),
                CheckIn = BaseDate.AddDays(-20),
                CheckOut = BaseDate.AddDays(-18),
                ActualCheckInDate = BaseDate.AddDays(-20).AddHours(14),
                ActualCheckOutDate = BaseDate.AddDays(-18).AddHours(11),
                GuestsCount = 3,
                TotalPrice = new Money { Amount = 340000m, Currency = "YER" },
                Status = BookingStatus.Completed,
                BookedAt = BaseDate.AddDays(-25),
                PlatformCommissionAmount = 34000m,
                FinalAmount = 340000m,
                BookingSource = "WebApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-25),
                UpdatedAt = BaseDate.AddDays(-18),
                IsActive = true,
                IsDeleted = false
            });

            // 50. حجز مؤكد - شقة غرفة واحدة M2 - مستخدم 5
            bookings.Add(new Booking
            {
                Id = Guid.Parse("B0000000-0000-0000-0000-000000000050"),
                UserId = User5Id,
                UnitId = Guid.Parse("20000000-0000-0000-0000-000000000046"),
                CheckIn = BaseDate.AddDays(12),
                CheckOut = BaseDate.AddDays(14),
                ActualCheckInDate = null,
                ActualCheckOutDate = null,
                GuestsCount = 2,
                TotalPrice = new Money { Amount = 120000m, Currency = "YER" },
                Status = BookingStatus.Confirmed,
                BookedAt = BaseDate.AddDays(-2),
                PlatformCommissionAmount = 12000m,
                FinalAmount = 120000m,
                BookingSource = "MobileApp",
                IsWalkIn = false,
                CreatedAt = BaseDate.AddDays(-2),
                UpdatedAt = BaseDate.AddDays(-2),
                IsActive = true,
                IsDeleted = false
            });

            return bookings;
        }
    }
}
