using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Payments;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.Json;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Enums;
using System.Text.RegularExpressions;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Features.AuditLog.Services;
using System.Linq;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Payments.Commands.ProcessPayment;
using YemenBooking.Application.Features.Payments.DTOs;
using YemenBooking.Application.Features.Payments.Services;
using YemenBooking.Application.Features.Units.Services;
using YemenBooking.Application.Infrastructure.Services.Wallets;

namespace YemenBooking.Application.Features.Payments.Commands.ProcessPayment;

/// <summary>
/// معالج أمر معالجة الدفع
/// Handler for process payment command
/// </summary>
public class ProcessPaymentCommandHandler : IRequestHandler<ProcessPaymentCommand, ResultDto<ProcessPaymentResponse>>
{
    private readonly IBookingRepository _bookingRepository;
    private readonly IPaymentRepository _paymentRepository;
    private readonly ILogger<ProcessPaymentCommandHandler> _logger;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;
    private readonly ICurrencySettingsService _currencySettingsService;
    private readonly IAvailabilityService _availabilityService;
    private readonly ISabaCashWalletService _sabaCashWalletService;
    private readonly IJwaliWalletService _jwaliWalletService;

    /// <summary>
    /// منشئ معالج أمر معالجة الدفع
    /// Constructor for process payment command handler
    /// </summary>
    /// <param name="bookingRepository">مستودع الحجوزات</param>
    /// <param name="paymentRepository">مستودع المدفوعات</param>
    /// <param name="logger">مسجل الأحداث</param>
    public ProcessPaymentCommandHandler(
        IBookingRepository bookingRepository,
        IPaymentRepository paymentRepository,
        ILogger<ProcessPaymentCommandHandler> logger,
        IAuditService auditService,
        ICurrentUserService currentUserService,
        ICurrencySettingsService currencySettingsService,
        IAvailabilityService availabilityService,
        ISabaCashWalletService sabaCashWalletService,
        IJwaliWalletService jwaliWalletService)
    {
        _bookingRepository = bookingRepository;
        _paymentRepository = paymentRepository;
        _logger = logger;
        _auditService = auditService;
        _currentUserService = currentUserService;
        _currencySettingsService = currencySettingsService;
        _availabilityService = availabilityService;
        _sabaCashWalletService = sabaCashWalletService;
        _jwaliWalletService = jwaliWalletService;
    }

    /// <summary>
    /// معالجة أمر معالجة الدفع
    /// Handle process payment command
    /// </summary>
    /// <param name="request">طلب معالجة الدفع</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة العملية</returns>
    public async Task<ResultDto<YemenBooking.Application.Features.Payments.DTOs.ProcessPaymentResponse>> Handle(ProcessPaymentCommand request, CancellationToken cancellationToken)
    {
        try
        {
            ResultDto<ProcessPaymentResponse> result = await SimulateSuccessfulPaymentAsync(request, cancellationToken);
            return result;
            _logger.LogInformation("بدء عملية معالجة الدفع للحجز: {BookingId}", request.BookingId);

            // التحقق من صحة البيانات المدخلة
            var validationResult = ValidateRequest(request);
            if (!validationResult.IsSuccess)
            {
                return validationResult;
            }

            // البحث عن الحجز
            var booking = await _bookingRepository.GetByIdAsync(request.BookingId, cancellationToken);
            if (booking == null)
            {
                _logger.LogWarning("لم يتم العثور على الحجز: {BookingId}", request.BookingId);
                return ResultDto<ProcessPaymentResponse>.Failed("الحجز غير موجود", "BOOKING_NOT_FOUND");
            }

            // التحقق من صحة المبلغ (عدد المنازل العشرية)
            if (decimal.Round(request.Amount.Amount, 2) != request.Amount.Amount)
            {
                return ResultDto<ProcessPaymentResponse>.Failed("عدد المنازل العشرية للمبلغ يجب ألا يتجاوز رقمين", "AMOUNT_PRECISION");
            }

            // منع الدفع إذا كان الحجز مفوّتاً (اليوم بعد تاريخ الوصول)
            var userToday = (await _currentUserService.ConvertFromUtcToUserLocalAsync(DateTime.UtcNow)).Date;
            var checkInLocal = (await _currentUserService.ConvertFromUtcToUserLocalAsync(booking.CheckIn)).Date;
            if (checkInLocal < userToday &&  // اليوم بعد تاريخ الوصول (وليس مساوياً)
                booking.Status != BookingStatus.Cancelled &&
                booking.Status != BookingStatus.Completed &&
                booking.Status != BookingStatus.CheckedIn)
            {
                _logger.LogWarning("محاولة دفع لحجز مفوّت: {BookingId}", request.BookingId);
                return ResultDto<ProcessPaymentResponse>.Failed(
                    "لا يمكن إتمام الدفع لأن وقت الوصول المحدد للحجز قد انقضى.",
                    "BOOKING_MISSED");
            }

            // التحقق من أن العملة مطابقة لعملة الحجز
            var paymentCurrency = request.Amount.Currency ?? booking.TotalPrice.Currency;
            if (!string.Equals(paymentCurrency, booking.TotalPrice.Currency, StringComparison.OrdinalIgnoreCase))
            {
                return ResultDto<ProcessPaymentResponse>.Failed($"العملة المستخدمة ({paymentCurrency}) يجب أن تطابق عملة الحجز ({booking.TotalPrice.Currency})", "CURRENCY_MISMATCH");
            }

            // التحقق من أن العملة مدعومة ضمن إعدادات النظام
            var currencies = await _currencySettingsService.GetCurrenciesAsync(cancellationToken);
            var isSupported = currencies.Any(c => string.Equals(c.Code, booking.TotalPrice.Currency, StringComparison.OrdinalIgnoreCase));
            if (!isSupported)
            {
                return ResultDto<ProcessPaymentResponse>.Failed("العملة غير مدعومة في إعدادات النظام", "UNSUPPORTED_CURRENCY");
            }

            // التحقق من حالة الحجز
            if (booking.Status != BookingStatus.Pending)
            {
                _logger.LogWarning("محاولة دفع لحجز غير في حالة الانتظار: {BookingId}, Status: {Status}", 
                    request.BookingId, booking.Status);
                return ResultDto<ProcessPaymentResponse>.Failed("الحجز غير قابل للدفع في الحالة الحالية", "BOOKING_NOT_PAYABLE");
            }

            // التحقق من توفر الوحدة للفترة قبل إتمام الدفع
            var isAvailable = await _availabilityService.CheckAvailabilityAsync(
                booking.UnitId,
                booking.CheckIn,
                booking.CheckOut,
                booking.Id);

            if (!isAvailable)
            {
                _logger.LogWarning(
                    "فشل الدفع بسبب عدم توفر الوحدة للفترة المحددة. BookingId: {BookingId}, UnitId: {UnitId}",
                    booking.Id,
                    booking.UnitId);

                const string unavailableMessage =
                    "عذراً، الوحدة غير متاحة في التواريخ المحددة. يرجى اختيار تواريخ أخرى.";

                return ResultDto<ProcessPaymentResponse>.Failed(
                    unavailableMessage,
                    "UNIT_NOT_AVAILABLE");
            }

            // التحقق من تطابق المبلغ (بما في ذلك الخدمات الإضافية)
            var servicesTotal = booking.BookingServices?.Sum(bs => bs.TotalPrice.Amount) ?? 0m;
            var totalAmountWithServices = booking.TotalPrice.Amount + servicesTotal;
            
            if (request.Amount.Amount != totalAmountWithServices)
            {
                _logger.LogWarning("مبلغ الدفع غير متطابق مع مبلغ الحجز. المطلوب: {BookingAmount} (أساس: {BaseAmount} + خدمات: {ServicesTotal}), المرسل: {PaymentAmount}", 
                    totalAmountWithServices, booking.TotalPrice.Amount, servicesTotal, request.Amount.Amount);
                return ResultDto<ProcessPaymentResponse>.Failed("مبلغ الدفع غير متطابق مع مبلغ الحجز", "AMOUNT_MISMATCH");
            }

            // التحقق من عدم وجود دفعة ناجحة مسبقاً
            var allPayments = await _paymentRepository.GetAllAsync(cancellationToken);
            var existingPayment = allPayments?.FirstOrDefault(p => 
                p.BookingId == request.BookingId && 
                p.Status == Core.Enums.PaymentStatus.Successful);
            if (existingPayment != null)
            {
                _logger.LogWarning("يوجد دفعة ناجحة مسبقاً للحجز: {BookingId}", request.BookingId);
                return ResultDto<ProcessPaymentResponse>.Failed("تم دفع مبلغ هذا الحجز مسبقاً", "ALREADY_PAID");
            }

            // مسار خاص لمحفظة سبأ كاش بتدفق من مرحلتين (تهيئة ثم تأكيد OTP)
            if (request.PaymentMethod == PaymentMethodEnum.SabaCashWallet)
            {
                return await HandleSabaCashWalletPaymentAsync(request, booking, cancellationToken);
            }

            // معالجة الدفع حسب طريقة الدفع
            var paymentResult = await ProcessPaymentByMethod(request, booking, cancellationToken);
            if (paymentResult == null)
            {
                _logger.LogError("فشل في معالجة الدفع للحجز: {BookingId}", request.BookingId);
                return ResultDto<ProcessPaymentResponse>.Failed("فشل في معالجة الدفع", "PAYMENT_PROCESSING_FAILED");
            }

            // حفظ معلومات الدفع في قاعدة البيانات
            if (!Enum.TryParse<PaymentMethodEnum>(request.PaymentMethod.ToString(), true, out var paymentMethodType))
            {
                _logger.LogError("طريقة الدفع غير صالحة");
                return ResultDto<ProcessPaymentResponse>.Failed("طريقة الدفع غير صالحة", "INVALID_PAYMENT_METHOD");
            }

            var payment = new YemenBooking.Core.Entities.Payment 
            {
                Id = Guid.NewGuid(),
                BookingId = request.BookingId,
                Amount = request.Amount,
                PaymentMethod = paymentMethodType, // استخدام PaymentMethodEnum مباشرة
                TransactionId = paymentResult.TransactionId ?? string.Empty,
                Status = paymentResult.Success ? Core.Enums.PaymentStatus.Successful : Core.Enums.PaymentStatus.Failed,
                ProcessedAt = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow
            };
            var savedPayment = await _paymentRepository.AddAsync(payment, cancellationToken);

            if (paymentResult.Success)
            {

                _logger.LogInformation("تم إكمال الدفع بنجاح للحجز: {BookingId}, TransactionId: {TransactionId}", 
                    request.BookingId, paymentResult.TransactionId);

                // سجل تدقيق الدفع الناجح
                var performerName = _currentUserService.Username;
                var performerId = _currentUserService.UserId;
                var notes = $"تم إتمام الدفع للحجز {request.BookingId} بنجاح بواسطة {performerName} (ID={performerId})";
                await _auditService.LogAuditAsync(
                    entityType: "Payment",
                    entityId: savedPayment.Id,
                    action: AuditAction.UPDATE,
                    oldValues: null,
                    newValues: JsonSerializer.Serialize(new { PaymentId = savedPayment.Id, BookingId = request.BookingId, Amount = request.Amount.Amount, Method = request.PaymentMethod.ToString(), TransactionId = paymentResult.TransactionId }),
                    performedBy: performerId,
                    notes: notes,
                    cancellationToken: cancellationToken);
            }
            else if (!paymentResult.Success)
            {
                _logger.LogWarning("فشل في الدفع للحجز: {BookingId}, Reason: {Message}", 
                    request.BookingId, paymentResult.Message);

                // سجل تدقيق الدفع الفاشل
                var performerName = _currentUserService.Username;
                var performerId = _currentUserService.UserId;
                var notes = $"فشل الدفع للحجز {request.BookingId} بواسطة {performerName} (ID={performerId})";
                await _auditService.LogAuditAsync(
                    entityType: "Payment",
                    entityId: savedPayment.Id,
                    action: AuditAction.UPDATE,
                    oldValues: null,
                    newValues: JsonSerializer.Serialize(new { PaymentId = savedPayment.Id, BookingId = request.BookingId, Amount = request.Amount.Amount, Method = request.PaymentMethod.ToString(), Error = paymentResult.Message }),
                    performedBy: performerId,
                    notes: notes,
                    cancellationToken: cancellationToken);
            }

            return ResultDto<ProcessPaymentResponse>.Ok(paymentResult, paymentResult.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء معالجة الدفع للحجز: {BookingId}", request.BookingId);
            return ResultDto<ProcessPaymentResponse>.Failed($"حدث خطأ أثناء معالجة الدفع: {ex.Message}", "PAYMENT_ERROR");
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate the input request
    /// </summary>
    /// <param name="request">طلب الدفع</param>
    /// <returns>نتيجة التحقق</returns>
    private ResultDto<ProcessPaymentResponse> ValidateRequest(ProcessPaymentCommand request)
    {
        if (request.BookingId == Guid.Empty)
        {
            return ResultDto<ProcessPaymentResponse>.Failed("معرف الحجز غير صالح", "INVALID_BOOKING_ID");
        }

        if (request.Amount == null || request.Amount.Amount <= 0)
        {
            return ResultDto<ProcessPaymentResponse>.Failed("مبلغ الدفع غير صالح", "INVALID_AMOUNT");
        }

        // التحقق من طريقة الدفع وبياناتها المطلوبة
        if (!Enum.TryParse<PaymentMethodEnum>(request.PaymentMethod.ToString(), true, out var paymentMethodType))
        {
            return ResultDto<ProcessPaymentResponse>.Failed("طريقة الدفع غير صالحة", "INVALID_PAYMENT_METHOD");
        }

        switch (paymentMethodType)
        {
            case PaymentMethodEnum.CreditCard:
                if (request.CardDetails == null)
                {
                    return ResultDto<ProcessPaymentResponse>.Failed("تفاصيل البطاقة مطلوبة", "CARD_DETAILS_REQUIRED");
                }
                
                var cardValidation = ValidateCardDetails(request.CardDetails);
                if (!cardValidation.IsSuccess)
                {
                    return cardValidation;
                }
                break;

            // المحافظ الرقمية المتاحة في النظام
            case PaymentMethodEnum.JwaliWallet:
            case PaymentMethodEnum.CashWallet:
            case PaymentMethodEnum.OneCashWallet:
            case PaymentMethodEnum.FloskWallet:
            case PaymentMethodEnum.JaibWallet:
                if (string.IsNullOrWhiteSpace(request.WalletId))
                {
                    return ResultDto<ProcessPaymentResponse>.Failed("معرف المحفظة الإلكترونية مطلوب", "WALLET_ID_REQUIRED");
                }
                break;

            case PaymentMethodEnum.SabaCashWallet:
                // لسبأ كاش نستخدم تدفق من مرحلتين:
                // - في طلب التهيئة: لا نرسل OTP، فقط BookingId + Amount + PaymentMethod
                // - في طلب التأكيد: نرسل OTP داخل PaymentData["otp"]

                if (request.PaymentData != null &&
                    request.PaymentData.TryGetValue("otp", out var otpObj))
                {
                    var otp = otpObj?.ToString() ?? string.Empty;
                    if (string.IsNullOrWhiteSpace(otp) || !Regex.IsMatch(otp, @"^\\d{4}$"))
                    {
                        return ResultDto<ProcessPaymentResponse>.Failed(
                            "رمز التحقق غير صالح. يجب أن يتكون من 4 أرقام",
                            "INVALID_OTP");
                    }
                }
                break;

            // طرق لا تحتاج تفاصيل إضافية
            case PaymentMethodEnum.Cash:
            case PaymentMethodEnum.Paypal:
                break;

            default:
                return ResultDto<ProcessPaymentResponse>.Failed("طريقة الدفع غير مدعومة", "UNSUPPORTED_PAYMENT_METHOD");
        }

        return ResultDto<ProcessPaymentResponse>.Ok(null, "البيانات صحيحة");
    }

    /// <summary>
    /// معالجة دفع محفظة سبأ كاش بتدفق على مرحلتين (تهيئة بدون OTP ثم تأكيد مع OTP)
    /// Handle SabaCash wallet payment with two-step flow (init then OTP confirmation)
    /// </summary>
    private async Task<ResultDto<ProcessPaymentResponse>> HandleSabaCashWalletPaymentAsync(
        ProcessPaymentCommand request,
        Booking booking,
        CancellationToken cancellationToken)
    {
        try
        {
            // استخراج رمز التحقق إن وُجد في PaymentData
            string? otp = null;
            if (request.PaymentData != null &&
                request.PaymentData.TryGetValue("otp", out var otpObj))
            {
                otp = otpObj?.ToString();
            }

            // إذا لم يوجد OTP => تهيئة العملية فقط (إرسال OTP للعميل)
            if (string.IsNullOrWhiteSpace(otp))
            {
                _logger.LogInformation(
                    "تهيئة عملية دفع سبأ كاش للحجز {BookingId} بدون OTP (المرحلة الأولى)",
                    request.BookingId);

                var initResult = await _sabaCashWalletService.InitiatePaymentAsync(
                    booking,
                    request.Amount.Amount,
                    cancellationToken);

                if (!initResult.IsSuccess)
                {
                    _logger.LogWarning(
                        "فشل تهيئة عملية دفع سبأ كاش للحجز {BookingId}: {Message}",
                        request.BookingId,
                        initResult.Message);

                    return ResultDto<ProcessPaymentResponse>.Failed(
                        initResult.Message ?? "فشل في إنشاء عملية الدفع عبر سبأ كاش",
                        "SABACASH_INIT_FAILED");
                }

                // إنشاء سجل دفع بحالة Pending وربطه بالـ AdjustmentId من سبأ كاش
                var pendingPayment = new YemenBooking.Core.Entities.Payment
                {
                    Id = Guid.NewGuid(),
                    BookingId = request.BookingId,
                    Amount = request.Amount,
                    PaymentMethod = PaymentMethodEnum.SabaCashWallet,
                    TransactionId = initResult.TransactionId ?? string.Empty,
                    GatewayTransactionId = initResult.GatewayTransactionId ?? string.Empty,
                    Status = Core.Enums.PaymentStatus.Pending,
                    PaymentDate = DateTime.UtcNow,
                    ProcessedAt = null,
                    ProcessedBy = _currentUserService.UserId,
                    CreatedAt = DateTime.UtcNow
                };

                var savedPayment = await _paymentRepository.AddAsync(pendingPayment, cancellationToken);

                // لا يتم تأكيد الحجز في هذه المرحلة؛ يبقى في حالة Pending حتى تأكيد OTP

                var response = new ProcessPaymentResponse
                {
                    TransactionId = initResult.TransactionId ?? string.Empty,
                    Success = true,
                    Message = initResult.Message ??
                              "تم إنشاء عملية الدفع عبر سبأ كاش وإرسال رمز التحقق إلى رقم هاتف العميل",
                    ProcessedAmount = initResult.ProcessedAmount,
                    Fees = initResult.Fees,
                    Currency = booking.TotalPrice.Currency,
                    ProcessedAt = initResult.ProcessedAt,
                    PaymentStatusDto = "pending"
                };

                // سجل تدقيق لعملية الدفع المعلقة
                var performerName = _currentUserService.Username;
                var performerId = _currentUserService.UserId;
                var notes =
                    $"تم إنشاء عملية دفع سبأ كاش معلّقة للحجز {request.BookingId} بواسطة {performerName} (ID={performerId})";

                await _auditService.LogAuditAsync(
                    entityType: "Payment",
                    entityId: savedPayment.Id,
                    action: AuditAction.CREATE,
                    oldValues: null,
                    newValues: JsonSerializer.Serialize(new
                    {
                        PaymentId = savedPayment.Id,
                        BookingId = request.BookingId,
                        Amount = request.Amount.Amount,
                        Method = request.PaymentMethod.ToString(),
                        TransactionId = response.TransactionId,
                        Status = "Pending"
                    }),
                    performedBy: performerId,
                    notes: notes,
                    cancellationToken: cancellationToken);

                return ResultDto<ProcessPaymentResponse>.Ok(response, response.Message);
            }

            // في حالة وجود OTP => محاولة تأكيد العملية
            _logger.LogInformation(
                "تأكيد عملية دفع سبأ كاش للحجز {BookingId} باستخدام OTP", request.BookingId);

            var payments = await _paymentRepository.GetPaymentsByBookingAsync(
                request.BookingId,
                cancellationToken);

            var sabaCashPayment = payments?
                .Where(p => p.PaymentMethod == PaymentMethodEnum.SabaCashWallet)
                .OrderByDescending(p => p.CreatedAt)
                .FirstOrDefault();

            if (sabaCashPayment == null)
            {
                _logger.LogWarning(
                    "لم يتم العثور على دفعة سبأ كاش معلّقة للحجز {BookingId}", request.BookingId);

                return ResultDto<ProcessPaymentResponse>.Failed(
                    "لا توجد عملية دفع معلّقة عبر سبأ كاش لهذا الحجز",
                    "SABACASH_PAYMENT_NOT_FOUND");
            }

            if (sabaCashPayment.Status != Core.Enums.PaymentStatus.Pending)
            {
                _logger.LogWarning(
                    "لا يمكن تأكيد دفع سبأ كاش في الحالة الحالية: {Status}",
                    sabaCashPayment.Status);

                return ResultDto<ProcessPaymentResponse>.Failed(
                    "لا يمكن تأكيد عملية سبأ كاش في الحالة الحالية",
                    "SABACASH_INVALID_STATE");
            }

            var confirmResult = await _sabaCashWalletService.ConfirmPaymentAsync(
                sabaCashPayment,
                otp!,
                cancellationToken);

            var isCompleted = confirmResult.IsSuccess &&
                              confirmResult.Status == Core.Enums.PaymentStatus.Successful;

            if (isCompleted)
            {
                _logger.LogInformation(
                    "تم تأكيد دفع سبأ كاش بنجاح للحجز {BookingId}, TransactionId: {TransactionId}",
                    request.BookingId,
                    confirmResult.TransactionId);

                var response = new ProcessPaymentResponse
                {
                    TransactionId = confirmResult.TransactionId ?? string.Empty,
                    Success = true,
                    Message = confirmResult.Message ?? "تم تأكيد عملية الدفع بنجاح",
                    ProcessedAmount = confirmResult.ProcessedAmount,
                    Fees = confirmResult.Fees,
                    Currency = booking.TotalPrice.Currency,
                    ProcessedAt = confirmResult.ProcessedAt,
                    PaymentStatusDto = "completed"
                };

                // سجل تدقيق لعملية الدفع المؤكدة
                var performerName = _currentUserService.Username;
                var performerId = _currentUserService.UserId;
                var notes =
                    $"تم تأكيد دفع سبأ كاش للحجز {request.BookingId} بنجاح بواسطة {performerName} (ID={performerId})";

                await _auditService.LogAuditAsync(
                    entityType: "Payment",
                    entityId: sabaCashPayment.Id,
                    action: AuditAction.UPDATE,
                    oldValues: null,
                    newValues: JsonSerializer.Serialize(new
                    {
                        PaymentId = sabaCashPayment.Id,
                        BookingId = request.BookingId,
                        Amount = request.Amount.Amount,
                        Method = request.PaymentMethod.ToString(),
                        TransactionId = response.TransactionId,
                        Status = "Completed"
                    }),
                    performedBy: performerId,
                    notes: notes,
                    cancellationToken: cancellationToken);

                return ResultDto<ProcessPaymentResponse>.Ok(response, response.Message);
            }

            _logger.LogWarning(
                "فشل تأكيد دفع سبأ كاش للحجز {BookingId}: {Message}",
                request.BookingId,
                confirmResult.Message);

            return ResultDto<ProcessPaymentResponse>.Failed(
                confirmResult.Message ?? "فشل في تأكيد عملية الدفع عبر سبأ كاش",
                "SABACASH_CONFIRM_FAILED");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "خطأ أثناء معالجة دفع سبأ كاش للحجز {BookingId}", request.BookingId);

            return ResultDto<ProcessPaymentResponse>.Failed(
                $"حدث خطأ أثناء معالجة دفع سبأ كاش: {ex.Message}",
                "SABACASH_ERROR");
        }
    }

    /// <summary>
    /// التحقق من صحة تفاصيل البطاقة الائتمانية
    /// Validate credit card details
    /// </summary>
    /// <param name="cardDetails">تفاصيل البطاقة</param>
    /// <returns>نتيجة التحقق</returns>
    private ResultDto<ProcessPaymentResponse> ValidateCardDetails(CardDetails cardDetails)
    {
        // التحقق من رقم البطاقة
        if (string.IsNullOrWhiteSpace(cardDetails.CardNumber))
        {
            return ResultDto<ProcessPaymentResponse>.Failed("رقم البطاقة مطلوب", "CARD_NUMBER_REQUIRED");
        }

        // إزالة المسافات والشرطات من رقم البطاقة
        var cleanCardNumber = cardDetails.CardNumber.Replace(" ", "").Replace("-", "");
        if (!Regex.IsMatch(cleanCardNumber, @"^\d{13,19}$"))
        {
            return ResultDto<ProcessPaymentResponse>.Failed("رقم البطاقة غير صالح", "INVALID_CARD_NUMBER");
        }

        // التحقق من اسم حامل البطاقة
        if (string.IsNullOrWhiteSpace(cardDetails.CardholderName))
        {
            return ResultDto<ProcessPaymentResponse>.Failed("اسم حامل البطاقة مطلوب", "CARDHOLDER_NAME_REQUIRED");
        }

        // التحقق من تاريخ انتهاء الصلاحية
        if (cardDetails.ExpiryMonth < 1 || cardDetails.ExpiryMonth > 12)
        {
            return ResultDto<ProcessPaymentResponse>.Failed("شهر انتهاء الصلاحية غير صالح", "INVALID_EXPIRY_MONTH");
        }

        var currentYear = DateTime.Now.Year;
        if (cardDetails.ExpiryYear < currentYear || cardDetails.ExpiryYear > currentYear + 20)
        {
            return ResultDto<ProcessPaymentResponse>.Failed("سنة انتهاء الصلاحية غير صالحة", "INVALID_EXPIRY_YEAR");
        }

        // التحقق من عدم انتهاء صلاحية البطاقة
        var expiryDate = new DateTime(cardDetails.ExpiryYear, cardDetails.ExpiryMonth, 1).AddMonths(1).AddDays(-1);
        if (expiryDate < DateTime.Now.Date)
        {
            return ResultDto<ProcessPaymentResponse>.Failed("البطاقة منتهية الصلاحية", "CARD_EXPIRED");
        }

        // التحقق من رمز الأمان CVV
        if (string.IsNullOrWhiteSpace(cardDetails.CVV))
        {
            return ResultDto<ProcessPaymentResponse>.Failed("رمز الأمان CVV مطلوب", "CVV_REQUIRED");
        }

        if (!Regex.IsMatch(cardDetails.CVV, @"^\d{3,4}$"))
        {
            return ResultDto<ProcessPaymentResponse>.Failed("رمز الأمان CVV غير صالح", "INVALID_CVV");
        }

        return ResultDto<ProcessPaymentResponse>.Ok(null, "تفاصيل البطاقة صحيحة");
    }

    /// <summary>
    /// معالجة الدفع حسب طريقة الدفع
    /// Process payment by payment method
    /// </summary>
    /// <param name="request">طلب الدفع</param>
    /// <param name="booking">الحجز</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة معالجة الدفع</returns>
    private async Task<ProcessPaymentResponse?> ProcessPaymentByMethod(
        ProcessPaymentCommand request, 
        dynamic booking, 
        CancellationToken cancellationToken)
    {
        if (!Enum.TryParse<PaymentMethodEnum>(request.PaymentMethod.ToString(), true, out var paymentMethodType))
        {
            _logger.LogError("طريقة الدفع غير صالحة");
            return null;
        }

        return paymentMethodType switch
        {
            // محفظة جوالي: نستخدم خدمة متخصصة تغلف استعلام الفاتورة + السحب (Cashout)
            PaymentMethodEnum.JwaliWallet => ConvertToProcessPaymentResponse(await _jwaliWalletService.ProcessBookingPaymentAsync(
                booking,
                request.Amount.Amount,
                request.PaymentData != null && request.PaymentData.TryGetValue("voucher", out var voucherObj)
                    ? voucherObj?.ToString() ?? string.Empty
                    : request.WalletId ?? string.Empty,
                booking.User?.Phone ?? string.Empty,
                cancellationToken)),

            // باقي الطرق حالياً غير مفعّلة في البوابة، يتم إرجاع رسالة واضحة
            _ => new ProcessPaymentResponse
            {
                TransactionId = string.Empty,
                Success = false,
                Message = "طريقة الدفع هذه غير مفعّلة حالياً. الطرق المتاحة: محفظة جوالي، محفظة سبأ كاش",
                ProcessedAmount = 0,
                Fees = 0,
                Currency = booking.TotalPrice.Currency,
                ProcessedAt = DateTime.UtcNow,
                PaymentStatusDto = "failed"
            }
        };
    }

    private async Task<ResultDto<ProcessPaymentResponse>> SimulateSuccessfulPaymentAsync(
        ProcessPaymentCommand request,
        CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء معالجة دفع في وضع المحاكاة للحجز: {BookingId}", request.BookingId);

            var booking = await _bookingRepository.GetByIdAsync(request.BookingId, cancellationToken);
            if (booking == null)
            {
                _logger.LogWarning("لم يتم العثور على الحجز (محاكاة): {BookingId}", request.BookingId);
                return ResultDto<ProcessPaymentResponse>.Failed("الحجز غير موجود", "BOOKING_NOT_FOUND");
            }

            if (decimal.Round(request.Amount.Amount, 2) != request.Amount.Amount)
            {
                return ResultDto<ProcessPaymentResponse>.Failed("عدد المنازل العشرية للمبلغ يجب ألا يتجاوز رقمين", "AMOUNT_PRECISION");
            }

            var paymentCurrency = request.Amount.Currency ?? booking.TotalPrice.Currency;
            if (!string.Equals(paymentCurrency, booking.TotalPrice.Currency, StringComparison.OrdinalIgnoreCase))
            {
                return ResultDto<ProcessPaymentResponse>.Failed($"العملة المستخدمة ({paymentCurrency}) يجب أن تطابق عملة الحجز ({booking.TotalPrice.Currency})", "CURRENCY_MISMATCH");
            }

            // منع الدفع في وضع المحاكاة إذا كان الحجز مفوّتاً (اليوم بعد تاريخ الوصول)
            var userToday = (await _currentUserService.ConvertFromUtcToUserLocalAsync(DateTime.UtcNow)).Date;
            var checkInLocal = (await _currentUserService.ConvertFromUtcToUserLocalAsync(booking.CheckIn)).Date;
            if (checkInLocal < userToday &&
                booking.Status != BookingStatus.Cancelled &&
                booking.Status != BookingStatus.Completed &&
                booking.Status != BookingStatus.CheckedIn)
            {
                _logger.LogWarning("محاولة دفع (محاكاة) لحجز مفوّت: {BookingId}", request.BookingId);
                return ResultDto<ProcessPaymentResponse>.Failed(
                    "لا يمكن إتمام الدفع لأن وقت الوصول المحدد للحجز قد انقضى.",
                    "BOOKING_MISSED");
            }

            if (booking.Status != BookingStatus.Pending)
            {
                _logger.LogWarning("محاولة دفع (محاكاة) لحجز غير في حالة الانتظار: {BookingId}, Status: {Status}",
                    request.BookingId, booking.Status);
                return ResultDto<ProcessPaymentResponse>.Failed("الحجز غير قابل للدفع في الحالة الحالية", "BOOKING_NOT_PAYABLE");
            }

            // التحقق من تطابق المبلغ مع مبلغ الحجز (منع دفع مبلغ أكبر أو أقل)
            // التحقق من تطابق المبلغ مع مبلغ الحجز (بما في ذلك الخدمات الإضافية - منع دفع مبلغ أكبر أو أقل)
            var servicesTotal = booking.BookingServices?.Sum(bs => bs.TotalPrice.Amount) ?? 0m;
            var totalAmountWithServices = booking.TotalPrice.Amount + servicesTotal;
            
            if (request.Amount.Amount != totalAmountWithServices)
            {
                _logger.LogWarning("مبلغ الدفع (محاكاة) غير متطابق مع مبلغ الحجز. المطلوب: {BookingAmount} (أساس: {BaseAmount} + خدمات: {ServicesTotal}), المرسل: {PaymentAmount}",
                    totalAmountWithServices, booking.TotalPrice.Amount, servicesTotal, request.Amount.Amount);
                return ResultDto<ProcessPaymentResponse>.Failed("مبلغ الدفع غير متطابق مع مبلغ الحجز", "AMOUNT_MISMATCH");
            }

            var allPayments = await _paymentRepository.GetAllAsync(cancellationToken);
            var existingPayment = allPayments?.FirstOrDefault(p =>
                p.BookingId == request.BookingId &&
                p.Status == Core.Enums.PaymentStatus.Successful);
            if (existingPayment != null)
            {
                _logger.LogWarning("يوجد دفعة ناجحة مسبقاً (محاكاة) للحجز: {BookingId}", request.BookingId);
                return ResultDto<ProcessPaymentResponse>.Failed("تم دفع مبلغ هذا الحجز مسبقاً", "ALREADY_PAID");
            }

            if (!Enum.TryParse<PaymentMethodEnum>(request.PaymentMethod.ToString(), true, out var paymentMethodType))
            {
                _logger.LogError("طريقة الدفع غير صالحة (محاكاة)");
                return ResultDto<ProcessPaymentResponse>.Failed("طريقة الدفع غير صالحة", "INVALID_PAYMENT_METHOD");
            }

            var simulatedTransactionId = $"SIM-{Guid.NewGuid():N}";

            var payment = new YemenBooking.Core.Entities.Payment
            {
                Id = Guid.NewGuid(),
                BookingId = request.BookingId,
                Amount = request.Amount,
                PaymentMethod = paymentMethodType,
                TransactionId = simulatedTransactionId,
                Status = Core.Enums.PaymentStatus.Successful,
                ProcessedAt = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow
            };

            var savedPayment = await _paymentRepository.AddAsync(payment, cancellationToken);

            var performerName = _currentUserService.Username;
            var performerId = _currentUserService.UserId;
            var notes = $"تم إتمام الدفع (وضع المحاكاة) للحجز {request.BookingId} بنجاح بواسطة {performerName} (ID={performerId})";

            await _auditService.LogAuditAsync(
                entityType: "Payment",
                entityId: savedPayment.Id,
                action: AuditAction.UPDATE,
                oldValues: null,
                newValues: JsonSerializer.Serialize(new
                {
                    PaymentId = savedPayment.Id,
                    BookingId = request.BookingId,
                    Amount = request.Amount.Amount,
                    Method = request.PaymentMethod.ToString(),
                    TransactionId = simulatedTransactionId,
                    Simulated = true
                }),
                performedBy: performerId,
                notes: notes,
                cancellationToken: cancellationToken);

            var response = new ProcessPaymentResponse
            {
                TransactionId = simulatedTransactionId,
                Success = true,
                Message = "تم إكمال الدفع بنجاح (وضع المحاكاة)",
                ProcessedAmount = request.Amount.Amount,
                Fees = 0,
                Currency = booking.TotalPrice.Currency,
                ProcessedAt = DateTime.UtcNow,
                PaymentStatusDto = "completed"
            };

            return ResultDto<ProcessPaymentResponse>.Ok(response, response.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء معالجة الدفع في وضع المحاكاة للحجز: {BookingId}", request.BookingId);
            return ResultDto<ProcessPaymentResponse>.Failed($"حدث خطأ أثناء معالجة الدفع في وضع المحاكاة: {ex.Message}", "PAYMENT_SIM_ERROR");
        }
    }

    /// <summary>
    /// تحويل PaymentResult إلى ProcessPaymentResponse
    /// </summary>
    private YemenBooking.Application.Features.Payments.DTOs.ProcessPaymentResponse? ConvertToProcessPaymentResponse(YemenBooking.Application.Features.Payments.Services.PaymentResult? paymentResult)
    {
        if (paymentResult == null)
            return null;

        return new YemenBooking.Application.Features.Payments.DTOs.ProcessPaymentResponse
        {
            TransactionId = paymentResult.TransactionId ?? string.Empty,
            Success = paymentResult.IsSuccess,
            Message = paymentResult.Message ?? string.Empty,
            ProcessedAmount = paymentResult.ProcessedAmount,
            Fees = paymentResult.Fees,
            Currency = "YER",
            ProcessedAt = paymentResult.ProcessedAt,
            PaymentStatusDto = paymentResult.IsSuccess ? "Completed" : "Failed"
        };
    }
}
