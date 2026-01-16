using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Units;
using YemenBooking.Application.Features.Units;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using System.Collections.Generic;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.DynamicFields.DTOs;
using YemenBooking.Application.Features.Units.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Units.Queries.GetUnitById
{
    /// <summary>
    /// معالج استعلام الحصول على بيانات الوحدة بواسطة المعرف
    /// Query handler for GetUnitByIdQuery
    /// </summary>
    public class GetUnitByIdQueryHandler : IRequestHandler<GetUnitByIdQuery, ResultDto<UnitDetailsDto>>
    {
        private readonly IUnitRepository _unitRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetUnitByIdQueryHandler> _logger;

        public GetUnitByIdQueryHandler(
            IUnitRepository unitRepository,
            ICurrentUserService currentUserService,
            ILogger<GetUnitByIdQueryHandler> logger)
        {
            _unitRepository = unitRepository;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<ResultDto<UnitDetailsDto>> Handle(GetUnitByIdQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("جاري معالجة استعلام الوحدة: {UnitId}", request.UnitId);

            // الوصول إلى الوحدة مع البيانات المرتبطة
            var unit = await _unitRepository.GetQueryable()
                .AsNoTracking()
                .Include(u => u.Property)
                .Include(u => u.UnitType)
                .Include(u => u.FieldValues)
                    .ThenInclude(fv => fv.UnitTypeField)
                .FirstOrDefaultAsync(u => u.Id == request.UnitId, cancellationToken);

            if (unit == null)
            {
                return ResultDto<UnitDetailsDto>.Failure($"الوحدة بالمعرف {request.UnitId} غير موجود");
            }

            // التحقق من الصلاحيات
            var currentUser = await _currentUserService.GetCurrentUserAsync(cancellationToken);
            var role = _currentUserService.Role;
            var accountRole = _currentUserService.AccountRole;
            var userId = _currentUserService.UserId;
            var propertyOwnerId = unit.Property.OwnerId;
            
            _logger.LogInformation(
                "[GetUnitById] التحقق من الصلاحيات: UserId={UserId}, Role={Role}, AccountRole={AccountRole}, PropertyOwnerId={PropertyOwnerId}, UnitId={UnitId}",
                userId, role, accountRole, propertyOwnerId, request.UnitId);

            // التحقق من كون المستخدم Admin
            var isAdmin = string.Equals(role, "Admin", StringComparison.OrdinalIgnoreCase)
                || string.Equals(accountRole, "Admin", StringComparison.OrdinalIgnoreCase)
                || (_currentUserService.UserRoles?.Any(r => string.Equals(r, "Admin", StringComparison.OrdinalIgnoreCase)) ?? false);

            // التحقق من كون المستخدم هو مالك العقار
            bool isPropertyOwner = userId != Guid.Empty && userId == propertyOwnerId;
            
            _logger.LogInformation(
                "[GetUnitById] نتيجة التحقق: IsAdmin={IsAdmin}, IsPropertyOwner={IsPropertyOwner}, PropertyIsApproved={PropertyIsApproved}",
                isAdmin, isPropertyOwner, unit.Property.IsApproved);

            // السماح بالوصول إذا:
            // 1. المستخدم Admin
            // 2. المستخدم هو مالك العقار
            // 3. العقار معتمد (للزوار والمستخدمين العاديين)
            if (!isAdmin && !isPropertyOwner && !unit.Property.IsApproved)
            {
                _logger.LogWarning(
                    "[GetUnitById] رفض الوصول: المستخدم ليس Admin ولا مالك العقار والعقار غير معتمد. UserId={UserId}, PropertyOwnerId={PropertyOwnerId}",
                    userId, propertyOwnerId);
                return ResultDto<UnitDetailsDto>.Failure("ليس لديك صلاحية لعرض هذه الوحدة");
            }

            // التحويل إلى DTO
            var dto = new UnitDetailsDto
            {
                Id = unit.Id,
                PropertyId = unit.PropertyId,
                UnitTypeId = unit.UnitTypeId,
                Name = unit.Name,
                CustomFeatures = unit.CustomFeatures,
                PropertyName = unit.Property.Name,
                UnitTypeName = unit.UnitType.Name,
                PricingMethod = unit.PricingMethod.ToString(),
                FieldValues = unit.FieldValues.Select(fv => new UnitFieldValueDto
                {
                    FieldId = fv.UnitTypeFieldId,
                    FieldName = fv.UnitTypeField.FieldName,
                    DisplayName = fv.UnitTypeField.DisplayName,
                    FieldType = fv.UnitTypeField.FieldTypeId,
                    FieldValue = fv.FieldValue,
                    IsPrimaryFilter = fv.UnitTypeField.IsPrimaryFilter,
                }).ToList(),
                DynamicFields = new List<FieldGroupWithValuesDto>()
            };

            _logger.LogInformation("تم الحصول على بيانات الوحدة بنجاح: {UnitId}", request.UnitId);
            return ResultDto<UnitDetailsDto>.Succeeded(dto);
        }
    }
}