using System;
using System.Collections.Generic;
using System.Linq;
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

namespace YemenBooking.Application.Features.Policies.Queries.GetPropertyPolicies
{
    /// <summary>
    /// معالج استعلام الحصول على سياسات الكيان
    /// Query handler for GetPropertyPoliciesQuery
    /// </summary>
    public class GetPropertyPoliciesQueryHandler : IRequestHandler<GetPropertyPoliciesQuery, ResultDto<IEnumerable<PolicyDto>>>
    {
        private readonly IPolicyRepository _policyRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetPropertyPoliciesQueryHandler> _logger;

        public GetPropertyPoliciesQueryHandler(
            IPolicyRepository policyRepository,
            IPropertyRepository propertyRepository,
            ICurrentUserService currentUserService,
            ILogger<GetPropertyPoliciesQueryHandler> logger)
        {
            _policyRepository = policyRepository;
            _propertyRepository = propertyRepository;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<ResultDto<IEnumerable<PolicyDto>>> Handle(GetPropertyPoliciesQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("جاري معالجة استعلام سياسات الكيان: {PropertyId}", request.PropertyId);

            var isAdmin = string.Equals(_currentUserService.Role, "Admin", StringComparison.OrdinalIgnoreCase);
            var effectivePropertyId = request.PropertyId;

            // هذا الاستعلام مرتبط بعقار محدد: يجب تمرير PropertyId
            if (effectivePropertyId == Guid.Empty)
                throw new ValidationException(nameof(request.PropertyId), "معرف الكيان غير صالح");

            // Authorization for non-admins: must be the owner of the property
            if (!isAdmin)
            {
                var property = await _propertyRepository.GetPropertyByIdAsync(effectivePropertyId, cancellationToken);
                if (property == null || property.OwnerId != _currentUserService.UserId)
                    return ResultDto<IEnumerable<PolicyDto>>.Failed("غير مصرح لك بعرض سياسات هذا الكيان");
            }

            var policies = await _policyRepository.GetPropertyPoliciesAsync(effectivePropertyId, cancellationToken);

            var dtos = policies.Select(p => new PolicyDto
            {
                Id = p.Id,
                PropertyId = p.PropertyId,
                PolicyType = p.Type,
                Description = p.Description,
                Rules = PolicyRulesMapper.BuildRulesJson(p),

                CancellationFreeCancel = p.CancellationFreeCancel,
                CancellationFullRefund = p.CancellationFullRefund,
                CancellationRefundPercentage = p.CancellationRefundPercentage,
                CancellationDaysBeforeCheckIn = p.CancellationDaysBeforeCheckIn,
                CancellationHoursBeforeCheckIn = p.CancellationHoursBeforeCheckIn,
                CancellationNonRefundable = p.CancellationNonRefundable,
                CancellationPenaltyAfterDeadline = p.CancellationPenaltyAfterDeadline,

                PaymentDepositRequired = p.PaymentDepositRequired,
                PaymentFullPaymentRequired = p.PaymentFullPaymentRequired,
                PaymentDepositPercentage = p.PaymentDepositPercentage,
                PaymentAcceptCash = p.PaymentAcceptCash,
                PaymentAcceptCard = p.PaymentAcceptCard,
                PaymentPayAtProperty = p.PaymentPayAtProperty,
                PaymentCashPreferred = p.PaymentCashPreferred,
                PaymentAcceptedMethods = p.PaymentAcceptedMethods,

                CheckInTime = p.CheckInTime,
                CheckOutTime = p.CheckOutTime,
                CheckInFrom = p.CheckInFrom,
                CheckInUntil = p.CheckInUntil,
                CheckInFlexible = p.CheckInFlexible,
                CheckInFlexibleCheckIn = p.CheckInFlexibleCheckIn,
                CheckInRequiresCoordination = p.CheckInRequiresCoordination,
                CheckInContactOwner = p.CheckInContactOwner,
                CheckInEarlyCheckInNote = p.CheckInEarlyCheckInNote,
                CheckInLateCheckOutNote = p.CheckInLateCheckOutNote,
                CheckInLateCheckOutFee = p.CheckInLateCheckOutFee,

                ChildrenAllowed = p.ChildrenAllowed,
                ChildrenFreeUnderAge = p.ChildrenFreeUnderAge,
                ChildrenHalfPriceUnderAge = p.ChildrenHalfPriceUnderAge,
                ChildrenMaxChildrenPerRoom = p.ChildrenMaxChildrenPerRoom,
                ChildrenMaxChildren = p.ChildrenMaxChildren,
                ChildrenCribsNote = p.ChildrenCribsNote,
                ChildrenPlaygroundAvailable = p.ChildrenPlaygroundAvailable,
                ChildrenKidsMenuAvailable = p.ChildrenKidsMenuAvailable,

                PetsAllowed = p.PetsAllowed,
                PetsReason = p.PetsReason,
                PetsFeeAmount = p.PetsFeeAmount,
                PetsMaxWeight = p.PetsMaxWeight,
                PetsRequiresApproval = p.PetsRequiresApproval,
                PetsNoFees = p.PetsNoFees,
                PetsPetFriendly = p.PetsPetFriendly,
                PetsOutdoorSpace = p.PetsOutdoorSpace,
                PetsStrict = p.PetsStrict,

                ModificationAllowed = p.ModificationAllowed,
                ModificationFreeModificationHours = p.ModificationFreeModificationHours,
                ModificationFeesAfter = p.ModificationFeesAfter,
                ModificationFlexible = p.ModificationFlexible,
                ModificationReason = p.ModificationReason,
                CancellationWindowDays = p.CancellationWindowDays,
                RequireFullPaymentBeforeConfirmation = p.RequireFullPaymentBeforeConfirmation,
                MinimumDepositPercentage = p.MinimumDepositPercentage,
                MinHoursBeforeCheckIn = p.MinHoursBeforeCheckIn,
                CreatedAt = p.CreatedAt,
                UpdatedAt = p.UpdatedAt,
                IsActive = p.IsActive
            }).ToList();

            return ResultDto<IEnumerable<PolicyDto>>.Ok(dtos, "تم جلب سياسات الكيان بنجاح");
        }
    }
}
 