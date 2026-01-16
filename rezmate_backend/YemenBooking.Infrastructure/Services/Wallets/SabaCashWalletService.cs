using System;
using System.Linq;
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
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Wallets.SabaCash;

namespace YemenBooking.Infrastructure.Services.Wallets
{
    /// <summary>
    /// تنفيذ خدمة محفظة سبأ كاش باستخدام تكامل YottaPay
    /// SabaCash wallet service implementation using YottaPay integration
    /// </summary>
    public class SabaCashWalletService : ISabaCashWalletService
    {
        // عميل HTTP للتواصل مع واجهة SabaCash
        private readonly HttpClient _httpClient;

        // إعدادات التطبيق للحصول على بيانات الاتصال (BaseUrl, Username, Password, TerminalId)
        private readonly IConfiguration _configuration;

        // ذاكرة مؤقتة لحفظ رمز المصادقة JWT
        private readonly IMemoryCache _cache;
        private const string TOKEN_CACHE_KEY = "SabaCash_Token";

        private readonly IPaymentRepository _paymentRepository;
        private readonly ILogger<SabaCashWalletService> _logger;

        public SabaCashWalletService(
            HttpClient httpClient,
            IConfiguration configuration,
            IMemoryCache cache,
            IPaymentRepository paymentRepository,
            ILogger<SabaCashWalletService> logger)
        {
            _httpClient = httpClient;
            _configuration = configuration;
            _cache = cache;
            _paymentRepository = paymentRepository;
            _logger = logger;

            // تهيئة عنوان الـ API وإعدادات الهيدر العامة
            _httpClient.BaseAddress = new Uri(_configuration["SabaCash:BaseUrl"]);
            if (!_httpClient.DefaultRequestHeaders.Contains("Accept-Language"))
            {
                _httpClient.DefaultRequestHeaders.Add("Accept-Language", "ar");
            }
        }

        #region SabaCash low-level HTTP helpers

        /// <summary>
        /// الحصول على رمز المصادقة من SabaCash مع تخزينه في الذاكرة المؤقتة
        /// </summary>
        private async Task<string> GetAuthTokenAsync()
        {
            if (_cache.TryGetValue(TOKEN_CACHE_KEY, out string cachedToken))
            {
                _logger.LogDebug("استخدام رمز المصادقة من الذاكرة المؤقتة لمحفظة سبأ كاش");
                return cachedToken;
            }

            try
            {
                _logger.LogInformation("بدء عملية تسجيل الدخول إلى SabaCash لمحفظة سبأ كاش");

                var loginRequest = new SabaCashLoginRequest
                {
                    Username = _configuration["SabaCash:Username"],
                    Password = _configuration["SabaCash:Password"]
                };

                var content = new StringContent(
                    JsonConvert.SerializeObject(loginRequest),
                    Encoding.UTF8,
                    "application/json");

                var response = await _httpClient.PostAsync("/api/user-ms/v1/login/", content);
                var responseContent = await response.Content.ReadAsStringAsync();

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogError("فشل تسجيل الدخول إلى SabaCash. الحالة: {Status}, المحتوى: {Content}", response.StatusCode, responseContent);
                    throw new Exception($"فشل تسجيل الدخول إلى SabaCash: {response.StatusCode}");
                }

                var loginResponse = JsonConvert.DeserializeObject<SabaCashLoginResponse>(responseContent);

                // حفظ الرمز لمدة 50 دقيقة (صلاحية 60 دقيقة تقريباً)
                _cache.Set(TOKEN_CACHE_KEY, loginResponse.Token, TimeSpan.FromMinutes(50));

                _logger.LogInformation("تم تسجيل الدخول بنجاح والحصول على رمز المصادقة من SabaCash");
                return loginResponse.Token;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء محاولة تسجيل الدخول إلى SabaCash لمحفظة سبأ كاش");
                throw new Exception("فشل الاتصال بخدمة الدفع الإلكتروني لمحفظة سبأ كاش", ex);
            }
        }

        /// <summary>
        /// استدعاء API لإنشاء عملية دفع جديدة في SabaCash
        /// </summary>
        private async Task<SabaCashPaymentResponse> CreatePaymentAsync(
            string customerWallet,
            decimal amount,
            string note)
        {
            try
            {
                _logger.LogInformation("بدء إنشاء عملية دفع عبر سبأ كاش: المحفظة={Wallet}, المبلغ={Amount}", customerWallet, amount);

                if (string.IsNullOrEmpty(customerWallet) || !customerWallet.StartsWith("7") || customerWallet.Length != 9)
                {
                    throw new ArgumentException("رقم المحفظة غير صحيح. يجب أن يبدأ بـ 7 ويتكون من 9 أرقام");
                }

                if (amount <= 0)
                {
                    throw new ArgumentException("المبلغ يجب أن يكون أكبر من صفر");
                }

                var token = await GetAuthTokenAsync();
                _httpClient.DefaultRequestHeaders.Authorization =
                    new System.Net.Http.Headers.AuthenticationHeaderValue("bearer", token);

                var paymentRequest = new SabaCashPaymentRequest
                {
                    Source = new SourceInfo
                    {
                        Code = customerWallet,
                        CurrencyId = "1" // ريال يمني
                    },
                    Beneficiary = new BeneficiaryInfo
                    {
                        Terminal = _configuration["SabaCash:TerminalId"],
                        CurrencyId = "1"
                    },
                    Amount = amount.ToString("F0"),
                    AmountCurrencyId = "1",
                    Note = note ?? $"عملية دفع بتاريخ {DateTime.Now:yyyy-MM-dd HH:mm}"
                };

                var content = new StringContent(
                    JsonConvert.SerializeObject(paymentRequest),
                    Encoding.UTF8,
                    "application/json");

                var response = await _httpClient.PostAsync(
                    "/api/accounts/v1/adjustment/onLinePayment",
                    content);

                var responseContent = await response.Content.ReadAsStringAsync();

                if (!response.IsSuccessStatusCode)
                {
                    var errorResponse = JsonConvert.DeserializeObject<SabaCashErrorResponse>(responseContent);
                    var errorMessage = errorResponse?.Errors?.SubErrors?.FirstOrDefault()?.Message;

                    if (errorMessage?.Contains("sufficient balance") == true)
                    {
                        errorMessage = "الرصيد غير كافي لإتمام العملية";
                    }
                    else if (errorMessage?.Contains("not exists") == true)
                    {
                        errorMessage = "رقم المحفظة غير مسجل في النظام";
                    }
                    else if (string.IsNullOrEmpty(errorMessage))
                    {
                        errorMessage = "حدث خطأ في إنشاء عملية الدفع";
                    }

                    _logger.LogError("فشل إنشاء عملية الدفع عبر سبأ كاش: {Content}", responseContent);
                    throw new Exception(errorMessage);
                }

                var paymentResponse = JsonConvert.DeserializeObject<SabaCashPaymentResponse>(responseContent);
                _logger.LogInformation("تم إنشاء عملية الدفع بنجاح عبر سبأ كاش. AdjustmentId={AdjId}, TransactionId={TxnId}",
                    paymentResponse.Adjustment.Id,
                    paymentResponse.Adjustment.TransactionId);

                return paymentResponse;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في إنشاء عملية الدفع عبر سبأ كاش");
                throw;
            }
        }

        /// <summary>
        /// استدعاء API لتأكيد عملية الدفع باستخدام OTP
        /// </summary>
        private async Task<SabaCashConfirmResponse> ConfirmPaymentInternalAsync(
            string adjustmentId,
            string otp,
            string note)
        {
            try
            {
                _logger.LogInformation("بدء تأكيد عملية الدفع سبأ كاش: AdjustmentId={AdjId}", adjustmentId);

                if (string.IsNullOrEmpty(adjustmentId))
                {
                    throw new ArgumentException("معرف العملية مطلوب");
                }

                if (string.IsNullOrEmpty(otp) || otp.Length != 4)
                {
                    throw new ArgumentException("رمز التحقق يجب أن يتكون من 4 أرقام");
                }

                var token = await GetAuthTokenAsync();
                _httpClient.DefaultRequestHeaders.Authorization =
                    new System.Net.Http.Headers.AuthenticationHeaderValue("bearer", token);

                var confirmRequest = new SabaCashConfirmRequest
                {
                    Id = adjustmentId,
                    Otp = otp,
                    Note = note ?? "تأكيد عملية الدفع"
                };

                var content = new StringContent(
                    JsonConvert.SerializeObject(confirmRequest),
                    Encoding.UTF8,
                    "application/json");

                var request = new HttpRequestMessage(HttpMethod.Patch,
                    "/api/accounts/v1/adjustment/onLinePayment")
                {
                    Content = content
                };

                var response = await _httpClient.SendAsync(request);
                var responseContent = await response.Content.ReadAsStringAsync();

                if (!response.IsSuccessStatusCode)
                {
                    var errorResponse = JsonConvert.DeserializeObject<SabaCashErrorResponse>(responseContent);
                    var errorMessage = errorResponse?.Errors?.SubErrors?.FirstOrDefault()?.Message;

                    if (errorMessage?.Contains("Invalid OTP") == true)
                    {
                        errorMessage = "رمز التحقق غير صحيح";
                    }
                    else if (errorMessage?.Contains("expired") == true)
                    {
                        errorMessage = "انتهت صلاحية العملية. يرجى إعادة المحاولة";
                    }
                    else if (errorMessage?.Contains("already processed") == true)
                    {
                        errorMessage = "تمت معالجة هذه العملية مسبقاً";
                    }
                    else if (string.IsNullOrEmpty(errorMessage))
                    {
                        errorMessage = "فشل تأكيد عملية الدفع";
                    }

                    _logger.LogError("فشل تأكيد عملية الدفع عبر سبأ كاش: {Content}", responseContent);
                    throw new Exception(errorMessage);
                }

                var confirmResponse = JsonConvert.DeserializeObject<SabaCashConfirmResponse>(responseContent);
                _logger.LogInformation("تم تأكيد عملية الدفع عبر سبأ كاش. النتيجة={Completed}",
                    confirmResponse.Completed ? "نجحت" : "فشلت");

                return confirmResponse;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في تأكيد عملية الدفع عبر سبأ كاش");
                throw;
            }
        }

        /// <summary>
        /// استدعاء API لإرجاع مبلغ (Refund) عبر سبأ كاش
        /// </summary>
        private async Task<SabaCashPaymentResponse> RefundPaymentInternalAsync(
            string originalAdjustmentId,
            string customerWallet,
            decimal amount,
            string transactionId,
            string note)
        {
            try
            {
                _logger.LogInformation("بدء عملية إرجاع عبر سبأ كاش: OriginalAdjId={AdjId}, Amount={Amount}", originalAdjustmentId, amount);

                if (string.IsNullOrEmpty(originalAdjustmentId))
                {
                    throw new ArgumentException("معرف العملية الأصلية مطلوب");
                }

                if (string.IsNullOrEmpty(customerWallet) || !customerWallet.StartsWith("7") || customerWallet.Length != 9)
                {
                    throw new ArgumentException("رقم محفظة العميل غير صحيح");
                }

                if (amount <= 0)
                {
                    throw new ArgumentException("مبلغ الإرجاع يجب أن يكون أكبر من صفر");
                }

                if (string.IsNullOrEmpty(transactionId))
                {
                    throw new ArgumentException("رقم المعاملة الأصلية مطلوب");
                }

                var token = await GetAuthTokenAsync();
                _httpClient.DefaultRequestHeaders.Authorization =
                    new System.Net.Http.Headers.AuthenticationHeaderValue("bearer", token);

                var refundRequest = new SabaCashRefundRequest
                {
                    Id = originalAdjustmentId,
                    Source = new RefundSourceInfo
                    {
                        CurrencyId = "1",
                        IsTerminal = true
                    },
                    Beneficiary = new RefundBeneficiaryInfo
                    {
                        Code = customerWallet,
                        CurrencyId = "1"
                    },
                    Amount = amount.ToString("F0"),
                    AmountCurrencyId = "1",
                    TransactionId = transactionId,
                    Note = note ?? $"إرجاع مبلغ - {DateTime.Now:yyyy-MM-dd HH:mm}"
                };

                var content = new StringContent(
                    JsonConvert.SerializeObject(refundRequest),
                    Encoding.UTF8,
                    "application/json");

                var response = await _httpClient.PostAsync(
                    "/api/accounts/v1/adjustment/onlineMoneyReturn",
                    content);

                var responseContent = await response.Content.ReadAsStringAsync();

                if (!response.IsSuccessStatusCode)
                {
                    var errorResponse = JsonConvert.DeserializeObject<SabaCashErrorResponse>(responseContent);
                    var errorMessage = errorResponse?.Errors?.SubErrors?.FirstOrDefault()?.Message;

                    if (errorMessage?.Contains("sufficient balance") == true)
                    {
                        errorMessage = "رصيد حساب التاجر غير كافي لإرجاع المبلغ";
                    }
                    else if (errorMessage?.Contains("not completed") == true)
                    {
                        errorMessage = "لا يمكن إرجاع مبلغ عملية غير مكتملة";
                    }
                    else if (errorMessage?.Contains("conflict") == true)
                    {
                        errorMessage = "بيانات العملية لا تتطابق مع العملية الأصلية";
                    }
                    else if (string.IsNullOrEmpty(errorMessage))
                    {
                        errorMessage = "فشلت عملية الإرجاع";
                    }

                    _logger.LogError("فشلت عملية الإرجاع عبر سبأ كاش: {Content}", responseContent);
                    throw new Exception(errorMessage);
                }

                var refundResponse = JsonConvert.DeserializeObject<SabaCashPaymentResponse>(responseContent);
                _logger.LogInformation("تمت عملية الإرجاع بنجاح عبر سبأ كاش. AdjustmentId={AdjId}",
                    refundResponse.Adjustment.Id);

                return refundResponse;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في معالجة عملية الإرجاع عبر سبأ كاش");
                throw;
            }
        }

        #endregion

        /// <inheritdoc />
        public async Task<PaymentResult> InitiatePaymentAsync(Booking booking, decimal amount, CancellationToken cancellationToken = default)
        {
            // ملاحظة: هذه الطبقة تغلف استدعاء CreatePaymentAsync الخاص بـ SabaCash
            // ولا تقوم بحفظ كيان Payment بنفسها، بل تعيد النتيجة للهاندلر الأعلى.
            try
            {
                _logger.LogInformation("بدء تهيئة عملية دفع سبأ كاش للحجز {BookingId}", booking.Id);

                var note = $"دفع حجز رقم {booking.Id}";
                var response = await CreatePaymentAsync(
                    customerWallet: booking.User?.Phone ?? string.Empty,
                    amount: amount,
                    note: note);

                // هنا نعيد PaymentResult بشكل مبسط؛ الربط الكامل (AdjustmentId/TransactionId)
                // سيتم في مستوى أعلى داخل الهاندلر عند حفظ كيان الدفع.
                return new PaymentResult
                {
                    IsSuccess = response != null,
                    TransactionId = response?.Adjustment?.TransactionId ?? string.Empty,
                    Message = response != null
                        ? "تم إنشاء عملية الدفع عبر سبأ كاش وإرسال رمز التحقق إلى رقم هاتف العميل"
                        : "فشل في إنشاء عملية الدفع عبر سبأ كاش",
                    Status = Core.Enums.PaymentStatus.Pending,
                    ProcessedAmount = amount,
                    Fees = 0,
                    ProcessedAt = DateTime.UtcNow,
                    GatewayTransactionId = response?.Adjustment?.Id.ToString() ?? string.Empty
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء تهيئة عملية دفع سبأ كاش للحجز {BookingId}", booking.Id);
                return new PaymentResult
                {
                    IsSuccess = false,
                    TransactionId = string.Empty,
                    Message = ex.Message,
                    Status = Core.Enums.PaymentStatus.Failed,
                    ProcessedAmount = 0,
                    Fees = 0,
                    ProcessedAt = DateTime.UtcNow
                };
            }
        }

        /// <inheritdoc />
        public async Task<PaymentResult> ConfirmPaymentAsync(Payment payment, string otp, CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation("بدء تأكيد عملية دفع سبأ كاش للدفعة {PaymentId}", payment.Id);

                // في هذه النسخة المبدئية نفترض أن معرف العملية (AdjustmentId)
                // مخزن داخل GatewayTransactionId أو حقل مشابه في كيان Payment
                var adjustmentId = payment.GatewayTransactionId;

                var confirmResponse = await ConfirmPaymentInternalAsync(
                    adjustmentId: adjustmentId,
                    otp: otp,
                    note: "تأكيد عملية دفع سبأ كاش");

                var isCompleted = confirmResponse?.Completed == true;

                if (isCompleted)
                {
                    payment.Status = Core.Enums.PaymentStatus.Successful;
                    payment.TransactionId = confirmResponse.TransactionId;
                    payment.ProcessedAt = DateTime.UtcNow;
                }

                await _paymentRepository.UpdateAsync(payment, cancellationToken);

                return new PaymentResult
                {
                    IsSuccess = isCompleted,
                    TransactionId = confirmResponse?.TransactionId ?? string.Empty,
                    Message = isCompleted ? "تم تأكيد عملية الدفع بنجاح" : "فشل تأكيد عملية الدفع",
                    Status = isCompleted ? Core.Enums.PaymentStatus.Successful : Core.Enums.PaymentStatus.Failed,
                    ProcessedAmount = payment.Amount.Amount,
                    Fees = 0,
                    ProcessedAt = DateTime.UtcNow
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء تأكيد عملية دفع سبأ كاش للدفعة {PaymentId}", payment.Id);
                return new PaymentResult
                {
                    IsSuccess = false,
                    TransactionId = string.Empty,
                    Message = ex.Message,
                    Status = Core.Enums.PaymentStatus.Failed,
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
            try
            {
                _logger.LogInformation(
                    "بدء استرداد مبلغ عبر سبأ كاش للدفعة {PaymentId} بمبلغ {Amount}",
                    payment.Id,
                    refundAmount);

                var originalAdjustmentId = payment.GatewayTransactionId;
                if (string.IsNullOrWhiteSpace(originalAdjustmentId))
                {
                    throw new InvalidOperationException("معرف العملية الأصلية (AdjustmentId) غير متوفر في الدفعة");
                }

                var customerWallet = booking.User?.Phone;
                if (string.IsNullOrWhiteSpace(customerWallet))
                {
                    throw new InvalidOperationException("رقم محفظة العميل غير معروف. يرجى التأكد من وجود رقم هاتف مفعّل للمستخدم");
                }

                var originalTxnId = string.IsNullOrWhiteSpace(payment.TransactionId)
                    ? originalAdjustmentId
                    : payment.TransactionId;

                var refundResponse = await RefundPaymentInternalAsync(
                    originalAdjustmentId: originalAdjustmentId,
                    customerWallet: customerWallet,
                    amount: refundAmount,
                    transactionId: originalTxnId,
                    note: reason ?? "استرداد مبلغ عبر سبأ كاش");

                var refundId = refundResponse?.Adjustment != null
                    ? refundResponse.Adjustment.Id.ToString()
                    : string.Empty;

                _logger.LogInformation(
                    "تم إنشاء عملية استرداد عبر سبأ كاش بنجاح. RefundId={RefundId}, OriginalPaymentId={PaymentId}",
                    refundId,
                    payment.Id);

                return new RefundResult
                {
                    IsSuccess = true,
                    RefundId = refundId,
                    Message = "تم استرداد المبلغ عبر سبأ كاش بنجاح",
                    RefundedAmount = refundAmount,
                    RefundedAt = DateTime.UtcNow
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "خطأ أثناء استرداد مبلغ عبر سبأ كاش للدفعة {PaymentId}",
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
    }
}
