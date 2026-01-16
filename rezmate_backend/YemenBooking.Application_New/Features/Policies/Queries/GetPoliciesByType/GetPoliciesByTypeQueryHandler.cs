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
                Rules = p.Rules,
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