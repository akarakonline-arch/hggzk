using MediatR;
using Microsoft.Extensions.Logging;
using System.Linq;
using YemenBooking.Application.Features.Bookings;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.Notifications.Services;
using System.Text.Json;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Features;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Features.Payments.Commands.RefundPayment;
using YemenBooking.Core.Notifications;

namespace YemenBooking.Application.Features.Bookings.Commands.CancelBooking;

/// <summary>
/// معالج أمر إلغاء الحجز للعميل عبر تطبيق الجوال
/// </summary>
public class CancelBookingCommandHandler : IRequestHandler<CancelBookingCommand, ResultDto<bool>>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;
    private readonly ILogger<CancelBookingCommandHandler> _logger;
    private readonly IBookingRepository _bookingRepository;
    private readonly IUnitRepository _unitRepository;
    private readonly IDailyUnitScheduleRepository _scheduleRepository;
    private readonly IDailyUnitScheduleService _scheduleService;
    private readonly IMediator _mediator;
    private readonly IUnitIndexingService _indexingService;
    private readonly IPropertyRepository _propertyRepository;
    private readonly IPaymentRepository _paymentRepository;
    private readonly INotificationService _notificationService;


    public CancelBookingCommandHandler(
        IUnitOfWork unitOfWork,
        IAuditService auditService,
        ICurrentUserService currentUserService,
        ILogger<CancelBookingCommandHandler> logger,
        IBookingRepository bookingRepository,
        IUnitRepository unitRepository,
        IDailyUnitScheduleRepository scheduleRepository,
        IDailyUnitScheduleService scheduleService,
        IMediator mediator,
    IUnitIndexingService indexingService,
        IPropertyRepository propertyRepository,
        IPaymentRepository paymentRepository,
        INotificationService notificationService)
    {
        _unitOfWork = unitOfWork;
        _auditService = auditService;
        _currentUserService = currentUserService;
        _logger = logger;
        _bookingRepository = bookingRepository;
        _unitRepository = unitRepository;
        _scheduleRepository = scheduleRepository;
        _scheduleService = scheduleService;
        _mediator = mediator;
        _indexingService = indexingService;
        _propertyRepository = propertyRepository;
        _paymentRepository = paymentRepository;
        _notificationService = notificationService;
    }

    /// <inheritdoc />
    public async Task<ResultDto<bool>> Handle(CancelBookingCommand request, CancellationToken cancellationToken)
    {
        _logger.LogInformation("بدء إلغاء الحجز {BookingId} من قبل المستخدم {UserId}", request.BookingId, request.UserId);

        var bookingRepo = _unitOfWork.Repository<Core.Entities.Booking>();
        var booking = await bookingRepo.GetByIdAsync(request.BookingId);
        if (booking == null)
        {
            return ResultDto<bool>.Failure("الحجز غير موجود");
        }
        var roles = _currentUserService.UserRoles;
        var isAdmin = roles.Any(r => string.Equals(r, "Admin", StringComparison.OrdinalIgnoreCase));
        var currentUserId = _currentUserService.UserId;

        if (booking.UserId != currentUserId && !isAdmin)
        {
            var unitForAuth = await _unitRepository.GetByIdAsync(booking.UnitId, cancellationToken);
            if (unitForAuth == null)
            {
                return ResultDto<bool>.Failure("الوحدة غير موجودة");
            }
            var propertyForAuth = await _propertyRepository.GetByIdAsync(unitForAuth.PropertyId, cancellationToken);
            if (propertyForAuth == null || propertyForAuth.OwnerId != currentUserId)
            {
                return ResultDto<bool>.Failure("ليس لديك صلاحية لإلغاء هذا الحجز");
            }
        }
        // سياسة الإلغاء: تحقق صارم قبل أي تعديل
        var unit = await _unitRepository.GetByIdAsync(booking.UnitId, cancellationToken);
        if (unit == null)
        {
            return ResultDto<bool>.Failure("الوحدة غير موجودة");
        }

        if (!unit.AllowsCancellation)
        {
            return ResultDto<bool>.Failure("هذه الوحدة لا تسمح بإلغاء الحجز");
        }

        // احصل على نافذة الإلغاء من الحقول المهيكلة بدقة (بدون الاعتماد على JSON)
        int? windowDays = unit.CancellationWindowDays;
        if (!windowDays.HasValue)
        {
            var propertyPolicy = await _propertyRepository.GetCancellationPolicyAsync(unit.PropertyId, cancellationToken);
            windowDays = propertyPolicy?.CancellationWindowDays;
        }

        if (windowDays.HasValue)
        {
            var userToday = (await _currentUserService.ConvertFromUtcToUserLocalAsync(DateTime.UtcNow)).Date;
            var checkInLocalDate = (await _currentUserService.ConvertFromUtcToUserLocalAsync(booking.CheckIn)).Date;
            var daysBeforeCheckIn = (checkInLocalDate - userToday).TotalDays;

            // لا يُسمح بإلغاء الحجز بعد وقت تسجيل الوصول وفقًا للسياسة
            if (daysBeforeCheckIn < 0)
            {
                return ResultDto<bool>.Failure(
                    "لا يمكن إلغاء الحجز بعد وقت تسجيل الوصول حسب سياسة الإلغاء",
                    errorCode: "CANCELLATION_AFTER_CHECKIN",
                    showAsDialog: true
                );
            }

            // إذا تم تعيين نافذة إلغاء، فالتجاوز عنها يُعد مخالفة للسياسة
            if (daysBeforeCheckIn < windowDays.Value)
            {
                return ResultDto<bool>.Failure(
                    $"لا يمكن إلغاء الحجز خلال {windowDays.Value} يوم/أيام قبل تاريخ الوصول حسب سياسة الإلغاء",
                    errorCode: "CANCELLATION_WINDOW_EXCEEDED",
                    showAsDialog: true
                );
            }
        }

        // التحقق من وجود مدفوعات ناجحة للحجز
        var payments = await _paymentRepository.GetPaymentsByBookingAsync(booking.Id, cancellationToken);
        var hasSuccessfulPayments = payments.Any(p => p.Status == PaymentStatus.Successful || p.Status == PaymentStatus.PartiallyRefunded);
        if (hasSuccessfulPayments && !request.RefundPayments)
        {
            return ResultDto<bool>.Failure(
                "لا يمكن إلغاء حجز يحتوي على مدفوعات. هل تريد استرداد المدفوعات ثم إلغاء الحجز؟",
                errorCode: "PAYMENTS_EXIST",
                showAsDialog: true
            );
        }

        if (hasSuccessfulPayments && request.RefundPayments)
        {
            foreach (var pay in payments.Where(p => p.Status == PaymentStatus.Successful).OrderBy(p => p.PaymentDate))
            {
                var refundCmd = new RefundPaymentCommand
                {
                    PaymentId = pay.Id,
                    RefundAmount = new MoneyDto { Amount = pay.Amount.Amount, Currency = pay.Amount.Currency, ExchangeRate = 1 },
                    RefundReason = request.CancellationReason ?? "Cancellation"
                };
                var refundRes = await _mediator.Send(refundCmd, cancellationToken);
                if (!refundRes.Success)
                {
                    return ResultDto<bool>.Failure(refundRes.Message ?? "فشل استرداد المبالغ قبل الإلغاء", errorCode: "REFUND_FAILED_BEFORE_CANCELLATION");
                }
            }
        }

        // Passed policy checks and handled payments: proceed to cancel
        booking.Status = BookingStatus.Cancelled;
        booking.CancellationReason = request.CancellationReason;
        booking.UpdatedAt = DateTime.UtcNow;

        // تحرير فترة الحجز في الجداول اليومية وإعادتها إلى متاحة
        var bookingSchedules = await _scheduleRepository.GetByBookingIdAsync(booking.Id);
        var schedulesToUpdate = bookingSchedules.ToList();

        foreach (var schedule in schedulesToUpdate)
        {
            schedule.Status = "Available";
            schedule.Reason = null;
            schedule.Notes = null;
            schedule.BookingId = null;
            schedule.UpdatedAt = DateTime.UtcNow;
        }

        if (schedulesToUpdate.Any())
        {
            await _scheduleRepository.BulkUpdateAsync(schedulesToUpdate);
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        // ✅ تحديث مباشر لفهرس الإتاحة - Critical للبحث
        // إذا فشل، نحتاج إعادة المحاولة لأن الفهرس سيصبح غير متطابق
        var indexingSuccess = false;
        var indexingAttempts = 0;
        const int maxIndexingAttempts = 3;
        
        while (!indexingSuccess && indexingAttempts < maxIndexingAttempts)
        {
            try
            {
                indexingAttempts++;
                var bookingToUpdate = await _bookingRepository.GetByIdAsync(request.BookingId, cancellationToken);
                if (bookingToUpdate != null)
                {
                    var from = DateTime.UtcNow.Date;
                    var to = from.AddMonths(6);
                    var periods = await _scheduleRepository.GetAvailableDaysAsync(bookingToUpdate.UnitId, from, to);
                    var availableRanges = periods
                        .Select(p => (p.Date, p.Date.AddDays(1)))
                        .ToList();

                    await _indexingService.OnAvailabilityChangedAsync(bookingToUpdate.UnitId, cancellationToken);
                    indexingSuccess = true;
                    _logger.LogInformation("✅ تم تحديث فهرس الإتاحة بنجاح بعد إلغاء الحجز {BookingId} (محاولة {Attempt}/{Max})", 
                        request.BookingId, indexingAttempts, maxIndexingAttempts);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "⚠️ فشلت محاولة {Attempt}/{Max} لتحديث فهرس الإتاحة بعد إلغاء الحجز {BookingId}", 
                    indexingAttempts, maxIndexingAttempts, request.BookingId);
                
                if (indexingAttempts < maxIndexingAttempts)
                {
                    await Task.Delay(TimeSpan.FromSeconds(1 * indexingAttempts), cancellationToken); // Exponential backoff
                }
                else
                {
                    // ❌ Critical failure: الفهرس لن يتطابق مع الواقع
                    _logger.LogCritical("❌ CRITICAL: فشل تحديث فهرس الإتاحة بعد {Attempts} محاولات للحجز {BookingId}. " +
                        "الفهرس غير متطابق! يجب تشغيل re-index يدوي.", 
                        maxIndexingAttempts, request.BookingId);
                    
                    // TODO: إضافة إلى background job queue للمحاولة لاحقاً
                }
            }
        }
        
        var performerName = _currentUserService.Username;
        var performerId = _currentUserService.UserId;
        var notes = $"تم إلغاء الحجز {booking.Id} بواسطة {performerName} (ID={performerId})";
        await _auditService.LogAuditAsync(
            entityType: "BookingDto",
            entityId: booking.Id,
            action: AuditAction.DELETE,
            oldValues: JsonSerializer.Serialize(new { booking.Id, PreviousStatus = "Pending" }),
            newValues: null,
            performedBy: performerId,
            notes: notes,
            cancellationToken: cancellationToken);

        // إرسال إشعار للضيف يتضمن سبب الإلغاء (عربي فقط)
        try
        {
            var reason = string.IsNullOrWhiteSpace(booking.CancellationReason)
                ? (string.IsNullOrWhiteSpace(request.CancellationReason) ? "غير محدد" : request.CancellationReason!)
                : booking.CancellationReason!;

            await _notificationService.SendAsync(new NotificationRequest
            {
                UserId = booking.UserId,
                Type = NotificationType.BookingCancelled,
                Title = "تم إلغاء الحجز",
                Message = $"تم إلغاء حجزك. رقم الحجز: {booking.Id}. السبب: {reason}.",
                Data = new { BookingId = booking.Id, Reason = reason }
            }, cancellationToken);

            // إشعار مالك العقار
            var unitEntity = await _unitRepository.GetByIdAsync(booking.UnitId, cancellationToken);
            if (unitEntity != null)
            {
                var propertyEntity = await _propertyRepository.GetByIdAsync(unitEntity.PropertyId, cancellationToken);
                if (propertyEntity != null && propertyEntity.OwnerId != Guid.Empty)
                {
                    await _notificationService.SendAsync(new NotificationRequest
                    {
                        UserId = propertyEntity.OwnerId,
                        Type = NotificationType.BookingCancelled,
                        Title = "تم إلغاء حجز",
                        Message = $"تم إلغاء حجز في وحدتك. رقم الحجز: {booking.Id}. السبب: {reason}.",
                        Data = new { BookingId = booking.Id, UnitId = unitEntity.Id, Reason = reason }
                    }, cancellationToken);
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "فشل إرسال إشعار إلغاء الحجز للمستخدم {UserId} للحجز {BookingId}", booking.UserId, booking.Id);
            // لا نُفشل العملية الأساسية بسبب فشل الإشعار
        }

        return ResultDto<bool>.Succeeded(true, "تم إلغاء الحجز بنجاح");
    }
}
