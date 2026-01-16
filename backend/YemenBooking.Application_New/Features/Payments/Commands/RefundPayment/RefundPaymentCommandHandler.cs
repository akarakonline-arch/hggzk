using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Payments.DTOs;
using YemenBooking.Application.Features.Payments.Commands.PaymentEvents;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Infrastructure.Services.Wallets;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Core.Notifications;
using System.Linq;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Accounting.Services;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Payments.Services;
using YemenBooking.Application.Features.Notifications.Services;

namespace YemenBooking.Application.Features.Payments.Commands.RefundPayment;

/// <summary>
/// مُعالج أمر استرداد الدفع
/// Payment refund command handler
/// 
/// يقوم بمعالجة عملية استرداد الدفع ويشمل:
/// - التحقق من صحة البيانات المدخلة
/// - التحقق من وجود الدفع
/// - التحقق من صلاحيات المستخدم
/// - التحقق من قواعد الأعمال
/// - التحقق من حالة الدفع
/// - معالجة الاسترداد
/// - إنشاء حدث الاسترداد
/// 
/// Processes payment refund and includes:
/// - Input data validation
/// - Payment existence validation
/// - User authorization validation
/// - Business rules validation
/// - Payment state validation
/// - Refund processing
/// - Refund event creation
/// </summary>
public class RefundPaymentCommandHandler : IRequestHandler<RefundPaymentCommand, ResultDto<bool>>
{
    private readonly IPaymentRepository _paymentRepository;
    private readonly IBookingRepository _bookingRepository;
    private readonly IUnitRepository _unitRepository;
    private readonly IPropertyRepository _propertyRepository;
    private readonly YemenBooking.Application.Features.Payments.Services.IPaymentGatewayService _paymentGatewayService;
    private readonly IValidationService _validationService;
    private readonly IAuditService _auditService;
    private readonly INotificationService _notificationService;
    private readonly IEventPublisher _eventPublisher;
    private readonly ICurrentUserService _currentUserService;
    private readonly ILogger<RefundPaymentCommandHandler> _logger;
    private readonly IFinancialAccountingService _financialAccountingService;
    private readonly ICurrencySettingsService _currencySettingsService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ISabaCashWalletService _sabaCashWalletService;
    private readonly IJwaliWalletService _jwaliWalletService;

    public RefundPaymentCommandHandler(
        IPaymentRepository paymentRepository,
        IBookingRepository bookingRepository,
        IUnitRepository unitRepository,
        IPropertyRepository propertyRepository,
        YemenBooking.Application.Features.Payments.Services.IPaymentGatewayService paymentGatewayService,
        IValidationService validationService,
        IAuditService auditService,
        INotificationService notificationService,
        IEventPublisher eventPublisher,
        ICurrentUserService currentUserService,
        ILogger<RefundPaymentCommandHandler> logger,
        IFinancialAccountingService financialAccountingService,
        ICurrencySettingsService currencySettingsService,
        IUnitOfWork unitOfWork,
        ISabaCashWalletService sabaCashWalletService,
        IJwaliWalletService jwaliWalletService)
    {
        _paymentRepository = paymentRepository;
        _bookingRepository = bookingRepository;
        _unitRepository = unitRepository;
        _propertyRepository = propertyRepository;
        _paymentGatewayService = paymentGatewayService;
        _validationService = validationService;
        _auditService = auditService;
        _notificationService = notificationService;
        _eventPublisher = eventPublisher;
        _currentUserService = currentUserService;
        _logger = logger;
        _financialAccountingService = financialAccountingService;
        _currencySettingsService = currencySettingsService;
        _unitOfWork = unitOfWork;
        _sabaCashWalletService = sabaCashWalletService;
        _jwaliWalletService = jwaliWalletService;
    }

    /// <summary>
    /// معالجة أمر استرداد الدفع
    /// Handle payment refund command
    /// </summary>
    /// <param name="request">طلب استرداد الدفع / Payment refund request</param>
    /// <param name="cancellationToken">رمز الإلغاء / Cancellation token</param>
    /// <returns>نتيجة العملية / Operation result</returns>
    public async Task<ResultDto<bool>> Handle(RefundPaymentCommand request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء معالجة أمر استرداد الدفع / Starting refund processing for payment: {PaymentId}", request.PaymentId);

            // الخطوة 1: التحقق من صحة البيانات المدخلة
            // Step 1: Input data validation
            var inputValidationResult = await ValidateInputAsync(request, cancellationToken);
            if (!inputValidationResult.Success)
            {
                _logger.LogWarning("فشل التحقق من صحة البيانات المدخلة / Input validation failed: {Errors}", string.Join(", ", inputValidationResult.Errors));
                return ResultDto<bool>.Failed(inputValidationResult.Errors);
            }

            // الخطوة 2: التحقق من وجود الدفعة والحجز
            // Step 2: Payment and booking existence validation
            var payment = await _paymentRepository.GetByIdAsync(request.PaymentId, cancellationToken);
            if (payment == null)
            {
                _logger.LogWarning("الدفعة غير موجودة / Payment not found: {PaymentId}", request.PaymentId);
                return ResultDto<bool>.Failed("الدفعة غير موجودة / Payment not found");
            }

            var booking = await _bookingRepository.GetByIdAsync(payment.BookingId, cancellationToken);
            if (booking == null)
            {
                _logger.LogWarning("الحجز غير موجود / Booking not found: {BookingId}", payment.BookingId);
                return ResultDto<bool>.Failed("الحجز غير موجود / Booking not found");
            }

            // الخطوة 3: التحقق من صلاحيات المستخدم
            // Step 3: User authorization validation
            var authorizationResult = await ValidateAuthorizationAsync(payment, booking, cancellationToken);
            if (!authorizationResult.IsSuccess)
            {
                _logger.LogWarning("فشل التحقق من الصلاحيات للمستخدم / Authorization failed for user: {UserId}", _currentUserService.UserId);
                return ResultDto<bool>.Failed(authorizationResult.Errors);
            }

            // الخطوة 4: التحقق من قواعد الأعمال
            // Step 4: Business rules validation
            var businessRulesResult = await ValidateBusinessRulesAsync(payment, request, cancellationToken);
            if (!businessRulesResult.IsSuccess)
            {
                _logger.LogWarning("فشل التحقق من قواعد الأعمال / Business rules validation failed: {Errors}", string.Join(", ", businessRulesResult.Errors));
                return ResultDto<bool>.Failed(businessRulesResult.Errors);
            }

            // الخطوة 5: التحقق من حالة الدفعة
            // Step 5: Payment state validation
            var stateValidationResult = await ValidatePaymentStateAsync(payment, cancellationToken);
            if (!stateValidationResult.IsSuccess)
            {
                _logger.LogWarning("فشل التحقق من حالة الدفعة / Payment state validation failed: {Errors}", string.Join(", ", stateValidationResult.Errors));
                return ResultDto<bool>.Failed(stateValidationResult.Errors);
            }

            // الخطوة 6: التحقق من سياسة الاسترداد
            // Step 6: Refund policy validation
            var refundPolicyResult = await ValidateRefundPolicyAsync(payment, request, cancellationToken);
            if (!refundPolicyResult.IsSuccess)
            {
                _logger.LogWarning("فشل التحقق من سياسة الاسترداد / Refund policy validation failed: {Errors}", string.Join(", ", refundPolicyResult.Errors));

                // تمرير بيانات السياسة (الكود + العرض كديالوج) إن وُجدت
                return ResultDto<bool>.Failed(
                    refundPolicyResult.Errors,
                    message: refundPolicyResult.Message,
                    errorCode: refundPolicyResult.ErrorCode,
                    showAsDialog: refundPolicyResult.ShowAsDialog
                );
            }

            // الخطوة 7: معالجة الاسترداد
            // Step 7: Process refund
            var refundResult = await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                var result = await ProcessRefundAsync(payment, booking, request, cancellationToken);
                if (!result.IsSuccess)
                {
                    _logger.LogError("فشل في معالجة الاسترداد / Refund processing failed: {Errors}", string.Join(", ", result.Errors));
                    throw new InvalidOperationException("FAILED_TO_PROCESS_REFUND");
                }
                return result;
            }, cancellationToken);

            // الخطوة 8: تسجيل العملية ونشر الأحداث
            // Step 8: Audit logging and event publishing
            await LogAuditAndPublishEventsAsync(
                payment,
                booking,
                new Money(request.RefundAmount.Amount, request.RefundAmount.Currency),
                request.RefundReason,
                refundResult.Data ?? string.Empty,
                cancellationToken);

            _logger.LogInformation("تم معالجة الاسترداد بنجاح / Refund processed successfully: {PaymentId}", payment.Id);
            return ResultDto<bool>.Succeeded(true, "تم معالجة الاسترداد بنجاح / Refund processed successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في معالجة أمر استرداد الدفع / Error processing refund command: {PaymentId}", request.PaymentId);
            return ResultDto<bool>.Failed("حدث خطأ أثناء معالجة الاسترداد / An error occurred while processing refund");
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate input data
    /// </summary>
    private async Task<ResultDto<bool>> ValidateInputAsync(RefundPaymentCommand request, CancellationToken cancellationToken)
    {
        var errors = new List<string>();

        // التحقق من معرف الدفعة
        // Validate payment ID
        if (request.PaymentId == Guid.Empty)
        {
            errors.Add("معرف الدفعة مطلوب / Payment ID is required");
        }

        // التحقق من مبلغ الاسترداد
        // Validate refund amount
        if (request.RefundAmount == null)
        {
            errors.Add("مبلغ الاسترداد مطلوب / Refund amount is required");
        }
        else if (request.RefundAmount.Amount <= 0)
        {
            errors.Add("مبلغ الاسترداد يجب أن يكون أكبر من صفر / Refund amount must be greater than zero");
        }
        else if (decimal.Round(request.RefundAmount.Amount, 2) != request.RefundAmount.Amount)
        {
            errors.Add("عدد المنازل العشرية للمبلغ يجب ألا يتجاوز رقمين / Amount must have at most 2 decimal places");
        }

        // التحقق من سبب الاسترداد
        // Validate refund reason
        if (string.IsNullOrWhiteSpace(request.RefundReason))
        {
            errors.Add("سبب الاسترداد مطلوب / Refund reason is required");
        }

        // التحقق من صحة البيانات باستخدام خدمة التحقق
        // Validate data using validation service
        var validationResult = await _validationService.ValidateAsync(request, cancellationToken);
        if (!validationResult.IsValid)
        {
            errors.AddRange(validationResult.Errors.Select(e => e.Message));
        }

        return errors.Any() ? ResultDto<bool>.Failed(errors) : ResultDto<bool>.Succeeded(true);
    }

    /// <summary>
    /// التحقق من صلاحيات المستخدم
    /// Validate user authorization
    /// </summary>
    private async Task<ResultDto<bool>> ValidateAuthorizationAsync(Payment payment, Booking booking, CancellationToken cancellationToken)
    {
        var userRoles = _currentUserService.UserRoles;
        var isAdmin = userRoles.Any(r => string.Equals(r, "Admin", StringComparison.OrdinalIgnoreCase));
        
        if (isAdmin)
        {
            return ResultDto<bool>.Succeeded(true);
        }

        return ResultDto<bool>.Failed("غير مسموح لغير المدير بتنفيذ الاسترداد / Only Admin can process refunds");
    }

    /// <summary>
    /// التحقق من قواعد الأعمال
    /// Validate business rules
    /// </summary>
    private async Task<ResultDto<bool>> ValidateBusinessRulesAsync(Payment payment, RefundPaymentCommand request, CancellationToken cancellationToken)
    {
        var errors = new List<string>();

        // التحقق من أن مبلغ الاسترداد لا يتجاوز المبلغ المدفوع - DISABLED
        // Check that refund amount doesn't exceed paid amount - DISABLED
        
        if (request.RefundAmount.Amount > payment.Amount.Amount)
        {
            errors.Add($"مبلغ الاسترداد يتجاوز المبلغ المدفوع. المبلغ المدفوع: {payment.Amount.Amount} / Refund amount exceeds paid amount. Paid amount: {payment.Amount.Amount}");
        }
        

        // التحقق من أن العملة متطابقة - DISABLED
        // Check that currency matches - DISABLED
        
        if (request.RefundAmount.Currency != payment.Amount.Currency)
        {
            errors.Add("عملة الاسترداد يجب أن تتطابق مع عملة الدفعة / Refund currency must match payment currency");
        }
        

        // Verify currency supported by system settings - DISABLED
        /*
        var currencies = await _currencySettingsService.GetCurrenciesAsync(cancellationToken);
        var isSupported = currencies.Any(c => string.Equals(c.Code, payment.Amount.Currency, StringComparison.OrdinalIgnoreCase));
        if (!isSupported)
        {
            errors.Add("العملة غير مدعومة في إعدادات النظام / Currency is not supported by system settings");
        }
        */

        // ملاحظة: يتم فرض حدود الاسترداد على مستوى الحجز أدناه (allowedRemaining)،
        // لتفادي الالتباس بين دفعات متعددة لنفس الحجز وتفادي استعلامات إضافية.

        return errors.Any() ? ResultDto<bool>.Failed(errors) : ResultDto<bool>.Succeeded(true);
    }

    /// <summary>
    /// التحقق من حالة الدفعة
    /// Validate payment state
    /// </summary>
    private async Task<ResultDto<bool>> ValidatePaymentStateAsync(Payment payment, CancellationToken cancellationToken)
    {
        var errors = new List<string>();

        // التحقق من أن الدفعة في حالة تسمح بالاسترداد
        // Check that payment is in a state that allows refund
        if (payment.Status != Core.Enums.PaymentStatus.Successful)
        {
            errors.Add($"لا يمكن استرداد الدفعة في الحالة الحالية: {payment.Status} / Cannot refund payment in current status: {payment.Status}");
        }

        // Verify original transaction status with gateway when possible
        try
        {
            var txId = string.IsNullOrWhiteSpace(payment.GatewayTransactionId)
                ? payment.TransactionId
                : payment.GatewayTransactionId;
            if (!string.IsNullOrWhiteSpace(txId))
            {
                var verification = await _paymentGatewayService.VerifyTransactionAsync(txId, cancellationToken);
                if (!string.Equals(verification.Status, "Success", StringComparison.OrdinalIgnoreCase))
                {
                    errors.Add("تعذر التحقق من نجاح المعاملة الأصلية من بوابة الدفع / Unable to verify original transaction success with payment gateway");
                }
            }
            else
            {
                errors.Add("لا يوجد معرّف معاملة صالح للتحقق / No valid transaction identifier to verify");
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "فشل التحقق من المعاملة مع بوابة الدفع");
            errors.Add("فشل التحقق من المعاملة مع بوابة الدفع / Failed to verify transaction with gateway");
        }

        return errors.Any() ? ResultDto<bool>.Failed(errors) : ResultDto<bool>.Succeeded(true);
    }

    /// <summary>
    /// التحقق من سياسة الاسترداد
    /// Validate refund policy
    /// </summary>
    private async Task<ResultDto<bool>> ValidateRefundPolicyAsync(Payment payment, RefundPaymentCommand request, CancellationToken cancellationToken)
    {
        var errors = new List<string>();

        var booking = await _bookingRepository.GetByIdAsync(payment.BookingId, cancellationToken);
        if (booking == null)
        {
            errors.Add("الحجز غير موجود / Booking not found");
            return ResultDto<bool>.Failed(errors);
        }

        
        // Determine cancellation window from saved snapshot if available
        int? windowDays = null;
        try
        {
            if (!string.IsNullOrWhiteSpace(booking.PolicySnapshot))
            {
                using var doc = System.Text.Json.JsonDocument.Parse(booking.PolicySnapshot);
                var root = doc.RootElement;
                if (root.TryGetProperty("UnitOverrides", out var overridesEl) && overridesEl.TryGetProperty("CancellationWindowDays", out var wndEl) && wndEl.ValueKind == System.Text.Json.JsonValueKind.Number)
                {
                    windowDays = wndEl.GetInt32();
                }
                if (!windowDays.HasValue && root.TryGetProperty("Policies", out var policiesEl) && policiesEl.ValueKind == System.Text.Json.JsonValueKind.Array)
                {
                    foreach (var p in policiesEl.EnumerateArray())
                    {
                        var typeStr = p.TryGetProperty("Type", out var tEl) ? tEl.GetString() : null;
                        if (!string.IsNullOrWhiteSpace(typeStr) && typeStr.Equals("Cancellation", StringComparison.OrdinalIgnoreCase))
                        {
                            if (p.TryGetProperty("CancellationWindowDays", out var cEl) && cEl.ValueKind == System.Text.Json.JsonValueKind.Number)
                            {
                                windowDays = cEl.GetInt32();
                                break;
                            }
                        }
                    }
                }
            }
        }
        catch { }
        // Fallback to current settings if snapshot missing
        if (!windowDays.HasValue)
        {
            var unit = await _unitRepository.GetByIdAsync(booking.UnitId, cancellationToken);
            windowDays = unit?.CancellationWindowDays;
            if (!windowDays.HasValue && unit != null)
            {
                var propertyPolicy = await _propertyRepository.GetCancellationPolicyAsync(unit.PropertyId, cancellationToken);
                windowDays = propertyPolicy?.CancellationWindowDays;
            }
        }

        var daysBeforeCheckIn = (booking.CheckIn - DateTime.UtcNow).TotalDays;
        decimal cancellationFeePercentage = 0m;
        if (daysBeforeCheckIn <= 1) cancellationFeePercentage = 100m;
        else if (daysBeforeCheckIn <= 3) cancellationFeePercentage = 50m;
        else if (daysBeforeCheckIn <= 7) cancellationFeePercentage = 25m;
        else if (windowDays.HasValue && daysBeforeCheckIn <= windowDays.Value) cancellationFeePercentage = 10m;
        else cancellationFeePercentage = 0m;

        var payments = await _paymentRepository.GetPaymentsByBookingAsync(booking.Id, cancellationToken);
        var totalPaid = payments.Where(p => p.Status == Core.Enums.PaymentStatus.Successful || p.Status == Core.Enums.PaymentStatus.PartiallyRefunded)
                                .Sum(p => p.Amount.Amount);
        var totalRefunded = payments.Where(p => p.Status == Core.Enums.PaymentStatus.Refunded)
                                    .Sum(p => p.Amount.Amount);

        var finalAmountToPay = booking.FinalAmount > 0 ? booking.FinalAmount : booking.TotalPrice.Amount;
        var retention = finalAmountToPay * (cancellationFeePercentage / 100m);
        var allowedRefundTotal = Math.Max(0m, totalPaid - retention);
        var allowedRemaining = Math.Max(0m, allowedRefundTotal - totalRefunded);

        if (request.RefundAmount.Amount > allowedRemaining)
        {
            errors.Add($"المبلغ المطلوب للاسترداد يتجاوز الحد المسموح حسب سياسة الإلغاء. الحد المتاح: {allowedRemaining} / Requested refund exceeds allowed by policy. Allowed remaining: {allowedRemaining}");

            // انتهاك واضح لسياسة الاسترداد -> يجب عرضه كديالوج للعميل/المشرف
            return ResultDto<bool>.Failed(
                errors,
                message: "الطلب يخالف سياسة الاسترداد المطبقة على هذا الحجز",
                errorCode: "REFUND_EXCEEDS_POLICY",
                showAsDialog: true
            );
        }
        

        // ✅ السماح بأي مبلغ للإرجاع - Allow any refund amount
        _logger.LogWarning("⚠️ تم تجاوز قيود سياسة الإرجاع للحجز {BookingId}", booking.Id);

        return ResultDto<bool>.Succeeded(true);
    }

    private async Task<ResultDto<bool>> SimulateSuccessfulRefundAsync(RefundPaymentCommand request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء معالجة استرداد في وضع المحاكاة للدفعة: {PaymentId}", request.PaymentId);

            var payment = await _paymentRepository.GetByIdAsync(request.PaymentId, cancellationToken);
            if (payment == null)
            {
                _logger.LogWarning("الدفعة غير موجودة (محاكاة) / Payment not found: {PaymentId}", request.PaymentId);
                return ResultDto<bool>.Failed("الدفعة غير موجودة / Payment not found");
            }

            var booking = await _bookingRepository.GetByIdAsync(payment.BookingId, cancellationToken);
            if (booking == null)
            {
                _logger.LogWarning("الحجز غير موجود (محاكاة) / Booking not found: {BookingId}", payment.BookingId);
                return ResultDto<bool>.Failed("الحجز غير موجود / Booking not found");
            }

            var businessRulesResult = await ValidateBusinessRulesAsync(payment, request, cancellationToken);
            if (!businessRulesResult.IsSuccess)
            {
                _logger.LogWarning("فشل التحقق من قواعد الأعمال (محاكاة) / Business rules validation failed: {Errors}", string.Join(", ", businessRulesResult.Errors));
                return ResultDto<bool>.Failed(businessRulesResult.Errors);
            }

            var refundPolicyResult = await ValidateRefundPolicyAsync(payment, request, cancellationToken);
            if (!refundPolicyResult.IsSuccess)
            {
                _logger.LogWarning("فشل التحقق من سياسة الاسترداد (محاكاة) / Refund policy validation failed: {Errors}", string.Join(", ", refundPolicyResult.Errors));
                return ResultDto<bool>.Failed(
                    refundPolicyResult.Errors,
                    message: refundPolicyResult.Message,
                    errorCode: refundPolicyResult.ErrorCode,
                    showAsDialog: refundPolicyResult.ShowAsDialog
                );
            }

            var simulatedRefundId = $"SIM-REF-{Guid.NewGuid():N}";

            var refund = new Payment
            {
                Id = Guid.NewGuid(),
                BookingId = payment.BookingId,
                Amount = new Money(request.RefundAmount.Amount, request.RefundAmount.Currency),
                PaymentMethod = payment.PaymentMethod,
                TransactionId = simulatedRefundId,
                Status = Core.Enums.PaymentStatus.Refunded,
                PaymentDate = DateTime.UtcNow,
                ProcessedBy = _currentUserService.UserId
            };

            payment.Status = request.RefundAmount.Amount < payment.Amount.Amount
                ? Core.Enums.PaymentStatus.PartiallyRefunded
                : Core.Enums.PaymentStatus.Refunded;
            payment.UpdatedAt = DateTime.UtcNow;

            await _paymentRepository.AddAsync(refund, cancellationToken);
            await _paymentRepository.UpdateAsync(payment, cancellationToken);

            // ⚠️ تم تعليق القيد المحاسبي مؤقتاً - DISABLED
            // try
            // {
            //     await _financialAccountingService.RecordRefundTransactionAsync(
            //         payment.BookingId,
            //         request.RefundAmount.Amount,
            //         request.RefundReason,
            //         _currentUserService.UserId);
            //     _logger.LogInformation("تم تسجيل القيد المحاسبي للاسترداد (وضع المحاكاة) للدفعة {PaymentId}", payment.Id);
            // }
            // catch (Exception ex)
            // {
            //     _logger.LogError(ex, "فشل تسجيل القيد المحاسبي للاسترداد (وضع المحاكاة) للدفعة {PaymentId} - سيتم المتابعة", payment.Id);
            // }

            var currentBooking = await _bookingRepository.GetByIdAsync(payment.BookingId, cancellationToken);
            if (currentBooking != null)
            {
                var totalPaid = await _paymentRepository.GetTotalPaidAmountAsync(currentBooking.Id, cancellationToken);
                if (totalPaid < currentBooking.TotalPrice.Amount)
                {
                    currentBooking.Status = BookingStatus.Pending;
                    currentBooking.UpdatedAt = DateTime.UtcNow;
                    await _bookingRepository.UpdateAsync(currentBooking, cancellationToken);
                }
            }

            await LogAuditAndPublishEventsAsync(
                payment,
                booking,
                new Money(request.RefundAmount.Amount, request.RefundAmount.Currency),
                request.RefundReason,
                simulatedRefundId,
                cancellationToken);

            _logger.LogInformation("تم معالجة الاسترداد بنجاح في وضع المحاكاة / Simulated refund processed successfully: {PaymentId}", payment.Id);
            return ResultDto<bool>.Succeeded(true, "تم معالجة الاسترداد بنجاح (وضع المحاكاة) / Refund processed successfully (simulation mode)");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في معالجة الاسترداد في وضع المحاكاة للدفعة / Error processing simulated refund for payment: {PaymentId}", request.PaymentId);
            return ResultDto<bool>.Failed("حدث خطأ أثناء معالجة الاسترداد في وضع المحاكاة / An error occurred while processing simulated refund");
        }
    }

    /// <summary>
    /// معالجة الاسترداد
    /// Process refund
    /// </summary>
    private async Task<ResultDto<string>> ProcessRefundAsync(Payment payment, Booking booking, RefundPaymentCommand request, CancellationToken cancellationToken)
    {
        try
        {
            // معالجة الاسترداد عبر القناة المناسبة
            // Process refund through the appropriate channel
            string refundId;

            if (payment.PaymentMethod == PaymentMethodEnum.SabaCashWallet)
            {
                // استرداد عبر محفظة سبأ كاش باستخدام تكامل YottaPay
                var sabaResult = await _sabaCashWalletService.RefundAsync(
                    payment,
                    booking,
                    request.RefundAmount.Amount,
                    request.RefundReason,
                    cancellationToken);

                if (!sabaResult.IsSuccess)
                {
                    return ResultDto<string>.Failed($"فشل في معالجة الاسترداد عبر سبأ كاش: {sabaResult.Message} / SabaCash refund failed: {sabaResult.Message}");
                }

                refundId = sabaResult.RefundId;
            }
            else if (payment.PaymentMethod == PaymentMethodEnum.JwaliWallet)
            {
                // استرداد عبر محفظة جوالي باستخدام تكامل PAYAG.ECOMMERCEREFUND
                var jwaliResult = await _jwaliWalletService.RefundAsync(
                    payment,
                    booking,
                    request.RefundAmount.Amount,
                    request.RefundReason,
                    cancellationToken);

                if (!jwaliResult.IsSuccess)
                {
                    return ResultDto<string>.Failed($"فشل في معالجة الاسترداد عبر جوالي: {jwaliResult.Message} / Jwali refund failed: {jwaliResult.Message}");
                }

                refundId = jwaliResult.RefundId;
            }
            else
            {
                // حالياً طرق الدفع الفعلية المدعومة هي محفظة جوالي ومحفظة سبأ كاش فقط
                // أي طريقة أخرى سيتم إرجاع رسالة توضح أن الاسترداد غير مفعّل لهذه الطريقة
                return ResultDto<string>.Failed(
                    "الاسترداد غير مفعّل حالياً لهذه الطريقة. الطرق المدعومة للاسترداد: محفظة جوالي، محفظة سبأ كاش",
                    "REFUND_METHOD_NOT_ENABLED");
            }

            // إنشاء سجل استرداد جديد
            // Create new refund record
            var refund = new Payment
            {
                Id = Guid.NewGuid(),
                BookingId = payment.BookingId,
                Amount = new Money(request.RefundAmount.Amount, request.RefundAmount.Currency),
                PaymentMethod = payment.PaymentMethod,
                TransactionId = refundId,
                Status = Core.Enums.PaymentStatus.Refunded,
                PaymentDate = DateTime.UtcNow,
                ProcessedBy = _currentUserService.UserId
            };

            // تحديث حالة الدفعة الأصلية
            // Update original payment status
            payment.Status = request.RefundAmount.Amount < payment.Amount.Amount
                ? Core.Enums.PaymentStatus.PartiallyRefunded
                : Core.Enums.PaymentStatus.Refunded;
            payment.UpdatedAt = DateTime.UtcNow;

            // حفظ التغييرات في قاعدة البيانات
            // Save changes to database
            await _paymentRepository.AddAsync(refund, cancellationToken);
            await _paymentRepository.UpdateAsync(payment, cancellationToken);

            // ⚠️ تم تعليق القيد المحاسبي مؤقتاً - DISABLED
            // تسجيل القيد المحاسبي للاسترداد
            // try
            // {
            //     await _financialAccountingService.RecordRefundTransactionAsync(
            //         payment.BookingId,
            //         request.RefundAmount.Amount,
            //         request.RefundReason,
            //         _currentUserService.UserId);
            //     _logger.LogInformation("تم تسجيل القيد المحاسبي للاسترداد للدفعة {PaymentId}", payment.Id);
            // }
            // catch (Exception ex)
            // {
            //     _logger.LogError(ex, "فشل تسجيل القيد المحاسبي للاسترداد للدفعة {PaymentId} - سيتم المتابعة", payment.Id);
            //     // نستمر رغم فشل القيد المحاسبي لأن الاسترداد تم بنجاح
            // }

            // تحديث حالة الحجز إذا لزم الأمر
            // Update booking status if needed
            booking = await _bookingRepository.GetByIdAsync(payment.BookingId, cancellationToken);
            if (booking != null)
            {
                var totalPaid = await _paymentRepository.GetTotalPaidAmountAsync(booking.Id, cancellationToken);
                if (totalPaid < booking.TotalPrice.Amount)
                {
                    booking.Status = BookingStatus.Pending;
                    booking.UpdatedAt = DateTime.UtcNow;
                    await _bookingRepository.UpdateAsync(booking, cancellationToken);
                }
            }

            return ResultDto<string>.Succeeded(refundId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في معالجة الاسترداد للدفعة / Error processing refund for payment: {PaymentId}", payment.Id);
            return ResultDto<string>.Failed("حدث خطأ أثناء معالجة الاسترداد / An error occurred while processing refund");
        }
    }

    /// <summary>
    /// تسجيل العملية ونشر الأحداث
    /// Log audit and publish events
    /// </summary>
    private async Task LogAuditAndPublishEventsAsync(Payment payment, Booking booking, Money refundAmount, string refundReason, string refundTransactionId, CancellationToken cancellationToken)
    {
        // تسجيل العملية
        // Audit logging
        var notes = $"تم معالجة الاسترداد للحجز {booking.Id} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
        await _auditService.LogAuditAsync(
            entityType: "Payment",
            entityId: payment.Id,
            action: AuditAction.UPDATE,
            oldValues: null,
            newValues: System.Text.Json.JsonSerializer.Serialize(new { RefundAmount = refundAmount.Amount, Currency = refundAmount.Currency, BookingId = booking.Id }),
            performedBy: _currentUserService.UserId,
            notes: notes,
            cancellationToken: cancellationToken);

        // نشر حدث معالجة الاسترداد
        // Publish refund processed event
        await _eventPublisher.PublishAsync(new PaymentRefundedEvent
        {
            PaymentId = payment.Id,
            BookingId = booking.Id,
            RefundAmount = refundAmount.Amount,
            RefundReason = refundReason,
            RefundTransactionId = refundTransactionId,
            RefundedAt = DateTime.UtcNow,
            RefundMethod = payment.PaymentMethod,
            RefundStatus = Core.Enums.PaymentStatus.Refunded,
            OriginalAmount = payment.Amount.Amount,
            Currency = refundAmount.Currency,
            Notes = null,
            EventId = Guid.NewGuid(),
            OccurredOn = DateTime.UtcNow,
            EventType = nameof(PaymentRefundedEvent),
            Version = 1,
            UserId = _currentUserService.UserId,
            CorrelationId = booking.Id.ToString()
        }, cancellationToken);

        // إرسال إشعار للضيف
        // Send notification to guest
        await _notificationService.SendAsync(new NotificationRequest
        {
            UserId = booking.UserId,
            Type = NotificationType.RefundProcessed,
            Title = "تم معالجة الاسترداد / Refund Processed",
            Message = $"تم معالجة استرداد بمبلغ {refundAmount.Amount} {refundAmount.Currency} بنجاح / Your refund of {refundAmount.Amount} {refundAmount.Currency} has been processed successfully",
            Data = new { PaymentId = payment.Id, BookingId = booking.Id }
        }, cancellationToken);
    }
}

