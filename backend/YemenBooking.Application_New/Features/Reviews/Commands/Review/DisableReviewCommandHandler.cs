using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Application.Features.Reviews.Commands.Review
{
    /// <summary>
    /// معالج أمر تعطيل تقييم
    /// </summary>
    public class DisableReviewCommandHandler : IRequestHandler<DisableReviewCommand, ResultDto<bool>>
    {
        private readonly IReviewRepository _reviewRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<DisableReviewCommandHandler> _logger;
        private readonly IUnitIndexingService _indexingService;

        public DisableReviewCommandHandler(
            IReviewRepository reviewRepository,
            IPropertyRepository propertyRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<DisableReviewCommandHandler> logger,
            IUnitIndexingService indexingService)
        {
            _reviewRepository = reviewRepository;
            _propertyRepository = propertyRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
            _indexingService = indexingService;
        }

        public async Task<ResultDto<bool>> Handle(DisableReviewCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء تعطيل التقييم: ReviewId={ReviewId}", request.ReviewId);

            if (request.ReviewId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف التقييم مطلوب");

            var review = await _reviewRepository.GetReviewByIdAsync(request.ReviewId, cancellationToken);
            if (review == null)
                return ResultDto<bool>.Failed("التقييم غير موجود");

            // السماح للمشرف أو مالك العقار (ضمن عقاره) بتعطيل التقييمات
            var isAdmin = string.Equals(_currentUserService.Role, "Admin", StringComparison.OrdinalIgnoreCase)
                || string.Equals(_currentUserService.AccountRole, "Admin", StringComparison.OrdinalIgnoreCase)
                || (_currentUserService.UserRoles?.Any(r => string.Equals(r, "Admin", StringComparison.OrdinalIgnoreCase)) ?? false);

            var isOwner = string.Equals(_currentUserService.Role, "Owner", StringComparison.OrdinalIgnoreCase)
                || string.Equals(_currentUserService.AccountRole, "Owner", StringComparison.OrdinalIgnoreCase)
                || (_currentUserService.UserRoles?.Any(r => string.Equals(r, "Owner", StringComparison.OrdinalIgnoreCase)) ?? false);

            _logger.LogInformation("🔐 Authorization Check: UserId={UserId}, Role={Role}, AccountRole={AccountRole}, isAdmin={IsAdmin}, isOwner={IsOwner}",
                _currentUserService.UserId, _currentUserService.Role, _currentUserService.AccountRole, isAdmin, isOwner);

            if (!isAdmin && !isOwner)
                return ResultDto<bool>.Failed("غير مصرح لك بتعطيل هذا التقييم");

            if (!isAdmin && isOwner)
            {
                if (review.PropertyId == Guid.Empty)
                    return ResultDto<bool>.Failed("غير مصرح لك بتعطيل هذا التقييم");

                var property = await _propertyRepository.GetPropertyByIdAsync(review.PropertyId, cancellationToken);
                
                _logger.LogInformation("🏠 Property Check: ReviewPropertyId={ReviewPropertyId}, PropertyOwnerId={PropertyOwnerId}, CurrentUserId={CurrentUserId}, Match={Match}",
                    review.PropertyId, 
                    property?.OwnerId, 
                    _currentUserService.UserId,
                    property?.OwnerId == _currentUserService.UserId);
                
                if (property == null || property.OwnerId != _currentUserService.UserId)
                    return ResultDto<bool>.Failed("غير مصرح لك بتعطيل هذا التقييم");
            }

            // إذا كان التقييم معطَّلاً بالفعل، اعتبر العملية ناجحة
            if (review.IsDisabled)
                return ResultDto<bool>.Succeeded(true, "التقييم معطَّل بالفعل");

            review.IsDisabled = true;
            // لا نريد أن يبقى التقييم محسوباً كمعلّق بعد تعطيله
            review.IsPendingApproval = false;
            review.UpdatedBy = _currentUserService.UserId;
            review.UpdatedAt = DateTime.UtcNow;

            await _reviewRepository.UpdateReviewAsync(review, cancellationToken);

            // تسجيل التدقيق
            var notes = $"تم تعطيل التقييم {review.Id} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
            await _auditService.LogAuditAsync(
                entityType: "Review",
                entityId: review.Id,
                action: AuditAction.UPDATE,
                oldValues: null,
                newValues: System.Text.Json.JsonSerializer.Serialize(new { Disabled = true }),
                performedBy: _currentUserService.UserId,
                notes: notes,
                cancellationToken: cancellationToken);

            // إعادة احتساب متوسط تقييم العقار بعد التعطيل
            var propertyId = review.PropertyId;
            if (propertyId != Guid.Empty)
            {
                try
                {
                    var (avgRating, totalReviews) = await _reviewRepository.GetPropertyRatingStatsAsync(propertyId, cancellationToken);
                    var property = await _propertyRepository.GetPropertyByIdAsync(propertyId, cancellationToken);
                    if (property != null)
                    {
                        property.AverageRating = (decimal)avgRating;
                        await _propertyRepository.UpdatePropertyAsync(property, cancellationToken);

                        // تحديث الفهرسة
                        try
                        {
                            await _indexingService.OnPropertyUpdatedAsync(property.Id, cancellationToken);
                        }
                        catch (Exception ex)
                        {
                            _logger.LogWarning(ex, "تعذرت الفهرسة المباشرة للعقار بعد تعطيل التقييم {PropertyId}", property.Id);
                        }
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "تعذر تحديث متوسط تقييم العقار بعد تعطيل التقييم {PropertyId}", propertyId);
                }
            }

            _logger.LogInformation("اكتمل تعطيل التقييم بنجاح: ReviewId={ReviewId}", request.ReviewId);
            return ResultDto<bool>.Succeeded(true, "تم تعطيل التقييم بنجاح");
        }
    }
}
