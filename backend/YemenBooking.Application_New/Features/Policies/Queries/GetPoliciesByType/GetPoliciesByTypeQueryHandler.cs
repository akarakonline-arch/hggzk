using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Common.Exceptions;
using YemenBooking.Application.Features.Policies;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.Policies.DTOs;
using YemenBooking.Application.Features;
 using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.Policies.Queries.GetPoliciesByType
{
    /// <summary>
    /// معالج استعلام الحصول على السياسات حسب النوع
    /// Query handler for GetPoliciesByTypeQuery
    /// </summary>
    public class GetPoliciesByTypeQueryHandler : IRequestHandler<GetPoliciesByTypeQuery, PaginatedResult<PolicyDto>>
    {
        private readonly IPolicyRepository _policyRepository;
        private readonly ILogger<GetPoliciesByTypeQueryHandler> _logger;
        private readonly ICurrentUserService _currentUserService;

        public GetPoliciesByTypeQueryHandler(
            IPolicyRepository policyRepository,
            ILogger<GetPoliciesByTypeQueryHandler> logger,
            ICurrentUserService currentUserService)
        {
            _policyRepository = policyRepository;
            _logger = logger;
            _currentUserService = currentUserService;
        }

        public async Task<PaginatedResult<PolicyDto>> Handle(GetPoliciesByTypeQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("جاري معالجة استعلام السياسات حسب النوع: {PolicyType}", request.PolicyType);

            var query = _policyRepository.GetQueryable()
                .Include(p => p.Property)
                .AsQueryable();

            query = query.Where(p => p.Type.ToString() == request.PolicyType.ToString());

            if (!string.Equals(_currentUserService.Role, "Admin", StringComparison.OrdinalIgnoreCase))
            {
                var userId = _currentUserService.UserId;
                query = query.Where(p => p.Property != null && p.Property.OwnerId == userId);
            }

            var policies = await query.ToListAsync(cancellationToken);

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
                IsActive = true
            }).ToList();

            var totalCount = dtos.Count;
            var items = dtos
                .Skip((request.PageNumber - 1) * request.PageSize)
                .Take(request.PageSize)
                .ToList();

            return new PaginatedResult<PolicyDto>
            {
                Items = items,
                PageNumber = request.PageNumber,
                PageSize = request.PageSize,
                TotalCount = totalCount
            };
        }
    }
} 