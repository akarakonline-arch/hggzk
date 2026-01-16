using System;
using System.Linq;
using System.Collections.Generic;
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

namespace YemenBooking.Application.Features.Policies.Queries.GetPolicyStats
{
    /// <summary>
    /// معالج استعلام الحصول على إحصائيات السياسات
    /// Handler for getting policy statistics
    /// </summary>
    public class GetPolicyStatsQueryHandler : IRequestHandler<GetPolicyStatsQuery, ResultDto<PolicyStatsDto>>
    {
        private readonly IPolicyRepository _policyRepository;
        private readonly ILogger<GetPolicyStatsQueryHandler> _logger;
        private readonly ICurrentUserService _currentUserService;

        public GetPolicyStatsQueryHandler(
            IPolicyRepository policyRepository,
            ILogger<GetPolicyStatsQueryHandler> logger,
            ICurrentUserService currentUserService)
        {
            _policyRepository = policyRepository;
            _logger = logger;
            _currentUserService = currentUserService;
        }

        public async Task<ResultDto<PolicyStatsDto>> Handle(GetPolicyStatsQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء الحصول على إحصائيات السياسات");

            var query = _policyRepository.GetQueryable()
                .Include(p => p.Property)
                .AsQueryable();

            if (!string.Equals(_currentUserService.Role, "Admin", StringComparison.OrdinalIgnoreCase))
            {
                var userId = _currentUserService.UserId;
                query = query.Where(p => p.Property != null && p.Property.OwnerId == userId);
            }
            else if (request.PropertyId.HasValue && request.PropertyId.Value != Guid.Empty)
            {
                // للمشرف: في حال تمرير PropertyId نقيد الإحصائيات عليه
                query = query.Where(p => p.PropertyId == request.PropertyId.Value);
            }

            var policies = await query.ToListAsync(cancellationToken);

            // احصائيات مبنية على جميع السياسات ضمن نطاق المستخدم / العقار
            var totalPolicies = policies.Count;

            // السياسات النشطة فقط (لمواءمة منطق قائمة السياسات التي تعرض النشطة فقط)
            var activePoliciesList = policies.Where(p => p.IsActive).ToList();
            var activePoliciesCount = activePoliciesList.Count;

            var stats = new PolicyStatsDto
            {
                // إجمالي السياسات (بغض النظر عن حالة التفعيل)
                TotalPolicies = totalPolicies,

                // عدد السياسات النشطة فقط، لضمان اتساقه مع ما يظهر في قائمة السياسات
                ActivePolicies = activePoliciesCount,

                // عدد أنواع السياسات المختلفة ضمن السياسات النشطة
                PoliciesByType = activePoliciesList
                    .GroupBy(p => p.Type)
                    .Count(),

                // توزيع أنواع السياسات النشطة
                PolicyTypeDistribution = activePoliciesList
                    .GroupBy(p => p.Type.ToString())
                    .ToDictionary(g => g.Key, g => g.Count()),

                // متوسط نافذة الإلغاء للسياسات النشطة فقط
                AverageCancellationWindow = activePoliciesList.Any()
                    ? activePoliciesList.Average(p => p.CancellationWindowDays)
                    : 0
            };

            _logger.LogInformation("تم الحصول على إحصائيات السياسات: Total={Total}, Active={Active}", 
                stats.TotalPolicies, stats.ActivePolicies);

            return ResultDto<PolicyStatsDto>.Succeeded(stats);
        }
    }
}
