using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Units.DTOs;
using YemenBooking.Application.Features.DynamicFields.DTOs;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Application.Features.Units.Queries.GetAdminUnitsSimple
{
    public class GetAdminUnitsSimpleQuery : IRequest<PaginatedResult<UnitDto>>
    {
        public Guid? PropertyId { get; set; }
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 20;
    }

    public class GetAdminUnitsSimpleQueryHandler : IRequestHandler<GetAdminUnitsSimpleQuery, PaginatedResult<UnitDto>>
    {
        private readonly IUnitRepository _unitRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetAdminUnitsSimpleQueryHandler> _logger;

        public GetAdminUnitsSimpleQueryHandler(
            IUnitRepository unitRepository,
            ICurrentUserService currentUserService,
            ILogger<GetAdminUnitsSimpleQueryHandler> logger)
        {
            _unitRepository = unitRepository;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<PaginatedResult<UnitDto>> Handle(GetAdminUnitsSimpleQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation(
                "[AdminSimpleUnits] Loading units. PropertyId={PropertyId}, Page={PageNumber}, Size={PageSize}",
                request.PropertyId, request.PageNumber, request.PageSize);

            var query = _unitRepository
                .GetQueryable()
                .AsNoTracking()
                .Include(u => u.Property)
                .Include(u => u.UnitType)
                .Where(u => !u.IsDeleted);

            if (await _currentUserService.IsInRoleAsync("Owner"))
            {
                var enforcedPropertyId = _currentUserService.PropertyId;
                if (enforcedPropertyId.HasValue && enforcedPropertyId.Value != Guid.Empty)
                {
                    query = query.Where(u => u.PropertyId == enforcedPropertyId.Value);
                }
                else
                {
                    var ownerId = _currentUserService.UserId;
                    query = query.Where(u => u.Property.OwnerId == ownerId);
                }
            }

            if (request.PropertyId.HasValue && request.PropertyId.Value != Guid.Empty)
            {
                var propertyId = request.PropertyId.Value;
                query = query.Where(u => u.PropertyId == propertyId);
            }

            var totalCount = await query.CountAsync(cancellationToken);

            var pageNumber = request.PageNumber <= 0 ? 1 : request.PageNumber;
            var pageSize = request.PageSize <= 0 ? 20 : request.PageSize;

            var units = await query
                .OrderBy(u => u.Name)
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            var items = units.Select(u => new UnitDto
            {
                Id = u.Id,
                PropertyId = u.PropertyId,
                UnitTypeId = u.UnitTypeId,
                Name = u.Name,
                CustomFeatures = u.CustomFeatures ?? string.Empty,
                PropertyName = u.Property?.Name ?? string.Empty,
                UnitTypeName = u.UnitType?.Name ?? string.Empty,
                PricingMethod = u.PricingMethod,
                FieldValues = new List<UnitFieldValueDto>(),
                DynamicFields = new List<FieldGroupWithValuesDto>(),
                DistanceKm = null,
                Images = new List<PropertyImageDto>(),
                AllowsCancellation = u.AllowsCancellation,
                CancellationWindowDays = u.CancellationWindowDays
            }).ToList();

            return new PaginatedResult<UnitDto>
            {
                Items = items,
                PageNumber = pageNumber,
                PageSize = pageSize,
                TotalCount = totalCount,
                Metadata = null
            };
        }
    }
}
