using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Policies;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.Policies.Commands.CreateProperty
{
    /// <summary>
    /// معالج أمر إنشاء سياسة جديدة للكيان
    /// </summary>
    public class CreatePropertyPolicyCommandHandler : IRequestHandler<CreatePropertyPolicyCommand, ResultDto<Guid>>
    {
        private readonly IPropertyRepository _propertyRepository;
        private readonly IPolicyRepository _policyRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<CreatePropertyPolicyCommandHandler> _logger;

        public CreatePropertyPolicyCommandHandler(
            IPropertyRepository propertyRepository,
            IPolicyRepository policyRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<CreatePropertyPolicyCommandHandler> logger)
        {
            _propertyRepository = propertyRepository;
            _policyRepository = policyRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
        }

        public async Task<ResultDto<Guid>> Handle(CreatePropertyPolicyCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء إنشاء سياسة للكيان: PropertyId={PropertyId}, Type={Type}", request.PropertyId, request.Type);

            // التحقق من صحة المدخلات
            if (string.IsNullOrWhiteSpace(request.Description))
                return ResultDto<Guid>.Failed("وصف السياسة مطلوب");

            var isAdmin = string.Equals(_currentUserService.Role, "Admin", StringComparison.OrdinalIgnoreCase);

            // للأدمن: يجب تمرير PropertyId صراحةً
            if (isAdmin && request.PropertyId == Guid.Empty)
                return ResultDto<Guid>.Failed("معرف الكيان مطلوب");

            // لغير الأدمن: يجب تحديد PropertyId (إما من الطلب أو من بيانات المستخدم إذا كانت متاحة)
            if (!isAdmin)
            {
                if (request.PropertyId == Guid.Empty)
                {
                    var userPropId = _currentUserService.PropertyId;
                    if (userPropId.HasValue && userPropId.Value != Guid.Empty)
                    {
                        request.PropertyId = userPropId.Value;
                    }
                }

                if (request.PropertyId == Guid.Empty)
                    return ResultDto<Guid>.Failed("معرف الكيان مطلوب");
            }

            // التحقق من وجود الكيان
            var property = await _propertyRepository.GetPropertyByIdAsync(request.PropertyId, cancellationToken);
            if (property == null)
                return ResultDto<Guid>.Failed("الكيان غير موجود");

            // التحقق من الصلاحيات (مالك الكيان أو مسؤول)
            if (!isAdmin && property.OwnerId != _currentUserService.UserId)
                return ResultDto<Guid>.Failed("غير مصرح لك بإنشاء سياسة لهذا الكيان");

            // التحقق من عدم وجود سياسة من نفس النوع مسبقًا
            bool exists = await _policyRepository.ExistsAsync(p => p.PropertyId == request.PropertyId && p.Type == request.Type, cancellationToken);
            if (exists)
                return ResultDto<Guid>.Failed("تمت إضافة سياسة من هذا النوع مسبقًا");

            // إنشاء كيان السياسة
            var policy = new PropertyPolicy
            {
                PropertyId = request.PropertyId,
                Type = request.Type,
                Description = request.Description,
                CancellationWindowDays = request.CancellationWindowDays,
                RequireFullPaymentBeforeConfirmation = request.RequireFullPaymentBeforeConfirmation,
                MinimumDepositPercentage = request.MinimumDepositPercentage,
                MinHoursBeforeCheckIn = request.MinHoursBeforeCheckIn,
                CancellationFreeCancel = request.CancellationFreeCancel,
                CancellationFullRefund = request.CancellationFullRefund,
                CancellationRefundPercentage = request.CancellationRefundPercentage,
                CancellationDaysBeforeCheckIn = request.CancellationDaysBeforeCheckIn,
                CancellationHoursBeforeCheckIn = request.CancellationHoursBeforeCheckIn,
                CancellationNonRefundable = request.CancellationNonRefundable,
                CancellationPenaltyAfterDeadline = request.CancellationPenaltyAfterDeadline,
                PaymentDepositRequired = request.PaymentDepositRequired,
                PaymentFullPaymentRequired = request.PaymentFullPaymentRequired,
                PaymentDepositPercentage = request.PaymentDepositPercentage,
                PaymentAcceptCash = request.PaymentAcceptCash,
                PaymentAcceptCard = request.PaymentAcceptCard,
                PaymentPayAtProperty = request.PaymentPayAtProperty,
                PaymentCashPreferred = request.PaymentCashPreferred,
                PaymentAcceptedMethods = request.PaymentAcceptedMethods,
                CheckInTime = request.CheckInTime,
                CheckOutTime = request.CheckOutTime,
                CheckInFrom = request.CheckInFrom,
                CheckInUntil = request.CheckInUntil,
                CheckInFlexible = request.CheckInFlexible,
                CheckInFlexibleCheckIn = request.CheckInFlexibleCheckIn,
                CheckInRequiresCoordination = request.CheckInRequiresCoordination,
                CheckInContactOwner = request.CheckInContactOwner,
                CheckInEarlyCheckInNote = request.CheckInEarlyCheckInNote,
                CheckInLateCheckOutNote = request.CheckInLateCheckOutNote,
                CheckInLateCheckOutFee = request.CheckInLateCheckOutFee,
                ChildrenAllowed = request.ChildrenAllowed,
                ChildrenFreeUnderAge = request.ChildrenFreeUnderAge,
                ChildrenHalfPriceUnderAge = request.ChildrenHalfPriceUnderAge,
                ChildrenMaxChildrenPerRoom = request.ChildrenMaxChildrenPerRoom,
                ChildrenMaxChildren = request.ChildrenMaxChildren,
                ChildrenCribsNote = request.ChildrenCribsNote,
                ChildrenPlaygroundAvailable = request.ChildrenPlaygroundAvailable,
                ChildrenKidsMenuAvailable = request.ChildrenKidsMenuAvailable,
                PetsAllowed = request.PetsAllowed,
                PetsReason = request.PetsReason,
                PetsFeeAmount = request.PetsFeeAmount,
                PetsMaxWeight = request.PetsMaxWeight,
                PetsRequiresApproval = request.PetsRequiresApproval,
                PetsNoFees = request.PetsNoFees,
                PetsPetFriendly = request.PetsPetFriendly,
                PetsOutdoorSpace = request.PetsOutdoorSpace,
                PetsStrict = request.PetsStrict,
                ModificationAllowed = request.ModificationAllowed,
                ModificationFreeModificationHours = request.ModificationFreeModificationHours,
                ModificationFeesAfter = request.ModificationFeesAfter,
                ModificationFlexible = request.ModificationFlexible,
                ModificationReason = request.ModificationReason,
                CreatedBy = _currentUserService.UserId,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                IsActive = true, // ✅ تفعيل السياسة صراحةً
                IsDeleted = false // ✅ التأكد من أنها غير محذوفة
            };

            if (!string.IsNullOrWhiteSpace(request.Rules))
            {
                policy.Rules = request.Rules;
                PolicyRulesMapper.PopulatePolicyFromRulesJson(policy, request.Rules);
            }
            else
            {
                var rulesDict = PolicyRulesMapper.BuildRulesDictionary(policy);
                if (rulesDict.Count == 0)
                    return ResultDto<Guid>.Failed("قواعد السياسة مطلوبة");

                policy.Rules = PolicyRulesMapper.BuildRulesJson(policy);
            }
            var created = await _policyRepository.CreatePropertyPolicyAsync(policy, cancellationToken);

            // تسجيل العملية في سجل التدقيق (يدوي) مع ذكر اسم المستخدم والمعرف
            var notes = $"تم إنشاء سياسة جديدة للكيان {request.PropertyId} من النوع {request.Type} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
            await _auditService.LogAuditAsync(
                entityType: "PropertyPolicy",
                entityId: created.Id,
                action: AuditAction.CREATE,
                oldValues: null,
                newValues: System.Text.Json.JsonSerializer.Serialize(new { PolicyId = created.Id, Type = request.Type }),
                performedBy: _currentUserService.UserId,
                notes: notes,
                cancellationToken: cancellationToken);

            _logger.LogInformation("اكتمل إنشاء السياسة بنجاح: PolicyId={PolicyId}", created.Id);
            return ResultDto<Guid>.Succeeded(created.Id, "تم إنشاء السياسة بنجاح");
        }
    }
} 