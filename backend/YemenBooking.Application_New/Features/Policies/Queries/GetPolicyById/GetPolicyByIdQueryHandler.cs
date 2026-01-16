using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Common.Exceptions;
using YemenBooking.Application.Features.Policies;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.Policies.DTOs;
using YemenBooking.Application.Features;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Common.Authorization;

namespace YemenBooking.Application.Features.Policies.Queries.GetPolicyById
{
    /// <summary>
    /// معالج استعلام الحصول على سياسة محددة
    /// Query handler for GetPolicyByIdQuery
    /// </summary>
    public class GetPolicyByIdQueryHandler : IRequestHandler<GetPolicyByIdQuery, ResultDto<PolicyDetailsDto>>
    {
        private readonly IPolicyRepository _policyRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly PropertyAuthorizationHelper _authHelper;
        private readonly ILogger<GetPolicyByIdQueryHandler> _logger;

        public GetPolicyByIdQueryHandler(
            IPolicyRepository policyRepository,
            IPropertyRepository propertyRepository,
            ICurrentUserService currentUserService,
            PropertyAuthorizationHelper authHelper,
            ILogger<GetPolicyByIdQueryHandler> logger)
        {
            _policyRepository = policyRepository;
            _propertyRepository = propertyRepository;
            _currentUserService = currentUserService;
            _authHelper = authHelper;
            _logger = logger;
        }

        public async Task<ResultDto<PolicyDetailsDto>> Handle(GetPolicyByIdQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("جاري معالجة استعلام السياسة: {PolicyId}", request.PolicyId);

            if (request.PolicyId == Guid.Empty)
                throw new ValidationException(nameof(request.PolicyId), "معرف السياسة غير صالح");

            var policy = await _policyRepository.GetPolicyByIdAsync(request.PolicyId, cancellationToken);
            if (policy == null)
                return ResultDto<PolicyDetailsDto>.Failure($"السياسة بالمعرف {request.PolicyId} غير موجودة");

            // ✅ Enhanced Authorization: التحقق من الوصول إلى العقار
            var authResult = await _authHelper.VerifyPropertyAccessAsync(
                policy.PropertyId, 
                allowStaff: false, 
                cancellationToken);
            
            if (!authResult.IsSuccess)
            {
                _logger.LogWarning(
                    "User {UserId} attempted unauthorized access to policy {PolicyId} of property {PropertyId}",
                    _currentUserService.UserId, request.PolicyId, policy.PropertyId);
                return ResultDto<PolicyDetailsDto>.Failed(authResult.Message ?? "غير مصرح بالوصول", authResult.ErrorCode);
            }

            var dto = new PolicyDetailsDto
            {
                Id = policy.Id,
                PropertyId = policy.PropertyId,
                PolicyType = policy.Type,
                Description = policy.Description,
                Rules = PolicyRulesMapper.BuildRulesJson(policy),
                CancellationFreeCancel = policy.CancellationFreeCancel,
                CancellationFullRefund = policy.CancellationFullRefund,
                CancellationRefundPercentage = policy.CancellationRefundPercentage,
                CancellationDaysBeforeCheckIn = policy.CancellationDaysBeforeCheckIn,
                CancellationHoursBeforeCheckIn = policy.CancellationHoursBeforeCheckIn,
                CancellationNonRefundable = policy.CancellationNonRefundable,
                CancellationPenaltyAfterDeadline = policy.CancellationPenaltyAfterDeadline,

                PaymentDepositRequired = policy.PaymentDepositRequired,
                PaymentFullPaymentRequired = policy.PaymentFullPaymentRequired,
                PaymentDepositPercentage = policy.PaymentDepositPercentage,
                PaymentAcceptCash = policy.PaymentAcceptCash,
                PaymentAcceptCard = policy.PaymentAcceptCard,
                PaymentPayAtProperty = policy.PaymentPayAtProperty,
                PaymentCashPreferred = policy.PaymentCashPreferred,
                PaymentAcceptedMethods = policy.PaymentAcceptedMethods,

                CheckInTime = policy.CheckInTime,
                CheckOutTime = policy.CheckOutTime,
                CheckInFrom = policy.CheckInFrom,
                CheckInUntil = policy.CheckInUntil,
                CheckInFlexible = policy.CheckInFlexible,
                CheckInFlexibleCheckIn = policy.CheckInFlexibleCheckIn,
                CheckInRequiresCoordination = policy.CheckInRequiresCoordination,
                CheckInContactOwner = policy.CheckInContactOwner,
                CheckInEarlyCheckInNote = policy.CheckInEarlyCheckInNote,
                CheckInLateCheckOutNote = policy.CheckInLateCheckOutNote,
                CheckInLateCheckOutFee = policy.CheckInLateCheckOutFee,

                ChildrenAllowed = policy.ChildrenAllowed,
                ChildrenFreeUnderAge = policy.ChildrenFreeUnderAge,
                ChildrenHalfPriceUnderAge = policy.ChildrenHalfPriceUnderAge,
                ChildrenMaxChildrenPerRoom = policy.ChildrenMaxChildrenPerRoom,
                ChildrenMaxChildren = policy.ChildrenMaxChildren,
                ChildrenCribsNote = policy.ChildrenCribsNote,
                ChildrenPlaygroundAvailable = policy.ChildrenPlaygroundAvailable,
                ChildrenKidsMenuAvailable = policy.ChildrenKidsMenuAvailable,

                PetsAllowed = policy.PetsAllowed,
                PetsReason = policy.PetsReason,
                PetsFeeAmount = policy.PetsFeeAmount,
                PetsMaxWeight = policy.PetsMaxWeight,
                PetsRequiresApproval = policy.PetsRequiresApproval,
                PetsNoFees = policy.PetsNoFees,
                PetsPetFriendly = policy.PetsPetFriendly,
                PetsOutdoorSpace = policy.PetsOutdoorSpace,
                PetsStrict = policy.PetsStrict,

                ModificationAllowed = policy.ModificationAllowed,
                ModificationFreeModificationHours = policy.ModificationFreeModificationHours,
                ModificationFeesAfter = policy.ModificationFeesAfter,
                ModificationFlexible = policy.ModificationFlexible,
                ModificationReason = policy.ModificationReason,
                CancellationWindowDays = policy.CancellationWindowDays,
                RequireFullPaymentBeforeConfirmation = policy.RequireFullPaymentBeforeConfirmation,
                MinimumDepositPercentage = policy.MinimumDepositPercentage,
                MinHoursBeforeCheckIn = policy.MinHoursBeforeCheckIn,
                CreatedAt = policy.CreatedAt,
                UpdatedAt = policy.UpdatedAt,
                IsActive = true
            };

            return ResultDto<PolicyDetailsDto>.Ok(dto, "تم جلب بيانات السياسة بنجاح");
        }
    }
} 