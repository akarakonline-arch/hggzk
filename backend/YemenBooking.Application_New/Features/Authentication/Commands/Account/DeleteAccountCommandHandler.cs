using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Authentication;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Authentication;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.Json;
using YemenBooking.Core.Interfaces.Repositories;
using System;
using System.Threading;
using YemenBooking.Application.Features.AuditLog.Services;
using System.Threading.Tasks;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Authentication.DTOs;
using YemenBooking.Application.Features.Authentication.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using Microsoft.EntityFrameworkCore;

namespace YemenBooking.Application.Features.Authentication.Commands.Account
{
    /// <summary>
    /// معالج أمر حذف حساب المستخدم
    /// Handler for delete account command
    /// </summary>
    public class DeleteAccountCommandHandler : IRequestHandler<DeleteAccountCommand, ResultDto<DeleteAccountResponse>>
    {
        private readonly IAuthenticationService _authService;
        private readonly IPasswordHashingService _passwordHashingService;
        private readonly IUserRepository _userRepository;
        private readonly IBookingRepository _bookingRepository;
    private readonly ILogger<DeleteAccountCommandHandler> _logger;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;

        /// <summary>
        /// منشئ معالج أمر حذف حساب المستخدم
        /// Constructor for delete account command handler
        /// </summary>
        /// <param name="authService">خدمة المصادقة</param>
        /// <param name="userRepository">مستودع المستخدمين</param>
        /// <param name="bookingRepository">مستودع الحجوزات</param>
        /// <param name="logger">مسجل الأحداث</param>
        public DeleteAccountCommandHandler(
            IAuthenticationService authService,
            IPasswordHashingService passwordHashingService,
            IUserRepository userRepository,
            IBookingRepository bookingRepository,
            ILogger<DeleteAccountCommandHandler> logger,
            IAuditService auditService,
            ICurrentUserService currentUserService)
        {
            _authService = authService;
            _passwordHashingService = passwordHashingService;
            _userRepository = userRepository;
            _bookingRepository = bookingRepository;
            _logger = logger;
            _auditService = auditService;
            _currentUserService = currentUserService;
        }

        /// <summary>
        /// معالجة أمر حذف حساب المستخدم
        /// Handle delete account command
        /// </summary>
        /// <param name="request">طلب حذف الحساب</param>
        /// <param name="cancellationToken">رمز الإلغاء</param>
        /// <returns>نتيجة العملية</returns>
        public async Task<ResultDto<DeleteAccountResponse>> Handle(DeleteAccountCommand request, CancellationToken cancellationToken)
        {
            try
            {
                // Prefer authenticated user id (do not trust userId from request body)
                var userId = _currentUserService.UserId != Guid.Empty
                    ? _currentUserService.UserId
                    : request.UserId;

                _logger.LogInformation("بدء عملية حذف حساب المستخدم: {UserId}", userId);

                // التحقق من صحة البيانات المدخلة
                if (userId == Guid.Empty)
                {
                    _logger.LogWarning("محاولة حذف حساب بدون معرف مستخدم صالح");
                    return ResultDto<DeleteAccountResponse>.Failed("معرف المستخدم غير صالح", "INVALID_USER_ID");
                }

                if (string.IsNullOrWhiteSpace(request.Password))
                {
                    return ResultDto<DeleteAccountResponse>.Failed("كلمة المرور مطلوبة للتأكيد", "PASSWORD_REQUIRED");
                }

                // البحث عن المستخدم
                var user = await _userRepository.GetUserByIdAsync(userId, cancellationToken);
                if (user == null)
                {
                    _logger.LogWarning("لم يتم العثور على المستخدم: {UserId}", userId);
                    return ResultDto<DeleteAccountResponse>.Failed("المستخدم غير موجود", "USER_NOT_FOUND");
                }

                // التحقق من كلمة المرور
                var passwordValid = await _passwordHashingService.VerifyPasswordAsync(request.Password, user.Password, cancellationToken);
                if (!passwordValid)
                {
                    return ResultDto<DeleteAccountResponse>.Failed("كلمة المرور غير صحيحة", "INVALID_PASSWORD");
                }

                _logger.LogInformation("تم التحقق من هوية المستخدم لحذف الحساب: {UserId}", userId);

                // التحقق من وجود حجوزات نشطة لم ينتهِ وقتها بعد
                // الحجوزات التي انتهى تاريخ مغادرتها (CheckOut) لا تعتبر نشطة
                // نستخدم Date فقط للمقارنة لأن CheckOut عادة يكون تاريخ بدون وقت (00:00:00)
                // الحجز يعتبر نشطاً فقط إذا كان تاريخ المغادرة > اليوم (أي لم يحن موعد المغادرة بعد)
                var now = DateTime.UtcNow;
                var today = now.Date;
                var hasActiveBookings = await _bookingRepository
                    .GetQueryable()
                    .AnyAsync(b => b.UserId == userId &&
                                 (b.Status == BookingStatus.Pending || b.Status == BookingStatus.Confirmed || b.Status == BookingStatus.CheckedIn) &&
                                 b.CheckOut.Date > today,
                        cancellationToken);

                if (hasActiveBookings)
                {
                    _logger.LogWarning("محاولة حذف حساب مع وجود حجوزات نشطة لم تنتهِ بعد: {UserId}", userId);
                    return ResultDto<DeleteAccountResponse>.Failed("لا يمكن حذف الحساب لوجود حجوزات نشطة لم ينتهِ وقتها. يرجى الانتظار حتى انتهاء الحجوزات أو إلغائها", "ACTIVE_BOOKINGS_EXIST");
                }

                // تسجيل سبب الحذف إذا تم توفيره
                if (!string.IsNullOrWhiteSpace(request.Reason))
                {
                    _logger.LogInformation("سبب حذف الحساب {UserId}: {Reason}", userId, request.Reason);
                }

                // Soft delete + anonymize personal data (PII)
                user.IsDeleted = true;
                user.DeletedAt = DateTime.UtcNow;
                user.IsActive = false;
                user.UpdatedAt = DateTime.UtcNow;

                // Ensure unique email/phone to avoid blocking future registrations
                // Phone column is varchar(20), so we use a short unique identifier
                var shortId = user.Id.ToString("N").Substring(0, 8); // First 8 chars of GUID without dashes
                user.Email = $"deleted+{user.Id}@example.invalid";
                user.Name = "حساب محذوف";
                user.Phone = $"DEL{shortId}";  // Max 11 chars: "DEL" + 8 chars = 11 chars (fits in varchar(20))
                user.ProfileImage = null;
                user.ProfileImageUrl = null;

                // Clear verification/reset tokens
                user.EmailConfirmationToken = null;
                user.EmailConfirmationTokenExpires = null;
                user.PasswordResetToken = null;
                user.PasswordResetTokenExpires = null;
                user.PhoneNumberConfirmationCode = null;
                user.PhoneNumberConfirmationCodeExpires = null;

                await _userRepository.UpdateUserAsync(user, cancellationToken);
                _logger.LogInformation("تم حذف الحساب (Soft Delete) بنجاح: {UserId}", userId);

                // تدقيق يدوي: حذف الحساب
                var performerName = _currentUserService.Username;
                var performerId = _currentUserService.UserId;
                var notes = $"تم حذف حساب المستخدم {userId} بواسطة {performerName} (ID={performerId})";
                await _auditService.LogAuditAsync(
                    entityType: "User",
                    entityId: userId,
                    action: YemenBooking.Core.Entities.AuditAction.DELETE,
                    oldValues: null,
                    newValues: JsonSerializer.Serialize(new { Success = true, Reason = request.Reason }),
                    performedBy: performerId,
                    notes: notes,
                    cancellationToken: cancellationToken);

                var response = new DeleteAccountResponse
                {
                    Success = true,
                    Message = "تم حذف الحساب بنجاح. نأسف لرؤيتك تغادر"
                };

                return ResultDto<DeleteAccountResponse>.Ok(response, "تم حذف الحساب بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء حذف حساب المستخدم: {UserId}", request.UserId);
                return ResultDto<DeleteAccountResponse>.Failed($"حدث خطأ أثناء حذف الحساب: {ex.Message}", "DELETE_ACCOUNT_ERROR");
            }
        }
    }
}