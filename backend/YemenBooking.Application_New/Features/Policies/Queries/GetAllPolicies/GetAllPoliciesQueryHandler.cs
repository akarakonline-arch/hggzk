using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Policies;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.Policies.DTOs;
using YemenBooking.Application.Features;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.Policies.Queries.GetAllPolicies
{
    /// <summary>
    /// معالج استعلام الحصول على جميع السياسات مع الصفحات
    /// Handler for getting all policies with pagination
    /// </summary>
    public class GetAllPoliciesQueryHandler : IRequestHandler<GetAllPoliciesQuery, PaginatedResult<PolicyDto>>
    {
        private readonly IPolicyRepository _policyRepository;
        private readonly ILogger<GetAllPoliciesQueryHandler> _logger;
        private readonly ICurrentUserService _currentUserService;

        public GetAllPoliciesQueryHandler(
            IPolicyRepository policyRepository,
            ILogger<GetAllPoliciesQueryHandler> logger,
            ICurrentUserService currentUserService)
        {
            _policyRepository = policyRepository;
            _logger = logger;
            _currentUserService = currentUserService;
        }

        public async Task<PaginatedResult<PolicyDto>> Handle(GetAllPoliciesQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء الاستعلام عن جميع السياسات: Page={PageNumber}, Size={PageSize}, PropertyId={PropertyId}, PolicyType={PolicyType}", 
                request.PageNumber, request.PageSize, request.PropertyId, request.PolicyType);

            // بناء الاستعلام مع تحسينات الأداء
            // Note: HasQueryFilter already filters IsDeleted, but we add it explicitly for clarity
            var query = _policyRepository.GetQueryable()
                .Include(p => p.Property)
                .AsSplitQuery() // تحسين الأداء للـ Include
                .AsQueryable();
            
            // فلترة السياسات النشطة (نتحمل IsActive = null كـ true للسياسات القديمة)
            query = query.Where(p => p.IsActive);

            if (!string.Equals(_currentUserService.Role, "Admin", System.StringComparison.OrdinalIgnoreCase))
            {
                var userId = _currentUserService.UserId;
                query = query.Where(p => p.Property != null && p.Property.OwnerId == userId);
            }

            // تطبيق الفلاتر
            if (request.PropertyId.HasValue && request.PropertyId.Value != Guid.Empty)
            {
                _logger.LogInformation("تطبيق فلتر PropertyId: {PropertyId}", request.PropertyId.Value);
                query = query.Where(p => p.PropertyId == request.PropertyId.Value);
            }

            if (request.PolicyType.HasValue)
            {
                _logger.LogInformation("تطبيق فلتر PolicyType: {PolicyType}", request.PolicyType.Value);
                query = query.Where(p => p.Type == request.PolicyType.Value);
            }

            if (!string.IsNullOrWhiteSpace(request.SearchTerm))
            {
                var searchTerm = request.SearchTerm.ToLower();
                _logger.LogInformation("تطبيق فلتر البحث: {SearchTerm}", searchTerm);
                query = query.Where(p => 
                    p.Description.ToLower().Contains(searchTerm) ||
                    (p.Rules != null && p.Rules.ToLower().Contains(searchTerm)) ||
                    (p.Property != null && p.Property.Name.ToLower().Contains(searchTerm))
                );
            }

            // الحصول على العدد الكلي
            var totalCount = await query.CountAsync(cancellationToken);
            _logger.LogInformation("إجمالي السياسات بعد الفلترة: {TotalCount}", totalCount);

            // تطبيق الترتيب والصفحات
            var policies = await query
                .OrderByDescending(p => p.CreatedAt)
                .Skip((request.PageNumber - 1) * request.PageSize)
                .Take(request.PageSize)
                .ToListAsync(cancellationToken);

            var policyDtos = policies.Select(p => new PolicyDto
            {
                Id = p.Id,
                PropertyId = p.PropertyId,
                PropertyName = p.Property != null ? p.Property.Name : "غير متوفر",
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

            _logger.LogInformation("تم الحصول على {Count} سياسة من أصل {Total} في الصفحة {Page}", 
                policies.Count, totalCount, request.PageNumber);

            return new PaginatedResult<PolicyDto>
            {
                Items = policyDtos,
                PageNumber = request.PageNumber,
                PageSize = request.PageSize,
                TotalCount = totalCount
            };
        }
    }
}
