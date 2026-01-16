using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.ValueObjects;

namespace YemenBooking.Core.Seeds
{
    /// <summary>
    /// بيانات أولية يدوية للمدفوعات - مرتبطة بدقة بالحجوزات
    /// Manual seed data for payments - precisely linked to bookings
    /// </summary>
    public class PaymentSeeder : ISeeder<Payment>
    {
        private static readonly DateTime BaseDate = DateTime.UtcNow.Date;

        // معرفات المستخدمين
        private static readonly Guid User1Id = Guid.Parse("C0000000-0000-0000-0000-000000000001");
        private static readonly Guid User2Id = Guid.Parse("C0000000-0000-0000-0000-000000000002");
        private static readonly Guid User3Id = Guid.Parse("C0000000-0000-0000-0000-000000000003");
        private static readonly Guid User4Id = Guid.Parse("C0000000-0000-0000-0000-000000000004");
        private static readonly Guid User5Id = Guid.Parse("C0000000-0000-0000-0000-000000000005");

        public IEnumerable<Payment> SeedData()
        {
            var payments = new List<Payment>();

            // ═══════════════════════════════════════════════════════════════════════
            // القسم 1: مدفوعات الحجوزات المكتملة (15 حجز = 30 دفعة)
            // مقدمة 30% + دفعة نهائية 70%
            // ═══════════════════════════════════════════════════════════════════════

            // الحجز 1: 90,000 YER
            payments.Add(CreatePayment(
                id: "A0000000-0000-0000-0000-000000000001",
                bookingId: "B0000000-0000-0000-0000-000000000001",
                amount: 27000m, // 30% مقدمة
                currency: "YER",
                method: PaymentMethodEnum.JwaliWallet,
                status: PaymentStatus.Successful,
                paymentDate: BaseDate.AddDays(-50),
                processedBy: User1Id,
                transactionId: "JWL-20241012140030-1234"
            ));

            payments.Add(CreatePayment(
                id: "A0000000-0000-0000-0000-000000000002",
                bookingId: "B0000000-0000-0000-0000-000000000001",
                amount: 63000m, // 70% دفعة نهائية
                currency: "YER",
                method: PaymentMethodEnum.Cash,
                status: PaymentStatus.Successful,
                paymentDate: BaseDate.AddDays(-45).AddHours(14),
                processedBy: User1Id,
                transactionId: "CSH-20241027140000-5678"
            ));

            // الحجز 2: 500,000 YER
            payments.Add(CreatePayment(
                id: "A0000000-0000-0000-0000-000000000003",
                bookingId: "B0000000-0000-0000-0000-000000000002",
                amount: 500000m, // دفعة كاملة
                currency: "YER",
                method: PaymentMethodEnum.CreditCard,
                status: PaymentStatus.Successful,
                paymentDate: BaseDate.AddDays(-48),
                processedBy: User2Id,
                transactionId: "CRD-20241014120000-2345",
                gatewayId: "GW-7A8B9C0D1E2F3G4H"
            ));

            // الحجز 3: 120,000 YER
            payments.Add(CreatePayment(
                id: "A0000000-0000-0000-0000-000000000004",
                bookingId: "B0000000-0000-0000-0000-000000000003",
                amount: 36000m,
                currency: "YER",
                method: PaymentMethodEnum.CashWallet,
                status: PaymentStatus.Successful,
                paymentDate: BaseDate.AddDays(-42),
                processedBy: User3Id,
                transactionId: "CWL-20241020100000-3456"
            ));

            payments.Add(CreatePayment(
                id: "A0000000-0000-0000-0000-000000000005",
                bookingId: "B0000000-0000-0000-0000-000000000003",
                amount: 84000m,
                currency: "YER",
                method: PaymentMethodEnum.Cash,
                status: PaymentStatus.Successful,
                paymentDate: BaseDate.AddDays(-38).AddHours(13),
                processedBy: User3Id,
                transactionId: "CSH-20241024130000-4567"
            ));

            // الحجز 4: 135,000 YER
            payments.Add(CreatePayment(
                id: "A0000000-0000-0000-0000-000000000006",
                bookingId: "B0000000-0000-0000-0000-000000000004",
                amount: 135000m, // دفعة كاملة
                currency: "YER",
                method: PaymentMethodEnum.Paypal,
                status: PaymentStatus.Successful,
                paymentDate: BaseDate.AddDays(-40),
                processedBy: User4Id,
                transactionId: "PPL-20241022150000-5678",
                gatewayId: "GW-1F2E3D4C5B6A7890"
            ));

            // الحجز 5: 360,000 YER
            payments.Add(CreatePayment(
                id: "A0000000-0000-0000-0000-000000000007",
                bookingId: "B0000000-0000-0000-0000-000000000005",
                amount: 108000m,
                currency: "YER",
                method: PaymentMethodEnum.JwaliWallet,
                status: PaymentStatus.Successful,
                paymentDate: BaseDate.AddDays(-38),
                processedBy: User5Id,
                transactionId: "JWL-20241024180000-6789"
            ));

            payments.Add(CreatePayment(
                id: "A0000000-0000-0000-0000-000000000008",
                bookingId: "B0000000-0000-0000-0000-000000000005",
                amount: 252000m,
                currency: "YER",
                method: PaymentMethodEnum.CreditCard,
                status: PaymentStatus.Successful,
                paymentDate: BaseDate.AddDays(-33).AddHours(15),
                processedBy: User5Id,
                transactionId: "CRD-20241029150000-7890",
                gatewayId: "GW-9H8G7F6E5D4C3B2A"
            ));

            // الحجز 6: 108,000 YER
            payments.Add(CreatePayment(
                id: "A0000000-0000-0000-0000-000000000009",
                bookingId: "B0000000-0000-0000-0000-000000000006",
                amount: 32400m,
                currency: "YER",
                method: PaymentMethodEnum.Cash,
                status: PaymentStatus.Successful,
                paymentDate: BaseDate.AddDays(-35),
                processedBy: User1Id,
                transactionId: "CSH-20241027110000-8901"
            ));

            payments.Add(CreatePayment(
                id: "A0000000-0000-0000-0000-000000000010",
                bookingId: "B0000000-0000-0000-0000-000000000006",
                amount: 75600m,
                currency: "YER",
                method: PaymentMethodEnum.Cash,
                status: PaymentStatus.Successful,
                paymentDate: BaseDate.AddDays(-30).AddHours(14),
                processedBy: User1Id,
                transactionId: "CSH-20241101140000-9012"
            ));

            // الحجز 7: 450,000 YER
            payments.Add(CreatePayment(
                id: "A0000000-0000-0000-0000-000000000011",
                bookingId: "B0000000-0000-0000-0000-000000000007",
                amount: 450000m, // دفعة كاملة
                currency: "YER",
                method: PaymentMethodEnum.CreditCard,
                status: PaymentStatus.Successful,
                paymentDate: BaseDate.AddDays(-32),
                processedBy: User2Id,
                transactionId: "CRD-20241030100000-0123",
                gatewayId: "GW-A1B2C3D4E5F6G7H8"
            ));

            // الحجز 8: 540,000 YER
            payments.Add(CreatePayment(
                id: "A0000000-0000-0000-0000-000000000012",
                bookingId: "B0000000-0000-0000-0000-000000000008",
                amount: 162000m,
                currency: "YER",
                method: PaymentMethodEnum.JwaliWallet,
                status: PaymentStatus.Successful,
                paymentDate: BaseDate.AddDays(-30),
                processedBy: User3Id,
                transactionId: "JWL-20241101120000-1234"
            ));

            payments.Add(CreatePayment(
                id: "A0000000-0000-0000-0000-000000000013",
                bookingId: "B0000000-0000-0000-0000-000000000008",
                amount: 378000m,
                currency: "YER",
                method: PaymentMethodEnum.Cash,
                status: PaymentStatus.Successful,
                paymentDate: BaseDate.AddDays(-26).AddHours(14),
                processedBy: User3Id,
                transactionId: "CSH-20241105140000-2345"
            ));

            // الحجز 9: 100,000 YER
            payments.Add(CreatePayment(
                id: "A0000000-0000-0000-0000-000000000014",
                bookingId: "B0000000-0000-0000-0000-000000000009",
                amount: 30000m,
                currency: "YER",
                method: PaymentMethodEnum.CashWallet,
                status: PaymentStatus.Successful,
                paymentDate: BaseDate.AddDays(-28),
                processedBy: User4Id,
                transactionId: "CWL-20241103130000-3456"
            ));

            payments.Add(CreatePayment(
                id: "A0000000-0000-0000-0000-000000000015",
                bookingId: "B0000000-0000-0000-0000-000000000009",
                amount: 70000m,
                currency: "YER",
                method: PaymentMethodEnum.Cash,
                status: PaymentStatus.Successful,
                paymentDate: BaseDate.AddDays(-24).AddHours(13),
                processedBy: User4Id,
                transactionId: "CSH-20241107130000-4567"
            ));

            // الحجز 10: 90,000 YER
            payments.Add(CreatePayment(
                id: "A0000000-0000-0000-0000-000000000016",
                bookingId: "B0000000-0000-0000-0000-000000000010",
                amount: 90000m, // دفعة كاملة
                currency: "YER",
                method: PaymentMethodEnum.Paypal,
                status: PaymentStatus.Successful,
                paymentDate: BaseDate.AddDays(-26),
                processedBy: User5Id,
                transactionId: "PPL-20241105150000-5678",
                gatewayId: "GW-H8G7F6E5D4C3B2A1"
            ));

            // الحجز 11-15: مدفوعات باقي الحجوزات المكتملة
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000017", "B0000000-0000-0000-0000-000000000011", 90000m, "YER", PaymentMethodEnum.CreditCard, PaymentStatus.Successful, BaseDate.AddDays(-24), User1Id, "CRD-20241107090000-6789", "GW-2A3B4C5D6E7F8G9H"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000018", "B0000000-0000-0000-0000-000000000011", 210000m, "YER", PaymentMethodEnum.Cash, PaymentStatus.Successful, BaseDate.AddDays(-20).AddHours(15), User1Id, "CSH-20241111150000-7890"));
            
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000019", "B0000000-0000-0000-0000-000000000012", 120000m, "YER", PaymentMethodEnum.JwaliWallet, PaymentStatus.Successful, BaseDate.AddDays(-22), User2Id, "JWL-20241109120000-8901"));
            
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000020", "B0000000-0000-0000-0000-000000000013", 32400m, "YER", PaymentMethodEnum.Cash, PaymentStatus.Successful, BaseDate.AddDays(-20), User3Id, "CSH-20241111100000-9012"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000021", "B0000000-0000-0000-0000-000000000013", 75600m, "YER", PaymentMethodEnum.Cash, PaymentStatus.Successful, BaseDate.AddDays(-16).AddHours(14), User3Id, "CSH-20241115140000-0123"));
            
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000022", "B0000000-0000-0000-0000-000000000014", 360000m, "YER", PaymentMethodEnum.CreditCard, PaymentStatus.Successful, BaseDate.AddDays(-18), User4Id, "CRD-20241113160000-1234", "GW-9I8H7G6F5E4D3C2B"));
            
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000023", "B0000000-0000-0000-0000-000000000015", 40500m, "YER", PaymentMethodEnum.CashWallet, PaymentStatus.Successful, BaseDate.AddDays(-16), User5Id, "CWL-20241115130000-2345"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000024", "B0000000-0000-0000-0000-000000000015", 94500m, "YER", PaymentMethodEnum.Cash, PaymentStatus.Successful, BaseDate.AddDays(-12).AddHours(14), User5Id, "CSH-20241119140000-3456"));

            // ═══════════════════════════════════════════════════════════════════════
            // القسم 2: مدفوعات الحجوزات قيد التنفيذ (7 حجوزات = 14 دفعة)
            // ═══════════════════════════════════════════════════════════════════════

            // الحجز 16: 120,000 YER
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000025", "B0000000-0000-0000-0000-000000000016", 36000m, "YER", PaymentMethodEnum.JwaliWallet, PaymentStatus.Successful, BaseDate.AddDays(-10), User1Id, "JWL-20241121100000-4567"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000026", "B0000000-0000-0000-0000-000000000016", 84000m, "YER", PaymentMethodEnum.Cash, PaymentStatus.Successful, BaseDate.AddDays(-2).AddHours(14), User1Id, "CSH-20241129140000-5678"));

            // الحجز 17: 400,000 YER
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000027", "B0000000-0000-0000-0000-000000000017", 120000m, "YER", PaymentMethodEnum.CreditCard, PaymentStatus.Successful, BaseDate.AddDays(-8), User2Id, "CRD-20241123120000-6789", "GW-C3B2A1Z9Y8X7W6V5"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000028", "B0000000-0000-0000-0000-000000000017", 280000m, "YER", PaymentMethodEnum.CreditCard, PaymentStatus.Successful, BaseDate.AddDays(-1).AddHours(15), User2Id, "CRD-20241130150000-7890", "GW-V5W6X7Y8Z9A1B2C3"));

            // الحجز 18: 120,000 YER
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000029", "B0000000-0000-0000-0000-000000000018", 120000m, "YER", PaymentMethodEnum.Cash, PaymentStatus.Successful, BaseDate.AddDays(-6), User3Id, "CSH-20241125110000-8901"));

            // الحجز 19: 108,000 YER
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000030", "B0000000-0000-0000-0000-000000000019", 32400m, "YER", PaymentMethodEnum.JwaliWallet, PaymentStatus.Successful, BaseDate.AddDays(-5), User4Id, "JWL-20241126140000-9012"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000031", "B0000000-0000-0000-0000-000000000019", 75600m, "YER", PaymentMethodEnum.Cash, PaymentStatus.Successful, BaseDate.AddHours(14), User4Id, "CSH-20241201140000-0123"));

            // الحجز 20: 480,000 YER
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000032", "B0000000-0000-0000-0000-000000000020", 144000m, "YER", PaymentMethodEnum.CreditCard, PaymentStatus.Successful, BaseDate.AddDays(-7), User5Id, "CRD-20241124150000-1234", "GW-D4E5F6G7H8I9J0K1"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000033", "B0000000-0000-0000-0000-000000000020", 336000m, "YER", PaymentMethodEnum.CreditCard, PaymentStatus.Successful, BaseDate.AddHours(15), User5Id, "CRD-20241201150000-2345", "GW-K1J0I9H8G7F6E5D4"));

            // الحجز 21: 540,000 YER
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000034", "B0000000-0000-0000-0000-000000000021", 162000m, "YER", PaymentMethodEnum.Paypal, PaymentStatus.Successful, BaseDate.AddDays(-9), User1Id, "PPL-20241122120000-3456", "GW-L2M3N4O5P6Q7R8S9"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000035", "B0000000-0000-0000-0000-000000000021", 378000m, "YER", PaymentMethodEnum.Cash, PaymentStatus.Successful, BaseDate.AddDays(-1).AddHours(14), User1Id, "CSH-20241130140000-4567"));

            // الحجز 22: 150,000 YER
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000036", "B0000000-0000-0000-0000-000000000022", 45000m, "YER", PaymentMethodEnum.CashWallet, PaymentStatus.Successful, BaseDate.AddDays(-8), User2Id, "CWL-20241123130000-5678"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000037", "B0000000-0000-0000-0000-000000000022", 105000m, "YER", PaymentMethodEnum.Cash, PaymentStatus.Successful, BaseDate.AddDays(-2).AddHours(13), User2Id, "CSH-20241129130000-6789"));

            // ═══════════════════════════════════════════════════════════════════════
            // القسم 3: مدفوعات الحجوزات الملغاة (8 حجوزات) مع مردودات
            // ═══════════════════════════════════════════════════════════════════════

            // الحجز 23: استرداد كامل 100%
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000038", "B0000000-0000-0000-0000-000000000023", 27000m, "YER", PaymentMethodEnum.JwaliWallet, PaymentStatus.Successful, BaseDate.AddDays(-5), User3Id, "JWL-20241126100000-7890"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000039", "B0000000-0000-0000-0000-000000000023", 27000m, "YER", PaymentMethodEnum.JwaliWallet, PaymentStatus.Refunded, BaseDate.AddDays(-2).AddHours(10), User3Id, "JWL-RFND-20241129100000-8901"));

            // الحجز 24: استرداد جزئي 50%
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000040", "B0000000-0000-0000-0000-000000000024", 120000m, "YER", PaymentMethodEnum.CreditCard, PaymentStatus.Successful, BaseDate.AddDays(-12), User4Id, "CRD-20241119090000-9012", "GW-S9R8Q7P6O5N4M3L2"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000041", "B0000000-0000-0000-0000-000000000024", 60000m, "YER", PaymentMethodEnum.CreditCard, PaymentStatus.PartiallyRefunded, BaseDate.AddDays(-3).AddHours(11), User4Id, "CRD-RFND-20241128110000-0123", "GW-L2M3N4O5P6Q7R8S9"));

            // الحجز 25: استرداد كامل
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000042", "B0000000-0000-0000-0000-000000000025", 36000m, "YER", PaymentMethodEnum.Cash, PaymentStatus.Successful, BaseDate.AddDays(-4), User5Id, "CSH-20241127120000-1234"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000043", "B0000000-0000-0000-0000-000000000025", 36000m, "YER", PaymentMethodEnum.Cash, PaymentStatus.Refunded, BaseDate.AddDays(-1).AddHours(9), User5Id, "CSH-RFND-20241130090000-2345"));

            // الحجز 26: استرداد جزئي 70%
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000044", "B0000000-0000-0000-0000-000000000026", 40500m, "YER", PaymentMethodEnum.Paypal, PaymentStatus.Successful, BaseDate.AddDays(-8), User1Id, "PPL-20241123150000-3456", "GW-T0U1V2W3X4Y5Z6A7"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000045", "B0000000-0000-0000-0000-000000000026", 28350m, "YER", PaymentMethodEnum.Paypal, PaymentStatus.PartiallyRefunded, BaseDate.AddDays(-6).AddHours(12), User1Id, "PPL-RFND-20241125120000-4567", "GW-A7Z6Y5X4W3V2U1T0"));

            // الحجز 27: دفعة فاشلة ثم ناجحة (لاحقاً ملغى مع مردود)
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000046", "B0000000-0000-0000-0000-000000000027", 108000m, "YER", PaymentMethodEnum.CreditCard, PaymentStatus.Failed, BaseDate.AddDays(-10), User2Id, "CRD-FAIL-20241121100000-5678", "GW-FAIL-123456789"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000047", "B0000000-0000-0000-0000-000000000027", 108000m, "YER", PaymentMethodEnum.JwaliWallet, PaymentStatus.Successful, BaseDate.AddDays(-10).AddHours(2), User2Id, "JWL-20241121120000-6789"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000048", "B0000000-0000-0000-0000-000000000027", 54000m, "YER", PaymentMethodEnum.JwaliWallet, PaymentStatus.PartiallyRefunded, BaseDate.AddDays(-8).AddHours(10), User2Id, "JWL-RFND-20241123100000-7890"));

            // الحجز 28: استرداد كامل
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000049", "B0000000-0000-0000-0000-000000000028", 32400m, "YER", PaymentMethodEnum.CashWallet, PaymentStatus.Successful, BaseDate.AddDays(-3), User3Id, "CWL-20241128110000-8901"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000050", "B0000000-0000-0000-0000-000000000028", 32400m, "YER", PaymentMethodEnum.CashWallet, PaymentStatus.Refunded, BaseDate.AddDays(-2).AddHours(15), User3Id, "CWL-RFND-20241129150000-9012"));

            // الحجز 29: دفعة معلقة (لم تكتمل)
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000051", "B0000000-0000-0000-0000-000000000029", 162000m, "YER", PaymentMethodEnum.CreditCard, PaymentStatus.Pending, BaseDate.AddDays(-7), User4Id, "CRD-PEND-20241124140000-0123", "GW-PENDING-987654321"));

            // الحجز 30: استرداد كامل
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000052", "B0000000-0000-0000-0000-000000000030", 135000m, "YER", PaymentMethodEnum.Cash, PaymentStatus.Successful, BaseDate.AddDays(-6), User5Id, "CSH-20241125090000-1234"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000053", "B0000000-0000-0000-0000-000000000030", 135000m, "YER", PaymentMethodEnum.Cash, PaymentStatus.Refunded, BaseDate.AddDays(-3).AddHours(13), User5Id, "CSH-RFND-20241128130000-2345"));

            // ═══════════════════════════════════════════════════════════════════════
            // القسم 4: مدفوعات الحجوزات المؤكدة (10 حجوزات) - مقدمات فقط
            // ═══════════════════════════════════════════════════════════════════════

            // الحجز 31-40: مقدمات 30% فقط
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000054", "B0000000-0000-0000-0000-000000000031", 27000m, "YER", PaymentMethodEnum.JwaliWallet, PaymentStatus.Successful, BaseDate.AddDays(-2), User1Id, "JWL-20241129150000-3456"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000055", "B0000000-0000-0000-0000-000000000032", 120000m, "YER", PaymentMethodEnum.CreditCard, PaymentStatus.Successful, BaseDate.AddDays(-3), User2Id, "CRD-20241128120000-4567", "GW-B8C9D0E1F2G3H4I5"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000056", "B0000000-0000-0000-0000-000000000033", 36000m, "YER", PaymentMethodEnum.Cash, PaymentStatus.Successful, BaseDate.AddDays(-4), User3Id, "CSH-20241127130000-5678"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000057", "B0000000-0000-0000-0000-000000000034", 32400m, "YER", PaymentMethodEnum.CashWallet, PaymentStatus.Successful, BaseDate.AddDays(-1), User4Id, "CWL-20241130110000-6789"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000058", "B0000000-0000-0000-0000-000000000035", 144000m, "YER", PaymentMethodEnum.Paypal, PaymentStatus.Successful, BaseDate.AddDays(-5), User5Id, "PPL-20241126170000-7890", "GW-I5H4G3F2E1D0C9B8"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000059", "B0000000-0000-0000-0000-000000000036", 40500m, "YER", PaymentMethodEnum.JwaliWallet, PaymentStatus.Successful, BaseDate.AddDays(-1), User1Id, "JWL-20241130160000-8901"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000060", "B0000000-0000-0000-0000-000000000037", 162000m, "YER", PaymentMethodEnum.CreditCard, PaymentStatus.Successful, BaseDate.AddDays(-2), User2Id, "CRD-20241129140000-9012", "GW-J6K7L8M9N0O1P2Q3"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000061", "B0000000-0000-0000-0000-000000000038", 30000m, "YER", PaymentMethodEnum.Cash, PaymentStatus.Successful, BaseDate, User3Id, "CSH-20241201100000-0123"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000062", "B0000000-0000-0000-0000-000000000039", 135000m, "YER", PaymentMethodEnum.CreditCard, PaymentStatus.Successful, BaseDate.AddDays(-1), User4Id, "CRD-20241130170000-1234", "GW-Q3P2O1N0M9L8K7J6"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000063", "B0000000-0000-0000-0000-000000000040", 27000m, "YER", PaymentMethodEnum.JwaliWallet, PaymentStatus.Successful, BaseDate, User5Id, "JWL-20241201120000-2345"));

            // ═══════════════════════════════════════════════════════════════════════
            // القسم 5: مدفوعات الحجوزات الجديدة (41 - 50) بسيناريوهات متنوعة
            // ═══════════════════════════════════════════════════════════════════════

            // 41 (CheckedIn): مقدّم 30% + دفعة نهائية 70%
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000064", "B0000000-0000-0000-0000-000000000041", 135000m, "YER", PaymentMethodEnum.CreditCard, PaymentStatus.Successful, BaseDate.AddDays(-3), User1Id, "CRD-20241129093000-4141", "GW-Z1Y2X3W4V5U6T7S8"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000065", "B0000000-0000-0000-0000-000000000041", 315000m, "YER", PaymentMethodEnum.Cash, PaymentStatus.Successful, BaseDate.AddDays(-1).AddHours(18), User1Id, "CSH-20241201180000-4242"));

            // 42 (Cancelled قبل الوصول): مقدّم 30% ثم استرجاع كامل
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000066", "B0000000-0000-0000-0000-000000000042", 18000m, "YER", PaymentMethodEnum.JwaliWallet, PaymentStatus.Successful, BaseDate.AddDays(-2), User2Id, "JWL-20241130094500-4343"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000067", "B0000000-0000-0000-0000-000000000042", 18000m, "YER", PaymentMethodEnum.JwaliWallet, PaymentStatus.Refunded, BaseDate.AddDays(-1), User2Id, "JWL-20241201100000-4444"));

            // 43 (Completed WalkIn): دفعة كاملة نقداً
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000068", "B0000000-0000-0000-0000-000000000043", 180000m, "YER", PaymentMethodEnum.Cash, PaymentStatus.Successful, BaseDate.AddDays(-6).AddHours(17), User3Id, "CSH-20241126170000-4545"));

            // 44 (Confirmed مستقبلية): مقدّم فقط
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000069", "B0000000-0000-0000-0000-000000000044", 114000m, "YER", PaymentMethodEnum.CreditCard, PaymentStatus.Successful, BaseDate.AddDays(-1).AddHours(12), User4Id, "CRD-20241130120000-4646", "GW-R1S2T3U4V5W6X7Y8"));

            // 45 (CheckedIn): مقدّم + دفعة نهائية عبر محفظة نقدية
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000070", "B0000000-0000-0000-0000-000000000045", 156000m, "YER", PaymentMethodEnum.CashWallet, PaymentStatus.Successful, BaseDate.AddDays(-5), User5Id, "CWL-20241127090000-4747"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000071", "B0000000-0000-0000-0000-000000000045", 364000m, "YER", PaymentMethodEnum.CashWallet, PaymentStatus.Successful, BaseDate.AddHours(10), User5Id, "CWL-20241201100000-4848"));

            // 46 (Completed): مقدّم + دفعة نهائية باي بال
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000072", "B0000000-0000-0000-0000-000000000046", 90000m, "YER", PaymentMethodEnum.Paypal, PaymentStatus.Successful, BaseDate.AddDays(-16), User1Id, "PPL-20241121093000-4949", "GW-A1B2C3D4E5F6G7H8"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000073", "B0000000-0000-0000-0000-000000000046", 210000m, "YER", PaymentMethodEnum.Paypal, PaymentStatus.Successful, BaseDate.AddDays(-9).AddHours(12), User1Id, "PPL-20241128120000-5050", "GW-H8G7F6E5D4C3B2A1"));

            // 47 (Confirmed): محاولة فاشلة ثم مقدّم ناجح
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000074", "B0000000-0000-0000-0000-000000000047", 60000m, "YER", PaymentMethodEnum.CreditCard, PaymentStatus.Failed, BaseDate.AddHours(9), User2Id, "CRD-20241201090000-5151", "GW-FAIL-0001"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000075", "B0000000-0000-0000-0000-000000000047", 18000m, "YER", PaymentMethodEnum.CreditCard, PaymentStatus.Successful, BaseDate.AddHours(10), User2Id, "CRD-20241201100000-5252", "GW-SUCCESS-0001"));

            // 48 (Cancelled يوم الوصول): مقدّم ناجح ثم رد جزئي
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000076", "B0000000-0000-0000-0000-000000000048", 66000m, "YER", PaymentMethodEnum.JwaliWallet, PaymentStatus.Successful, BaseDate.AddDays(-1).AddHours(8), User3Id, "JWL-20241130080000-5353"));
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000077", "B0000000-0000-0000-0000-000000000048", 33000m, "YER", PaymentMethodEnum.JwaliWallet, PaymentStatus.PartiallyRefunded, BaseDate.AddHours(14), User3Id, "JWL-20241201140000-5454"));

            // 49 (Completed): دفعة كاملة بطاقة ائتمان
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000078", "B0000000-0000-0000-0000-000000000049", 340000m, "YER", PaymentMethodEnum.CreditCard, PaymentStatus.Successful, BaseDate.AddDays(-25).AddHours(13), User4Id, "CRD-20241119130000-5555", "GW-L1M2N3O4P5Q6R7S8"));

            // 50 (Confirmed): مقدّم قيد الانتظار
            payments.Add(CreatePayment("A0000000-0000-0000-0000-000000000079", "B0000000-0000-0000-0000-000000000050", 36000m, "YER", PaymentMethodEnum.Paypal, PaymentStatus.Pending, BaseDate.AddDays(-2).AddHours(16), User5Id, "PPL-20241129160000-5656", "GW-PENDING-0001"));

            return payments;
        }

        /// <summary>
        /// دالة مساعدة لإنشاء دفعة
        /// </summary>
        private static Payment CreatePayment(
            string id,
            string bookingId,
            decimal amount,
            string currency,
            PaymentMethodEnum method,
            PaymentStatus status,
            DateTime paymentDate,
            Guid processedBy,
            string transactionId,
            string gatewayId = null)
        {
            return new Payment
            {
                Id = Guid.Parse(id),
                BookingId = Guid.Parse(bookingId),
                Amount = new Money { Amount = amount, Currency = currency },
                PaymentMethod = method,
                Status = status,
                PaymentDate = paymentDate,
                ProcessedBy = processedBy,
                ProcessedAt = paymentDate,
                TransactionId = transactionId,
                GatewayTransactionId = gatewayId ?? string.Empty,
                CreatedAt = paymentDate,
                UpdatedAt = paymentDate,
                IsActive = true,
                IsDeleted = false
            };
        }
    }
}
