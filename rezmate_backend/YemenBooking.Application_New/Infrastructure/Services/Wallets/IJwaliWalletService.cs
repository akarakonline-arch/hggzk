using System;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Application.Features.Payments.Services;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Infrastructure.Services.Wallets
{
    /// <summary>
    /// خدمة منطق الأعمال الخاصة بمحفظة جوالي
    /// Business service for Jwali wallet payments
    /// </summary>
    public interface IJwaliWalletService
    {
        /// <summary>
        /// تنفيذ عملية دفع حجز عبر محفظة جوالي باستخدام قسيمة (Voucher)
        /// تقوم الخدمة داخلياً بتنفيذ استعلام الفاتورة ثم عملية السحب النقدي (Cashout)
        /// </summary>
        /// <param name="booking">كيان الحجز المرتبط بالدفع</param>
        /// <param name="amount">المبلغ المطلوب دفعه (يجب أن يطابق مبلغ الفاتورة)</param>
        /// <param name="voucher">كود القسيمة / الفاتورة القادم من تطبيق جوالي</param>
        /// <param name="receiverMobile">رقم جوال المستلم (عادة رقم جوال العميل)</param>
        /// <param name="cancellationToken">رمز الإلغاء</param>
        /// <returns>نتيجة معالجة الدفع عبر جوالي</returns>
        Task<PaymentResult> ProcessBookingPaymentAsync(
            Booking booking,
            decimal amount,
            string voucher,
            string receiverMobile,
            CancellationToken cancellationToken = default);

        /// <summary>
        /// استرداد مبلغ لعملية دفع تمت عبر محفظة جوالي (E-Commerce Refund)
        /// </summary>
        /// <param name="payment">كيان الدفعة الأصلية</param>
        /// <param name="booking">كيان الحجز المرتبط بالدفعة</param>
        /// <param name="refundAmount">المبلغ المطلوب استرداده</param>
        /// <param name="reason">سبب الاسترداد كما سيظهر في جوالي</param>
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
