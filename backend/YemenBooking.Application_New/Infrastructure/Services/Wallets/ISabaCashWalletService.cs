using System;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Application.Features.Payments.Services;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Infrastructure.Services.Wallets
{
    /// <summary>
    /// خدمة منطق الأعمال الخاصة بمحفظة سبأ كاش
    /// Business service for SabaCash wallet payments (via YottaPay)
    /// </summary>
    public interface ISabaCashWalletService
    {
        /// <summary>
        /// تهيئة عملية دفع جديدة عبر سبأ كاش (إنشاء عملية في YottaPay وإرسال OTP للعميل)
        /// Initiate a new SabaCash payment (create adjustment in YottaPay and send OTP to customer)
        /// </summary>
        /// <param name="booking">كيان الحجز المرتبط بالدفع</param>
        /// <param name="amount">المبلغ المطلوب دفعه</param>
        /// <param name="cancellationToken">رمز الإلغاء</param>
        /// <returns>نتيجة معالجة الدفع (عادة بحالة Pending في هذه المرحلة)</returns>
        Task<PaymentResult> InitiatePaymentAsync(Booking booking, decimal amount, CancellationToken cancellationToken = default);

        /// <summary>
        /// تأكيد عملية دفع سبأ كاش باستخدام رمز OTP المرسل للعميل
        /// Confirm an existing SabaCash payment using OTP sent to the customer
        /// </summary>
        /// <param name="payment">كيان الدفع الموجود في النظام</param>
        /// <param name="otp">رمز التحقق المكون من 4 أرقام</param>
        /// <param name="cancellationToken">رمز الإلغاء</param>
        /// <returns>نتيجة معالجة الدفع بعد التأكيد</returns>
        Task<PaymentResult> ConfirmPaymentAsync(Payment payment, string otp, CancellationToken cancellationToken = default);

        /// <summary>
        /// استرداد مبلغ لعملية دفع تمت عبر محفظة سبأ كاش
        /// Refund an amount for a payment processed via SabaCash wallet
        /// </summary>
        /// <param name="payment">كيان الدفعة الأصلية</param>
        /// <param name="booking">كيان الحجز المرتبط بالدفعة (يُستخدم للحصول على محفظة العميل)</param>
        /// <param name="refundAmount">المبلغ المطلوب استرداده</param>
        /// <param name="reason">سبب الاسترداد كما سيظهر في YottaPay</param>
        /// <param name="cancellationToken">رمز الإلغاء</param>
        /// <returns>نتيجة عملية الاسترداد</returns>
        Task<RefundResult> RefundAsync(
            Payment payment,
            Booking booking,
            decimal refundAmount,
            string reason,
            CancellationToken cancellationToken = default);
    }
}
