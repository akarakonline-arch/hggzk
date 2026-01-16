using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using System;
using System.Linq;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Features.Authentication.DTOs;
using YemenBooking.Application.Features.Authentication.Services;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces.Repositories;
using CoreUnit = YemenBooking.Core.Entities.Unit;

namespace YemenBooking.Application.Features.Authentication.Commands.Account
{
    public class DeleteOwnerAccountCommandHandler : IRequestHandler<DeleteOwnerAccountCommand, ResultDto<DeleteAccountResponse>>
    {
        private readonly IPasswordHashingService _passwordHashingService;
        private readonly IUserRepository _userRepository;
        private readonly IBookingRepository _bookingRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly IUnitRepository _unitRepository;
        private readonly IUnitIndexingService _indexingService;
        private readonly ILogger<DeleteOwnerAccountCommandHandler> _logger;
        private readonly IAuditService _auditService;
        private readonly ICurrentUserService _currentUserService;

        public DeleteOwnerAccountCommandHandler(
            IPasswordHashingService passwordHashingService,
            IUserRepository userRepository,
            IBookingRepository bookingRepository,
            IPropertyRepository propertyRepository,
            IUnitRepository unitRepository,
            IUnitIndexingService indexingService,
            ILogger<DeleteOwnerAccountCommandHandler> logger,
            IAuditService auditService,
            ICurrentUserService currentUserService)
        {
            _passwordHashingService = passwordHashingService;
            _userRepository = userRepository;
            _bookingRepository = bookingRepository;
            _propertyRepository = propertyRepository;
            _unitRepository = unitRepository;
            _indexingService = indexingService;
            _logger = logger;
            _auditService = auditService;
            _currentUserService = currentUserService;
        }

        public async Task<ResultDto<DeleteAccountResponse>> Handle(DeleteOwnerAccountCommand request, CancellationToken cancellationToken)
        {
            try
            {
                var userId = _currentUserService.UserId;

                _logger.LogInformation("بدء عملية حذف حساب المالك: {UserId}", userId);

                if (userId == Guid.Empty)
                {
                    return ResultDto<DeleteAccountResponse>.Failed("غير مصرح", "UNAUTHORIZED");
                }

                var role = _currentUserService.Role;
                var accountRole = _currentUserService.AccountRole;
                var roles = _currentUserService.UserRoles ?? Enumerable.Empty<string>();

                var isOwner = string.Equals(role, "Owner", StringComparison.OrdinalIgnoreCase)
                              || string.Equals(accountRole, "Owner", StringComparison.OrdinalIgnoreCase)
                              || roles.Any(r => string.Equals(r, "Owner", StringComparison.OrdinalIgnoreCase));

                var isAdmin = string.Equals(role, "Admin", StringComparison.OrdinalIgnoreCase)
                              || string.Equals(accountRole, "Admin", StringComparison.OrdinalIgnoreCase)
                              || roles.Any(r => string.Equals(r, "Admin", StringComparison.OrdinalIgnoreCase));

                if (!isOwner)
                {
                    return ResultDto<DeleteAccountResponse>.Failed("هذه العملية متاحة فقط لملاك العقارات", "OWNER_ONLY");
                }

                if (isAdmin)
                {
                    return ResultDto<DeleteAccountResponse>.Failed("لا يمكن للمدير حذف حسابه", "ADMIN_CANNOT_DELETE_ACCOUNT");
                }

                if (string.IsNullOrWhiteSpace(request.Password))
                {
                    return ResultDto<DeleteAccountResponse>.Failed("كلمة المرور مطلوبة للتأكيد", "PASSWORD_REQUIRED");
                }

                var user = await _userRepository.GetUserByIdAsync(userId, cancellationToken);
                if (user == null)
                {
                    return ResultDto<DeleteAccountResponse>.Failed("المستخدم غير موجود", "USER_NOT_FOUND");
                }

                var passwordValid = await _passwordHashingService.VerifyPasswordAsync(request.Password, user.Password, cancellationToken);
                if (!passwordValid)
                {
                    return ResultDto<DeleteAccountResponse>.Failed("كلمة المرور غير صحيحة", "INVALID_PASSWORD");
                }

                // التحقق من وجود حجوزات نشطة على عقارات المالك لم ينتهِ وقتها بعد
                // الحجوزات التي انتهى تاريخ مغادرتها (CheckOut) لا تعتبر نشطة
                // نستخدم Date فقط للمقارنة لأن CheckOut عادة يكون تاريخ بدون وقت (00:00:00)
                // الحجز يعتبر نشطاً فقط إذا كان تاريخ المغادرة > اليوم (أي لم يحن موعد المغادرة بعد)
                var now = DateTime.UtcNow;
                var today = now.Date;
                var hasActiveBookingsOnOwnedProperties = await _bookingRepository
                    .GetQueryable()
                    .AsNoTracking()
                    .Include(b => b.Unit)
                    .ThenInclude(u => u.Property)
                    .AnyAsync(
                        b => b.Unit.Property.OwnerId == userId &&
                             (b.Status == BookingStatus.Pending || b.Status == BookingStatus.Confirmed || b.Status == BookingStatus.CheckedIn) &&
                             b.CheckOut.Date > today,
                        cancellationToken);

                if (hasActiveBookingsOnOwnedProperties)
                {
                    return ResultDto<DeleteAccountResponse>.Failed(
                        "لا يمكن حذف حساب المالك لوجود حجوزات نشطة لم ينتهِ وقتها على عقاراته. يرجى الانتظار حتى انتهاء الحجوزات أو إلغائها",
                        "ACTIVE_BOOKINGS_EXIST");
                }

                var properties = await _propertyRepository
                    .GetQueryable()
                    .Where(p => p.OwnerId == userId)
                    .ToListAsync(cancellationToken);

                var propertyIds = properties.Select(p => p.Id).ToList();

                var units = propertyIds.Count == 0
                    ? new System.Collections.Generic.List<CoreUnit>()
                    : await _unitRepository
                        .GetQueryable()
                        .Where(u => propertyIds.Contains(u.PropertyId))
                        .ToListAsync(cancellationToken);

                foreach (var p in properties)
                {
                    p.IsApproved = false;
                    p.IsActive = false;
                    p.IsDeleted = true;
                    p.DeletedAt = now;
                    p.UpdatedAt = now;
                }

                foreach (var u in units)
                {
                    u.IsActive = false;
                    u.IsDeleted = true;
                    u.DeletedAt = now;
                    u.UpdatedAt = now;
                }

                if (properties.Count > 0)
                {
                    await _propertyRepository.UpdateRangeAsync(properties, cancellationToken);
                }

                if (units.Count > 0)
                {
                    await _unitRepository.UpdateRangeAsync(units, cancellationToken);
                }

                if (properties.Count > 0 || units.Count > 0)
                {
                    await _propertyRepository.SaveChangesAsync(cancellationToken);
                }

                foreach (var p in properties)
                {
                    try
                    {
                        await _indexingService.OnPropertyDeletedAsync(p.Id, cancellationToken);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "فشل حذف وحدات العقار من الفهرس أثناء حذف حساب المالك. PropertyId={PropertyId}", p.Id);
                    }
                }

                user.IsDeleted = true;
                user.DeletedAt = now;
                user.IsActive = false;
                user.UpdatedAt = now;

                // Ensure unique email/phone to avoid blocking future registrations
                // Phone column is varchar(20), so we use a short unique identifier
                var shortId = user.Id.ToString("N").Substring(0, 8); // First 8 chars of GUID without dashes
                user.Email = $"deleted+{user.Id}@example.invalid";
                user.Name = "حساب محذوف";
                user.Phone = $"DEL{shortId}";  // Max 11 chars: "DEL" + 8 chars = 11 chars (fits in varchar(20))
                user.ProfileImage = null;
                user.ProfileImageUrl = null;

                user.EmailConfirmationToken = null;
                user.EmailConfirmationTokenExpires = null;
                user.PasswordResetToken = null;
                user.PasswordResetTokenExpires = null;
                user.PhoneNumberConfirmationCode = null;
                user.PhoneNumberConfirmationCodeExpires = null;

                await _userRepository.UpdateUserAsync(user, cancellationToken);

                var notes = $"تم حذف حساب المالك {userId} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
                await _auditService.LogAuditAsync(
                    entityType: "User",
                    entityId: userId,
                    action: AuditAction.DELETE,
                    oldValues: null,
                    newValues: JsonSerializer.Serialize(new { Success = true, Reason = request.Reason, DisabledProperties = properties.Count, DisabledUnits = units.Count }),
                    performedBy: _currentUserService.UserId,
                    notes: notes,
                    cancellationToken: cancellationToken);

                var response = new DeleteAccountResponse
                {
                    Success = true,
                    Message = "تم حذف الحساب بنجاح"
                };

                return ResultDto<DeleteAccountResponse>.Ok(response, "تم حذف الحساب بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء حذف حساب المالك: {UserId}", _currentUserService.UserId);
                return ResultDto<DeleteAccountResponse>.Failed($"حدث خطأ أثناء حذف الحساب: {ex.Message}", "DELETE_ACCOUNT_ERROR");
            }
        }
    }
}
