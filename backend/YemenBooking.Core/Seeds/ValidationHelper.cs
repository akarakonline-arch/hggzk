using System;
using System.Collections.Generic;
using System.Linq;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;

namespace YemenBooking.Core.Seeds
{
    /// <summary>
    /// مساعد للتحقق من القوانين والقيود عند توليد البيانات
    /// Validation helper for seeding rules and constraints
    /// </summary>
    public static class ValidationHelper
    {
        /// <summary>
        /// التحقق من إمكانية إنشاء حجز للوحدة في الفترة المحددة
        /// </summary>
        public static bool CanCreateBooking(
            Guid unitId,
            DateTime checkIn,
            DateTime checkOut,
            List<DailyUnitSchedule> existingSchedules,
            List<Booking> existingBookings)
        {
            // التحقق من عدم وجود حجوزات متداخلة
            var hasConflictingBooking = existingBookings.Any(b =>
                b.UnitId == unitId &&
                b.Status != BookingStatus.Cancelled &&
                b.CheckIn < checkOut &&
                b.CheckOut > checkIn);

            if (hasConflictingBooking) return false;

            // التحقق من الجداول اليومية
            var relevantSchedules = existingSchedules
                .Where(s => s.UnitId == unitId &&
                           s.Date >= checkIn.Date &&
                           s.Date < checkOut.Date)
                .ToList();

            // التحقق من عدم وجود أيام محجوزة أو محظورة
            var hasUnavailableDays = relevantSchedules.Any(s =>
                s.Status != "Available");

            return !hasUnavailableDays;
        }

        /// <summary>
        /// التحقق من إمكانية إنشاء مردود بناءً على سياسة العقار
        /// </summary>
        public static bool CanCreateRefund(
            Booking booking,
            List<PropertyPolicy> policies,
            DateTime cancellationDate)
        {
            // الحصول على سياسة الإلغاء
            var cancellationPolicy = policies.FirstOrDefault(p =>
                p.PropertyId == booking.Unit.PropertyId &&
                p.Type == PolicyType.Cancellation);

            if (cancellationPolicy == null)
            {
                // لا توجد سياسة = لا يمكن الإرجاع
                return false;
            }

            // التحقق من السياسة الصارمة (لا استرداد)
            if (cancellationPolicy.RequireFullPaymentBeforeConfirmation &&
                cancellationPolicy.CancellationWindowDays == 0)
            {
                return false;
            }

            // حساب الفرق بالساعات
            var hoursBeforeCheckIn = (booking.CheckIn - cancellationDate).TotalHours;

            // التحقق من نافذة الإلغاء
            if (cancellationPolicy.MinHoursBeforeCheckIn > 0)
            {
                return hoursBeforeCheckIn >= cancellationPolicy.MinHoursBeforeCheckIn;
            }

            return true;
        }

        /// <summary>
        /// حساب نسبة الاسترداد بناءً على السياسة
        /// </summary>
        public static decimal CalculateRefundPercentage(
            Booking booking,
            PropertyPolicy cancellationPolicy,
            DateTime cancellationDate)
        {
            var hoursBeforeCheckIn = (booking.CheckIn - cancellationDate).TotalHours;
            var requiredHours = cancellationPolicy.MinHoursBeforeCheckIn;

            if (hoursBeforeCheckIn >= requiredHours)
            {
                // داخل نافذة الإلغاء المجاني
                return 100m;
            }
            else if (hoursBeforeCheckIn >= requiredHours / 2)
            {
                // نصف المدة = نصف الاسترداد
                return 50m;
            }
            else
            {
                // خارج النافذة = فقط المقدمة أو لا شيء
                return cancellationPolicy.MinimumDepositPercentage;
            }
        }

        /// <summary>
        /// التحقق من متطلبات الدفع بناءً على السياسة
        /// </summary>
        public static (bool requiresFullPayment, decimal depositPercentage) GetPaymentRequirements(
            PropertyPolicy paymentPolicy)
        {
            if (paymentPolicy == null)
            {
                return (false, 20m); // افتراضياً: 20% مقدمة
            }

            return (
                paymentPolicy.RequireFullPaymentBeforeConfirmation,
                paymentPolicy.MinimumDepositPercentage
            );
        }

        /// <summary>
        /// التحقق من صحة التواريخ
        /// </summary>
        public static bool AreDatesValid(DateTime checkIn, DateTime checkOut)
        {
            // يجب أن يكون CheckIn في المستقبل
            if (checkIn < DateTime.UtcNow.Date) return false;

            // يجب أن يكون CheckOut بعد CheckIn
            if (checkOut <= checkIn) return false;

            // الحد الأقصى للحجز 30 يوم
            if ((checkOut - checkIn).Days > 30) return false;

            return true;
        }

        /// <summary>
        /// الحصول على الأيام المتاحة للحجز
        /// </summary>
        public static List<DateTime> GetAvailableDatesForUnit(
            Guid unitId,
            DateTime startDate,
            DateTime endDate,
            List<DailyUnitSchedule> schedules)
        {
            var availableDates = new List<DateTime>();
            var currentDate = startDate.Date;

            while (currentDate < endDate.Date)
            {
                var schedule = schedules.FirstOrDefault(s =>
                    s.UnitId == unitId &&
                    s.Date == currentDate);

                if (schedule == null || schedule.Status == "Available")
                {
                    availableDates.Add(currentDate);
                }

                currentDate = currentDate.AddDays(1);
            }

            return availableDates;
        }

        /// <summary>
        /// إيجاد أول فترة متاحة للحجز
        /// </summary>
        public static (DateTime? checkIn, DateTime? checkOut) FindFirstAvailablePeriod(
            Guid unitId,
            DateTime startSearchDate,
            int nights,
            List<DailyUnitSchedule> schedules)
        {
            var currentDate = startSearchDate.Date;
            var endSearchDate = startSearchDate.AddMonths(3); // البحث في 3 أشهر قادمة
            var consecutiveAvailable = 0;
            DateTime? potentialCheckIn = null;

            while (currentDate < endSearchDate)
            {
                var schedule = schedules.FirstOrDefault(s =>
                    s.UnitId == unitId &&
                    s.Date == currentDate);

                var isAvailable = schedule == null || schedule.Status == "Available";

                if (isAvailable)
                {
                    if (consecutiveAvailable == 0)
                    {
                        potentialCheckIn = currentDate;
                    }
                    consecutiveAvailable++;

                    if (consecutiveAvailable == nights)
                    {
                        return (potentialCheckIn, currentDate.AddDays(1));
                    }
                }
                else
                {
                    consecutiveAvailable = 0;
                    potentialCheckIn = null;
                }

                currentDate = currentDate.AddDays(1);
            }

            return (null, null);
        }

        /// <summary>
        /// حساب السعر الإجمالي من الجداول اليومية
        /// </summary>
        public static decimal CalculateTotalPrice(
            Guid unitId,
            DateTime checkIn,
            DateTime checkOut,
            List<DailyUnitSchedule> schedules)
        {
            decimal totalPrice = 0;
            var currentDate = checkIn.Date;

            while (currentDate < checkOut.Date)
            {
                var schedule = schedules.FirstOrDefault(s =>
                    s.UnitId == unitId &&
                    s.Date == currentDate);

                if (schedule?.PriceAmount != null)
                {
                    totalPrice += schedule.PriceAmount.Value;
                }

                currentDate = currentDate.AddDays(1);
            }

            return totalPrice;
        }

        /// <summary>
        /// تحديد حالة الحجز المناسبة بناءً على التواريخ
        /// </summary>
        public static BookingStatus DetermineBookingStatus(DateTime checkIn, DateTime checkOut)
        {
            var now = DateTime.UtcNow;

            if (now < checkIn)
            {
                return BookingStatus.Confirmed;
            }
            else if (now >= checkIn && now < checkOut)
            {
                return BookingStatus.CheckedIn;
            }
            else
            {
                return BookingStatus.Completed;
            }
        }

        /// <summary>
        /// التحقق من إمكانية تعديل الحجز
        /// </summary>
        public static bool CanModifyBooking(
            Booking booking,
            List<PropertyPolicy> policies,
            DateTime modificationDate)
        {
            var modificationPolicy = policies.FirstOrDefault(p =>
                p.PropertyId == booking.Unit.PropertyId &&
                p.Type == PolicyType.Modification);

            if (modificationPolicy == null)
            {
                // لا توجد سياسة = لا يمكن التعديل
                return false;
            }

            var hoursBeforeCheckIn = (booking.CheckIn - modificationDate).TotalHours;
            return hoursBeforeCheckIn >= modificationPolicy.MinHoursBeforeCheckIn;
        }
    }
}
