using System;
using System.Collections.Generic;
using System.Linq;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Seeds
{
    /// <summary>
    /// مولد بيانات احترافي للجداول اليومية (الإتاحة والتسعير)
    /// Professional seeder for Daily Unit Schedules (Availability & Pricing)
    /// </summary>
    public class DailyUnitScheduleSeeder
    {
        private readonly Random _random = new Random(42); // Fixed seed للنتائج القابلة للتكرار
        private readonly DateTime _baseDate = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc);

        /// <summary>
        /// توليد جداول يومية لجميع الوحدات للأشهر القادمة
        /// </summary>
        public List<DailyUnitSchedule> GenerateSchedules(
            List<Unit> units, 
            List<Property> properties,
            int monthsAhead = 6)
        {
            var schedules = new List<DailyUnitSchedule>();
            var startDate = DateTime.UtcNow.Date;
            var endDate = startDate.AddMonths(monthsAhead);

            foreach (var unit in units)
            {
                var property = properties.FirstOrDefault(p => p.Id == unit.PropertyId);
                if (property == null) continue;

                // تحديد استراتيجية التسعير بناءً على نوع العقار
                var pricingStrategy = GetPricingStrategy(property);
                
                // توليد جداول لكل يوم
                var currentDate = startDate;
                while (currentDate < endDate)
                {
                    var schedule = GenerateDaySchedule(unit, property, currentDate, pricingStrategy);
                    schedules.Add(schedule);
                    currentDate = currentDate.AddDays(1);
                }
            }

            return schedules;
        }

        /// <summary>
        /// توليد جدول ليوم واحد
        /// ✅ FIX: تحويل السعر للعملة الصحيحة
        /// </summary>
        private DailyUnitSchedule GenerateDaySchedule(
            Unit unit, 
            Property property, 
            DateTime date,
            PricingStrategy strategy)
        {
            var dayOfWeek = date.DayOfWeek;
            var isWeekend = dayOfWeek == DayOfWeek.Friday || dayOfWeek == DayOfWeek.Saturday;
            var isHoliday = IsYemeniHoliday(date);
            
            // تحديد حالة الإتاحة
            var status = DetermineAvailabilityStatus(date, unit, property);
            
            // حساب السعر بناءً على الاستراتيجية (بالريال اليمني دائماً)
            var priceInfo = CalculatePrice(strategy, isWeekend, isHoliday, date);
            
            // ✅ تحديد العملة النهائية
            var finalCurrency = property.Currency ?? "YER";
            
            // ✅ تحويل السعر للعملة المطلوبة
            var convertedPrice = ConvertPriceToTargetCurrency(
                priceInfo.Amount, 
                "YER",  // السعر المحسوب دائماً بالريال
                finalCurrency
            );
            
            var convertedMinPrice = ConvertPriceToTargetCurrency(
                priceInfo.MinPrice, 
                "YER", 
                finalCurrency
            );
            
            var convertedMaxPrice = ConvertPriceToTargetCurrency(
                priceInfo.MaxPrice, 
                "YER", 
                finalCurrency
            );

            return new DailyUnitSchedule
            {
                Id = Guid.NewGuid(),
                UnitId = unit.Id,
                Date = date.Date,
                
                // خصائص الإتاحة
                Status = status,
                Reason = GetReasonForStatus(status),
                Notes = GetNotesForDay(status, isWeekend, isHoliday),
                BookingId = null,
                
                // ✅ خصائص التسعير (مع التحويل الصحيح)
                PriceAmount = convertedPrice,
                Currency = finalCurrency,
                PriceType = priceInfo.Type,
                PricingTier = priceInfo.Tier,
                PercentageChange = priceInfo.PercentageChange,
                MinPrice = convertedMinPrice,
                MaxPrice = convertedMaxPrice,
                
                // خصائص إضافية
                StartTime = null,
                EndTime = null,
                CreatedBy = "System",
                ModifiedBy = null,
                
                // خصائص BaseEntity
                CreatedAt = _baseDate,
                UpdatedAt = _baseDate,
                IsActive = true,
                IsDeleted = false
            };
        }

        /// <summary>
        /// تحديد حالة الإتاحة بناءً على عدة عوامل
        /// </summary>
        private string DetermineAvailabilityStatus(DateTime date, Unit unit, Property property)
        {
            var daysFromNow = (date - DateTime.UtcNow.Date).Days;
            
            // الأيام القريبة جداً (أول أسبوعين) - احتمال أكبر للحجز
            if (daysFromNow < 14)
            {
                var chance = _random.Next(100);
                if (chance < 60) return "Available"; // 60% متاح
                if (chance < 90) return "Booked";    // 30% محجوز
                if (chance < 95) return "Blocked";   // 5% محظور
                return "Maintenance";                // 5% صيانة
            }
            
            // الأيام البعيدة - احتمال أقل للحجز
            if (daysFromNow > 60)
            {
                var chance = _random.Next(100);
                if (chance < 85) return "Available"; // 85% متاح
                if (chance < 95) return "Blocked";   // 10% محظور
                return "Available";                  // 5% متاح
            }
            
            // الأيام المتوسطة
            var normalChance = _random.Next(100);
            if (normalChance < 70) return "Available"; // 70% متاح
            if (normalChance < 90) return "Booked";    // 20% محجوز
            if (normalChance < 96) return "Blocked";   // 6% محظور
            return "OwnerUse";                         // 4% استخدام المالك
        }

        /// <summary>
        /// الحصول على سبب الحالة
        /// </summary>
        private string? GetReasonForStatus(string status)
        {
            return status switch
            {
                "Blocked" => "محجوز للصيانة الدورية",
                "Maintenance" => "صيانة وتنظيف شامل",
                "OwnerUse" => "استخدام شخصي للمالك",
                _ => null
            };
        }

        /// <summary>
        /// الحصول على ملاحظات لليوم
        /// </summary>
        private string? GetNotesForDay(string status, bool isWeekend, bool isHoliday)
        {
            if (status != "Available") return null;
            
            if (isHoliday) return "عطلة رسمية - أسعار خاصة";
            if (isWeekend) return "عطلة نهاية الأسبوع - طلب مرتفع";
            
            return null;
        }

        /// <summary>
        /// تحديد استراتيجية التسعير بناءً على العقار
        /// </summary>
        private PricingStrategy GetPricingStrategy(Property property)
        {
            // يمكن التوسع هنا بناءً على معايير أخرى
            var random = _random.Next(100);
            
            if (property.StarRating >= 4)
            {
                // فنادق 4-5 نجوم: أسعار مرتفعة ومتغيرة
                return new PricingStrategy
                {
                    BasePrice = _random.Next(150000, 350000), // 150-350 ألف ريال
                    WeekendMultiplier = 1.3m,
                    HolidayMultiplier = 1.5m,
                    SeasonalVariation = true,
                    Currency = property.Currency ?? "YER"
                };
            }
            else if (property.StarRating >= 3)
            {
                // فنادق 3 نجوم: أسعار متوسطة
                return new PricingStrategy
                {
                    BasePrice = _random.Next(80000, 150000), // 80-150 ألف ريال
                    WeekendMultiplier = 1.2m,
                    HolidayMultiplier = 1.4m,
                    SeasonalVariation = true,
                    Currency = property.Currency ?? "YER"
                };
            }
            else
            {
                // شقق وفنادق اقتصادية
                return new PricingStrategy
                {
                    BasePrice = _random.Next(40000, 80000), // 40-80 ألف ريال
                    WeekendMultiplier = 1.1m,
                    HolidayMultiplier = 1.2m,
                    SeasonalVariation = false,
                    Currency = property.Currency ?? "YER"
                };
            }
        }

        /// <summary>
        /// حساب السعر بناءً على الاستراتيجية
        /// </summary>
        private PriceInfo CalculatePrice(
            PricingStrategy strategy, 
            bool isWeekend, 
            bool isHoliday,
            DateTime date)
        {
            decimal basePrice = strategy.BasePrice;
            string priceType = "Base";
            string pricingTier = "Normal";
            decimal percentageChange = 0;

            // تطبيق التغيرات الموسمية
            if (strategy.SeasonalVariation)
            {
                var month = date.Month;
                // الصيف (يونيو-أغسطس): طلب أقل، خصم
                if (month >= 6 && month <= 8)
                {
                    basePrice *= 0.85m;
                    percentageChange = -15;
                    pricingTier = "Discount";
                    priceType = "Seasonal";
                }
                // الشتاء (ديسمبر-فبراير): طلب مرتفع
                else if (month == 12 || month <= 2)
                {
                    basePrice *= 1.15m;
                    percentageChange = 15;
                    pricingTier = "High";
                    priceType = "Seasonal";
                }
            }

            // تطبيق زيادة العطلات والويكند
            if (isHoliday)
            {
                basePrice *= strategy.HolidayMultiplier;
                percentageChange = (strategy.HolidayMultiplier - 1) * 100;
                priceType = "Holiday";
                pricingTier = "Peak";
            }
            else if (isWeekend)
            {
                basePrice *= strategy.WeekendMultiplier;
                percentageChange = (strategy.WeekendMultiplier - 1) * 100;
                priceType = "Weekend";
                pricingTier = "High";
            }

            // تقريب السعر
            basePrice = Math.Round(basePrice / 1000) * 1000;

            return new PriceInfo
            {
                Amount = basePrice,
                Type = priceType,
                Tier = pricingTier,
                PercentageChange = percentageChange,
                MinPrice = basePrice * 0.8m,
                MaxPrice = basePrice * 1.2m
            };
        }

        /// <summary>
        /// التحقق من العطلات اليمنية
        /// </summary>
        private bool IsYemeniHoliday(DateTime date)
        {
            // عطلات ثابتة
            if (date.Month == 9 && date.Day == 26) return true;  // 26 سبتمبر
            if (date.Month == 10 && date.Day == 14) return true; // 14 أكتوبر
            if (date.Month == 11 && date.Day == 30) return true; // 30 نوفمبر
            if (date.Month == 5 && date.Day == 22) return true;  // 22 مايو

            // عطلات متغيرة (تقريبية - يجب تحديثها سنوياً)
            // عيد الفطر (تقريبياً: 10-13 أبريل 2024)
            if (date.Month == 4 && date.Day >= 10 && date.Day <= 13) return true;
            
            // عيد الأضحى (تقريبياً: 16-19 يونيو 2024)
            if (date.Month == 6 && date.Day >= 16 && date.Day <= 19) return true;

            return false;
        }

        /// <summary>
        /// فئة مساعدة لاستراتيجية التسعير
        /// </summary>
        private class PricingStrategy
        {
            public decimal BasePrice { get; set; }
            public decimal WeekendMultiplier { get; set; }
            public decimal HolidayMultiplier { get; set; }
            public bool SeasonalVariation { get; set; }
            public string Currency { get; set; } = "YER";
        }

        /// <summary>
        /// فئة مساعدة لمعلومات السعر
        /// </summary>
        private class PriceInfo
        {
            public decimal Amount { get; set; }
            public string Type { get; set; } = "Base";
            public string Tier { get; set; } = "Normal";
            public decimal PercentageChange { get; set; }
            public decimal MinPrice { get; set; }
            public decimal MaxPrice { get; set; }
        }
        
        /// <summary>
        /// ✅ تحويل السعر من عملة لأخرى
        /// Convert price from source currency to target currency
        /// </summary>
        /// <param name="amount">المبلغ</param>
        /// <param name="fromCurrency">العملة المصدر</param>
        /// <param name="toCurrency">العملة الهدف</param>
        /// <returns>المبلغ المُحول</returns>
        private decimal ConvertPriceToTargetCurrency(
            decimal amount, 
            string fromCurrency, 
            string toCurrency)
        {
            // إذا كانت نفس العملة، لا داعي للتحويل
            if (fromCurrency == toCurrency)
                return amount;
            
            // ━━━ جدول أسعار الصرف (نفس القيم في جدول Currencies) ━━━
            var exchangeRates = new Dictionary<string, decimal>
            {
                { "YER", 1.0m },      // العملة الأساسية
                { "USD", 250m },      // 1 USD = 250 YER
                { "SAR", 66.67m },    // 1 SAR = 66.67 YER
                { "EUR", 270m },      // 1 EUR = 270 YER
                { "GBP", 312.5m }     // 1 GBP = 312.5 YER
            };
            
            // الحصول على معدلات التحويل
            if (!exchangeRates.TryGetValue(fromCurrency, out var fromRate))
                fromRate = 1.0m;
            
            if (!exchangeRates.TryGetValue(toCurrency, out var toRate))
                toRate = 1.0m;
            
            // التحويل: amount → YER → target
            // مثال: 1,000 USD → YER
            // Step 1: 1,000 USD × 250 = 250,000 YER
            // Step 2: 250,000 YER ÷ 1 = 250,000 YER ✅
            var amountInYER = amount * fromRate;
            var amountInTarget = amountInYER / toRate;
            
            // تقريب حسب العملة
            if (toCurrency == "YER")
                return Math.Round(amountInTarget / 1000) * 1000; // تقريب لأقرب ألف
            else
                return Math.Round(amountInTarget, 2); // تقريب لرقمين عشريين
        }
    }
}
