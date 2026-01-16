using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Policies;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.Policies.Commands.UpdateProperty
{
    /// <summary>
    /// معالج أمر تحديث سياسة الكيان
    /// </summary>
    public class UpdatePropertyPolicyCommandHandler : IRequestHandler<UpdatePropertyPolicyCommand, ResultDto<bool>>
    {
        private readonly IPolicyRepository _policyRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<UpdatePropertyPolicyCommandHandler> _logger;

        public UpdatePropertyPolicyCommandHandler(
            IPolicyRepository policyRepository,
            IPropertyRepository propertyRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<UpdatePropertyPolicyCommandHandler> logger)
        {
            _policyRepository = policyRepository;
            _propertyRepository = propertyRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
        }

        public async Task<ResultDto<bool>> Handle(UpdatePropertyPolicyCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء تحديث السياسة: PolicyId={PolicyId}", request.PolicyId);

            // التحقق من صحة المدخلات
            if (request.PolicyId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف السياسة مطلوب");

            // التحقق من وجود السياسة
            var policy = await _policyRepository.GetPolicyByIdAsync(request.PolicyId, cancellationToken);
            if (policy == null)
                return ResultDto<bool>.Failed("السياسة غير موجودة");

            // التحقق من وجود الكيان المرتبط
            var property = await _propertyRepository.GetPropertyByIdAsync(policy.PropertyId, cancellationToken);
            if (property == null)
                return ResultDto<bool>.Failed("الكيان المرتبط بالسياسة غير موجود");

            // التحقق من الصلاحيات (مالك الكيان أو مسؤول)
            var isAdmin = string.Equals(_currentUserService.Role, "Admin", StringComparison.OrdinalIgnoreCase);
            if (!isAdmin && property.OwnerId != _currentUserService.UserId)
                return ResultDto<bool>.Failed("غير مصرح لك بتحديث هذه السياسة");

            // تنفيذ التحديث
            policy.Type = request.Type;
            policy.Description = request.Description;

            if (!string.IsNullOrWhiteSpace(request.Rules))
            {
                PolicyRulesMapper.PopulatePolicyFromRulesJson(policy, request.Rules);
            }
            
            if (request.CancellationWindowDays.HasValue)
                policy.CancellationWindowDays = request.CancellationWindowDays.Value;
            if (request.RequireFullPaymentBeforeConfirmation.HasValue)
                policy.RequireFullPaymentBeforeConfirmation = request.RequireFullPaymentBeforeConfirmation.Value;
            if (request.MinimumDepositPercentage.HasValue)
                policy.MinimumDepositPercentage = request.MinimumDepositPercentage.Value;
            if (request.MinHoursBeforeCheckIn.HasValue)
                policy.MinHoursBeforeCheckIn = request.MinHoursBeforeCheckIn.Value;

            if (request.CancellationFreeCancel.HasValue)
                policy.CancellationFreeCancel = request.CancellationFreeCancel;
            if (request.CancellationFullRefund.HasValue)
                policy.CancellationFullRefund = request.CancellationFullRefund;
            if (request.CancellationRefundPercentage.HasValue)
                policy.CancellationRefundPercentage = request.CancellationRefundPercentage;
            if (request.CancellationDaysBeforeCheckIn.HasValue)
                policy.CancellationDaysBeforeCheckIn = request.CancellationDaysBeforeCheckIn;
            if (request.CancellationHoursBeforeCheckIn.HasValue)
                policy.CancellationHoursBeforeCheckIn = request.CancellationHoursBeforeCheckIn;
            if (request.CancellationNonRefundable.HasValue)
                policy.CancellationNonRefundable = request.CancellationNonRefundable;
            if (request.CancellationPenaltyAfterDeadline != null)
                policy.CancellationPenaltyAfterDeadline = request.CancellationPenaltyAfterDeadline;

            if (request.PaymentDepositRequired.HasValue)
                policy.PaymentDepositRequired = request.PaymentDepositRequired;
            if (request.PaymentFullPaymentRequired.HasValue)
                policy.PaymentFullPaymentRequired = request.PaymentFullPaymentRequired;
            if (request.PaymentDepositPercentage.HasValue)
                policy.PaymentDepositPercentage = request.PaymentDepositPercentage;
            if (request.PaymentAcceptCash.HasValue)
                policy.PaymentAcceptCash = request.PaymentAcceptCash;
            if (request.PaymentAcceptCard.HasValue)
                policy.PaymentAcceptCard = request.PaymentAcceptCard;
            if (request.PaymentPayAtProperty.HasValue)
                policy.PaymentPayAtProperty = request.PaymentPayAtProperty;
            if (request.PaymentCashPreferred.HasValue)
                policy.PaymentCashPreferred = request.PaymentCashPreferred;
            if (request.PaymentAcceptedMethods != null)
                policy.PaymentAcceptedMethods = request.PaymentAcceptedMethods;

            if (request.CheckInTime.HasValue)
                policy.CheckInTime = request.CheckInTime;
            if (request.CheckOutTime.HasValue)
                policy.CheckOutTime = request.CheckOutTime;
            if (request.CheckInFrom.HasValue)
                policy.CheckInFrom = request.CheckInFrom;
            if (request.CheckInUntil.HasValue)
                policy.CheckInUntil = request.CheckInUntil;
            if (request.CheckInFlexible.HasValue)
                policy.CheckInFlexible = request.CheckInFlexible;
            if (request.CheckInFlexibleCheckIn.HasValue)
                policy.CheckInFlexibleCheckIn = request.CheckInFlexibleCheckIn;
            if (request.CheckInRequiresCoordination.HasValue)
                policy.CheckInRequiresCoordination = request.CheckInRequiresCoordination;
            if (request.CheckInContactOwner.HasValue)
                policy.CheckInContactOwner = request.CheckInContactOwner;
            if (request.CheckInEarlyCheckInNote != null)
                policy.CheckInEarlyCheckInNote = request.CheckInEarlyCheckInNote;
            if (request.CheckInLateCheckOutNote != null)
                policy.CheckInLateCheckOutNote = request.CheckInLateCheckOutNote;
            if (request.CheckInLateCheckOutFee != null)
                policy.CheckInLateCheckOutFee = request.CheckInLateCheckOutFee;

            if (request.ChildrenAllowed.HasValue)
                policy.ChildrenAllowed = request.ChildrenAllowed;
            if (request.ChildrenFreeUnderAge.HasValue)
                policy.ChildrenFreeUnderAge = request.ChildrenFreeUnderAge;
            if (request.ChildrenHalfPriceUnderAge.HasValue)
                policy.ChildrenHalfPriceUnderAge = request.ChildrenHalfPriceUnderAge;
            if (request.ChildrenMaxChildrenPerRoom.HasValue)
                policy.ChildrenMaxChildrenPerRoom = request.ChildrenMaxChildrenPerRoom;
            if (request.ChildrenMaxChildren.HasValue)
                policy.ChildrenMaxChildren = request.ChildrenMaxChildren;
            if (request.ChildrenCribsNote != null)
                policy.ChildrenCribsNote = request.ChildrenCribsNote;
            if (request.ChildrenPlaygroundAvailable.HasValue)
                policy.ChildrenPlaygroundAvailable = request.ChildrenPlaygroundAvailable;
            if (request.ChildrenKidsMenuAvailable.HasValue)
                policy.ChildrenKidsMenuAvailable = request.ChildrenKidsMenuAvailable;

            if (request.PetsAllowed.HasValue)
                policy.PetsAllowed = request.PetsAllowed;
            if (request.PetsReason != null)
                policy.PetsReason = request.PetsReason;
            if (request.PetsFeeAmount.HasValue)
                policy.PetsFeeAmount = request.PetsFeeAmount;
            if (request.PetsMaxWeight != null)
                policy.PetsMaxWeight = request.PetsMaxWeight;
            if (request.PetsRequiresApproval.HasValue)
                policy.PetsRequiresApproval = request.PetsRequiresApproval;
            if (request.PetsNoFees.HasValue)
                policy.PetsNoFees = request.PetsNoFees;
            if (request.PetsPetFriendly.HasValue)
                policy.PetsPetFriendly = request.PetsPetFriendly;
            if (request.PetsOutdoorSpace.HasValue)
                policy.PetsOutdoorSpace = request.PetsOutdoorSpace;
            if (request.PetsStrict.HasValue)
                policy.PetsStrict = request.PetsStrict;

            if (request.ModificationAllowed.HasValue)
                policy.ModificationAllowed = request.ModificationAllowed;
            if (request.ModificationFreeModificationHours.HasValue)
                policy.ModificationFreeModificationHours = request.ModificationFreeModificationHours;
            if (request.ModificationFeesAfter != null)
                policy.ModificationFeesAfter = request.ModificationFeesAfter;
            if (request.ModificationFlexible.HasValue)
                policy.ModificationFlexible = request.ModificationFlexible;
            if (request.ModificationReason != null)
                policy.ModificationReason = request.ModificationReason;

            policy.Rules = PolicyRulesMapper.BuildRulesJson(policy);
                
            policy.UpdatedBy = _currentUserService.UserId;
            policy.UpdatedAt = DateTime.UtcNow;
            await _policyRepository.UpdatePropertyPolicyAsync(policy, cancellationToken);

            // تسجيل العملية في سجل التدقيق (يدوي) مع ذكر اسم المستخدم والمعرف
            var notes = $"تم تحديث السياسة {request.PolicyId} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
            await _auditService.LogAuditAsync(
                entityType: "PropertyPolicy",
                entityId: request.PolicyId,
                action: AuditAction.UPDATE,
                oldValues: null,
                newValues: System.Text.Json.JsonSerializer.Serialize(new { Updated = true }),
                performedBy: _currentUserService.UserId,
                notes: notes,
                cancellationToken: cancellationToken);

            _logger.LogInformation("اكتمل تحديث السياسة: PolicyId={PolicyId}", request.PolicyId);
            return ResultDto<bool>.Succeeded(true, "تم تحديث السياسة بنجاح");
        }
    }
} 