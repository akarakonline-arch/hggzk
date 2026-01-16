using System;
using System.Net.Http;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using YemenBooking.Application.Features.Payments.Services;
using YemenBooking.Application.Infrastructure.Services.Wallets;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Wallets.Jwali;

namespace YemenBooking.Infrastructure.Services.Wallets
{
    /// <summary>
    /// تنفيذ خدمة محفظة جوالي (JwaliWallet)
    /// تغلّف استدعاءات واجهات PAYWA / PAYAG الخاصة بجوالي
    /// لاستخدامها في عمليات دفع الحجوزات والاسترداد داخل النظام.
    /// </summary>
    public class JwaliWalletService : IJwaliWalletService
    {
        // عميل HTTP للتواصل مع واجهة جوالي
        private readonly HttpClient _httpClient;

        // إعدادات التطبيق للحصول على بيانات الاتصال (BaseUrl, AgentWallet, Password, ClientID, OrgID, UserID, ExternalUser, DefaultRefundType)
        private readonly IConfiguration _configuration;

        // ذاكرة مؤقتة لحفظ رمز الوصول (AccessToken)
        private readonly IMemoryCache _cache;
        private const string TOKEN_CACHE_KEY = "Jwali_AccessToken";

        private readonly ILogger<JwaliWalletService> _logger;

        public JwaliWalletService(
            HttpClient httpClient,
            IConfiguration configuration,
            IMemoryCache cache,
            ILogger<JwaliWalletService> logger)
        {
            _httpClient = httpClient;
            _configuration = configuration;
            _cache = cache;
            _logger = logger;

            // تهيئة عنوان الـ API الأساسي لمحفظة جوالي
            // ملاحظة: يمكن أن يكون BaseUrl هو الرابط الكامل لنقطة النهاية (Endpoint)
            var baseUrl = _configuration["Jwali:BaseUrl"];
            if (string.IsNullOrWhiteSpace(baseUrl))
            {
                _logger.LogWarning("لم يتم ضبط قيمة Jwali:BaseUrl في ملف الإعدادات. لن تعمل عمليات محفظة جوالي بدون هذا الإعداد.");
            }
            else
            {
                _httpClient.BaseAddress = new Uri(baseUrl);
            }
        }

        #region Low-level helpers (Header + HTTP)

        /// <summary>
        /// إنشاء هيدر قياسي لطلب جوالي بناءً على إعدادات النظام واسم الخدمة المطلوبة
        /// </summary>
        private JwaliHeader BuildHeader(string serviceName)
        {
            return new JwaliHeader
            {
                ServiceDetail = new JwaliServiceDetail
                {
                    CorrID = Guid.NewGuid().ToString(),
                    DomainName = _configuration["Jwali:DomainName"] ?? "WalletDomain",
                    ServiceName = serviceName
                },
                SignonDetail = new JwaliSignonDetail
                {
                    ClientID = _configuration["Jwali:ClientID"] ?? string.Empty,
                    OrgID = _configuration["Jwali:OrgID"] ?? string.Empty,
                    UserID = _configuration["Jwali:UserID"] ?? string.Empty,
                    ExternalUser = _configuration["Jwali:ExternalUser"] ?? "api-user"
                },
                MessageContext = new JwaliMessageContext
                {
                    ClientDate = DateTime.UtcNow.ToString("yyyyMMddHHmm"),
                    BodyType = "Clear"
                }
            };
        }

        /// <summary>
        /// الحصول على رمز الوصول (AccessToken) من خدمة WALLETAUTHENTICATION مع تخزينه في الذاكرة المؤقتة
        /// </summary>
        private async Task<string> GetAccessTokenAsync(CancellationToken cancellationToken)
        {
            if (_cache.TryGetValue(TOKEN_CACHE_KEY, out string cachedToken) && !string.IsNullOrWhiteSpace(cachedToken))
            {
                _logger.LogDebug("استخدام رمز الوصول المخزن في الذاكرة لمحفظة جوالي");
                return cachedToken;
            }

            var agentWallet = _configuration["Jwali:AgentWallet"];
            var password = _configuration["Jwali:Password"];

            if (string.IsNullOrWhiteSpace(agentWallet) || string.IsNullOrWhiteSpace(password))
            {
                throw new InvalidOperationException("إعدادات محفظة جوالي غير مكتملة. يجب ضبط Jwali:AgentWallet و Jwali:Password في ملف الإعدادات.");
            }

            try
            {
                _logger.LogInformation("بدء عملية تسجيل الدخول إلى محفظة جوالي (PAYWA.WALLETAUTHENTICATION)");

                var loginRequest = new JwaliLoginRequest
                {
                    Header = BuildHeader("PAYWA.WALLETAUTHENTICATION"),
                    Body = new JwaliLoginBody
                    {
                        Identifier = agentWallet,
                        Password = password
                    }
                };

                var content = new StringContent(
                    JsonConvert.SerializeObject(loginRequest),
                    Encoding.UTF8,
                    "application/json");

                // ملاحظة: نفترض أن BaseAddress يشير مباشرة لنقطة النهاية الخاصة بجوالي
                var response = await _httpClient.PostAsync(string.Empty, content, cancellationToken);
                var responseContent = await response.Content.ReadAsStringAsync(cancellationToken);

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError("فشل تسجيل الدخول إلى محفظة جوالي. الحالة: {Status}, المحتوى: {Content}",
                        response.StatusCode, responseContent);
                    throw new Exception("فشل تسجيل الدخول إلى محفظة جوالي");
                }

                var loginResponse = JsonConvert.DeserializeObject<JwaliLoginResponse>(responseContent)
                                   ?? new JwaliLoginResponse();

                if (string.IsNullOrWhiteSpace(loginResponse.Access_Token))
                {
                    throw new Exception("لم يتم إرجاع رمز وصول صالح من خدمة جوالي");
                }

                // حفظ التوكن لمدة 30 دقيقة افتراضياً
                _cache.Set(TOKEN_CACHE_KEY, loginResponse.Access_Token, TimeSpan.FromMinutes(30));

                _logger.LogInformation("تم الحصول على رمز الوصول من محفظة جوالي بنجاح");
                return loginResponse.Access_Token;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء محاولة تسجيل الدخول إلى محفظة جوالي");
                throw new Exception("فشل الاتصال بخدمة محفظة جوالي", ex);
            }
        }

        /// <summary>
        /// دالة مساعدة عامة لإرسال طلب جوالي (هيدر + جسم) وإرجاع الاستجابة كنموذج strongly-typed
        /// </summary>
        private async Task<TResponse> PostJwaliAsync<TRequest, TResponse>(
            string serviceName,
            TRequest request,
            CancellationToken cancellationToken)
        {
            var json = JsonConvert.SerializeObject(request);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            _logger.LogDebug("إرسال طلب جوالي للخدمة {ServiceName}: {Payload}", serviceName, json);

            var response = await _httpClient.PostAsync(string.Empty, content, cancellationToken);
            var responseContent = await response.Content.ReadAsStringAsync(cancellationToken);

            _logger.LogDebug("استجابة جوالي للخدمة {ServiceName}: {Content}", serviceName, responseContent);

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogError("فشل استدعاء خدمة جوالي {ServiceName}. الحالة: {Status}",
                    serviceName, response.StatusCode);
                throw new Exception($"فشل استدعاء خدمة جوالي: {serviceName}");
            }

            var result = JsonConvert.DeserializeObject<TResponse>(responseContent);
            if (result == null)
            {
                throw new Exception($"فشل في تحويل استجابة خدمة جوالي: {serviceName}");
            }

            return result;
        }

        #endregion

        #region Public API - حجز عبر جوالي

        /// <inheritdoc />
        public async Task<PaymentResult> ProcessBookingPaymentAsync(
            Booking booking,
            decimal amount,
            string voucher,
            string receiverMobile,
            CancellationToken cancellationToken = default)
        {
            if (booking == null)
            {
                throw new ArgumentNullException(nameof(booking));
            }

            if (amount <= 0)
            {
                throw new ArgumentException("المبلغ يجب أن يكون أكبر من صفر", nameof(amount));
            }

            if (string.IsNullOrWhiteSpace(voucher))
            {
                throw new ArgumentException("كود القسيمة (Voucher) مطلوب لعملية جوالي", nameof(voucher));
            }

            if (string.IsNullOrWhiteSpace(receiverMobile))
            {
                throw new ArgumentException("رقم جوال المستلم مطلوب لعملية جوالي", nameof(receiverMobile));
            }

            try
            {
                _logger.LogInformation(
                    "بدء معالجة دفع حجز عبر محفظة جوالي. BookingId={BookingId}, Voucher={Voucher}",
                    booking.Id,
                    voucher);

                var agentWallet = _configuration["Jwali:AgentWallet"];
                var password = _configuration["Jwali:Password"];

                if (string.IsNullOrWhiteSpace(agentWallet) || string.IsNullOrWhiteSpace(password))
                {
                    throw new InvalidOperationException("إعدادات محفظة جوالي غير مكتملة. يجب ضبط Jwali:AgentWallet و Jwali:Password.");
                }

                // 1) الحصول على رمز الوصول
                var accessToken = await GetAccessTokenAsync(cancellationToken);

                var refId = Guid.NewGuid().ToString("N");

                // 2) استعلام الفاتورة (E-Commerce Inquiry)
                var inquiryRequest = new JwaliEcommerceInquiryRequest
                {
                    Header = BuildHeader("PAYAG.ECOMMERCEINQUIRY"),
                    Body = new JwaliEcommerceInquiryBody
                    {
                        AgentWallet = agentWallet,
                        Voucher = voucher,
                        ReceiverMobile = receiverMobile,
                        Password = password,
                        AccessToken = accessToken,
                        RefId = refId,
                        Purpose = $"Booking Payment #{booking.Id}"
                    }
                };

                var inquiryResponse = await PostJwaliAsync<JwaliEcommerceInquiryRequest, JwaliEcommerceInquiryResponse>(
                    "PAYAG.ECOMMERCEINQUIRY",
                    inquiryRequest,
                    cancellationToken);

                // التحقق من حالة الفاتورة
                var state = (inquiryResponse.State ?? string.Empty).ToUpperInvariant();
                if (state == "PENDING")
                {
                    return new PaymentResult
                    {
                        IsSuccess = false,
                        TransactionId = inquiryResponse.IssuerTrxRef,
                        Message = "الفاتورة ما زالت في حالة انتظار (PENDING) في نظام جوالي",
                        Status = PaymentStatus.Failed,
                        ProcessedAmount = 0,
                        Fees = 0,
                        ProcessedAt = DateTime.UtcNow
                    };
                }

                if (state != "ACCEPTED")
                {
                    return new PaymentResult
                    {
                        IsSuccess = false,
                        TransactionId = inquiryResponse.IssuerTrxRef,
                        Message = "لا يمكن تنفيذ العملية لأن حالة الفاتورة ليست مقبولة في نظام جوالي",
                        Status = PaymentStatus.Failed,
                        ProcessedAmount = 0,
                        Fees = 0,
                        ProcessedAt = DateTime.UtcNow
                    };
                }

                // التحقق من تطابق مبلغ الفاتورة مع مبلغ الحجز
                if (inquiryResponse.TxnAmount != amount)
                {
                    return new PaymentResult
                    {
                        IsSuccess = false,
                        TransactionId = inquiryResponse.IssuerTrxRef,
                        Message = "مبلغ الفاتورة في جوالي لا يطابق مبلغ الحجز في النظام",
                        Status = PaymentStatus.Failed,
                        ProcessedAmount = 0,
                        Fees = 0,
                        ProcessedAt = DateTime.UtcNow
                    };
                }

                // 3) تنفيذ السحب (Cashout)
                var cashoutRequest = new JwaliEcommerceCashoutRequest
                {
                    Header = BuildHeader("PAYAG.ECOMMCASHOUT"),
                    Body = new JwaliEcommerceCashoutBody
                    {
                        AgentWallet = agentWallet,
                        Voucher = voucher,
                        ReceiverMobile = receiverMobile,
                        Password = password,
                        AccessToken = accessToken,
                        RefId = refId,
                        Purpose = $"Booking Payment #{booking.Id}"
                    }
                };

                var cashoutResponse = await PostJwaliAsync<JwaliEcommerceCashoutRequest, JwaliEcommerceCashoutResponse>(
                    "PAYAG.ECOMMCASHOUT",
                    cashoutRequest,
                    cancellationToken);

                var status = (cashoutResponse.Status ?? string.Empty).ToUpperInvariant();
                var isAccepted = status == "ACCEPTED" || status == "SUCCESS";

                if (!isAccepted)
                {
                    return new PaymentResult
                    {
                        IsSuccess = false,
                        TransactionId = cashoutResponse.IssuerRef,
                        Message = "فشلت عملية السحب (Cashout) عبر محفظة جوالي",
                        Status = PaymentStatus.Failed,
                        ProcessedAmount = 0,
                        Fees = 0,
                        ProcessedAt = DateTime.UtcNow
                    };
                }

                // نجاح العملية
                return new PaymentResult
                {
                    IsSuccess = true,
                    TransactionId = cashoutResponse.IssuerRef,
                    Message = "تم تنفيذ عملية الدفع عبر محفظة جوالي بنجاح",
                    Status = PaymentStatus.Successful,
                    ProcessedAmount = amount,
                    Fees = 0,
                    ProcessedAt = DateTime.UtcNow
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "خطأ أثناء معالجة دفع حجز عبر محفظة جوالي. BookingId={BookingId}",
                    booking.Id);

                return new PaymentResult
                {
                    IsSuccess = false,
                    TransactionId = string.Empty,
                    Message = ex.Message,
                    Status = PaymentStatus.Failed,
                    ProcessedAmount = 0,
                    Fees = 0,
                    ProcessedAt = DateTime.UtcNow
                };
            }
        }

        /// <inheritdoc />
        public async Task<RefundResult> RefundAsync(
            Payment payment,
            Booking booking,
            decimal refundAmount,
            string reason,
            CancellationToken cancellationToken = default)
        {
            if (payment == null)
            {
                throw new ArgumentNullException(nameof(payment));
            }

            if (booking == null)
            {
                throw new ArgumentNullException(nameof(booking));
            }

            if (refundAmount <= 0)
            {
                throw new ArgumentException("مبلغ الاسترداد يجب أن يكون أكبر من صفر", nameof(refundAmount));
            }

            try
            {
                _logger.LogInformation(
                    "بدء استرداد مبلغ عبر محفظة جوالي. PaymentId={PaymentId}, Amount={Amount}",
                    payment.Id,
                    refundAmount);

                var agentWallet = _configuration["Jwali:AgentWallet"];
                var password = _configuration["Jwali:Password"];
                var defaultRefundType = _configuration["Jwali:DefaultRefundType"] ?? "1";

                if (string.IsNullOrWhiteSpace(agentWallet) || string.IsNullOrWhiteSpace(password))
                {
                    throw new InvalidOperationException("إعدادات محفظة جوالي غير مكتملة. يجب ضبط Jwali:AgentWallet و Jwali:Password.");
                }

                var receiverMobile = booking.User?.Phone;
                if (string.IsNullOrWhiteSpace(receiverMobile))
                {
                    throw new InvalidOperationException("رقم جوال العميل غير معروف، لا يمكن إتمام عملية استرداد جوالي.");
                }

                var issuerRef = payment.TransactionId;
                if (string.IsNullOrWhiteSpace(issuerRef))
                {
                    throw new InvalidOperationException("لا يوجد رقم مرجع (TransactionId) مخزن للدفعة الأصلية لاستخدامه في جوالي.");
                }

                var accessToken = await GetAccessTokenAsync(cancellationToken);
                var refId = Guid.NewGuid().ToString("N");

                var refundRequest = new JwaliEcommerceRefundRequest
                {
                    Header = BuildHeader("PAYAG.ECOMMERCEREFUND"),
                    Body = new JwaliEcommerceRefundBody
                    {
                        AgentWallet = agentWallet,
                        Amount = refundAmount,
                        ReceiverMobile = receiverMobile,
                        Password = password,
                        AccessToken = accessToken,
                        RefId = refId,
                        RefundType = defaultRefundType,
                        IssuerRef = issuerRef,
                        Purpose = string.IsNullOrWhiteSpace(reason) ? "Refund Booking" : reason
                    }
                };

                var refundResponse = await PostJwaliAsync<JwaliEcommerceRefundRequest, JwaliEcommerceRefundResponse>(
                    "PAYAG.ECOMMERCEREFUND",
                    refundRequest,
                    cancellationToken);

                var status = (refundResponse.Status ?? string.Empty).ToUpperInvariant();
                var isSuccess = status == "ACCEPTED" || status == "SUCCESS";

                if (!isSuccess)
                {
                    return new RefundResult
                    {
                        IsSuccess = false,
                        RefundId = refundResponse.RefId,
                        Message = "فشلت عملية استرداد المبلغ عبر محفظة جوالي",
                        RefundedAmount = 0,
                        RefundedAt = DateTime.UtcNow
                    };
                }

                return new RefundResult
                {
                    IsSuccess = true,
                    RefundId = refundResponse.RefId,
                    Message = "تم استرداد المبلغ عبر محفظة جوالي بنجاح",
                    RefundedAmount = refundAmount,
                    RefundedAt = DateTime.UtcNow
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "خطأ أثناء استرداد مبلغ عبر محفظة جوالي. PaymentId={PaymentId}",
                    payment.Id);

                return new RefundResult
                {
                    IsSuccess = false,
                    RefundId = string.Empty,
                    Message = ex.Message,
                    RefundedAmount = 0,
                    RefundedAt = DateTime.UtcNow
                };
            }
        }

        #endregion
    }
}
