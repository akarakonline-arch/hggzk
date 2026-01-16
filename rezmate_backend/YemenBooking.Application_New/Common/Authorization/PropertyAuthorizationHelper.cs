using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Application.Common.Authorization
{
    /// <summary>
    /// مساعد التفويض للتحقق من ملكية العقار
    /// Authorization helper to verify property ownership
    /// </summary>
    public class PropertyAuthorizationHelper
    {
        private readonly ICurrentUserService _currentUserService;
        private readonly IPropertyRepository _propertyRepository;
        private readonly ILogger<PropertyAuthorizationHelper> _logger;

        public PropertyAuthorizationHelper(
            ICurrentUserService currentUserService,
            IPropertyRepository propertyRepository,
            ILogger<PropertyAuthorizationHelper> logger)
        {
            _currentUserService = currentUserService;
            _propertyRepository = propertyRepository;
            _logger = logger;
        }

        /// <summary>
        /// التحقق من صلاحية المستخدم للوصول إلى العقار
        /// Verify user has access to property
        /// </summary>
        /// <param name="propertyId">معرف العقار</param>
        /// <param name="allowStaff">السماح للموظفين</param>
        /// <param name="cancellationToken">رمز الإلغاء</param>
        /// <returns>Result indicating authorization status</returns>
        public async Task<ResultDto<bool>> VerifyPropertyAccessAsync(
            Guid propertyId,
            bool allowStaff = false,
            CancellationToken cancellationToken = default)
        {
            var userId = _currentUserService.UserId;
            var userRole = _currentUserService.Role;

            // السماح للمسؤول دائماً
            if (string.Equals(userRole, "Admin", StringComparison.OrdinalIgnoreCase))
            {
                _logger.LogDebug("Authorization succeeded: User {UserId} is Admin", userId);
                return ResultDto<bool>.Succeeded(true);
            }

            // التحقق من وجود العقار
            var property = await _propertyRepository.GetPropertyByIdAsync(propertyId, cancellationToken);
            if (property == null)
            {
                _logger.LogWarning("Property {PropertyId} not found", propertyId);
                return ResultDto<bool>.Failed("العقار غير موجود", errorCode: "PROPERTY_NOT_FOUND");
            }

            // التحقق من المالك
            if (property.OwnerId == userId)
            {
                _logger.LogDebug("Authorization succeeded: User {UserId} owns property {PropertyId}", 
                    userId, propertyId);
                return ResultDto<bool>.Succeeded(true);
            }

            // التحقق من الموظف إذا كان مسموحاً
            if (allowStaff && _currentUserService.IsStaffInProperty(propertyId))
            {
                _logger.LogDebug("Authorization succeeded: User {UserId} is staff in property {PropertyId}", 
                    userId, propertyId);
                return ResultDto<bool>.Succeeded(true);
            }

            _logger.LogWarning(
                "Authorization failed: User {UserId} does not have access to property {PropertyId}", 
                userId, propertyId);
            return ResultDto<bool>.Failed(
                "غير مصرح لك بالوصول إلى هذا العقار",
                errorCode: "UNAUTHORIZED_PROPERTY_ACCESS");
        }

        /// <summary>
        /// الحصول على معرف العقار الفعال للمستخدم
        /// Get effective property ID for user
        /// </summary>
        /// <param name="requestedPropertyId">معرف العقار المطلوب (اختياري)</param>
        /// <returns>معرف العقار الفعال</returns>
        public Guid? GetEffectivePropertyId(Guid? requestedPropertyId = null)
        {
            var userRole = _currentUserService.Role;

            // المسؤول يمكنه استخدام أي propertyId
            if (string.Equals(userRole, "Admin", StringComparison.OrdinalIgnoreCase))
            {
                return requestedPropertyId;
            }

            // المالك/الموظف يجب أن يستخدم propertyId الخاص به
            var userPropertyId = _currentUserService.PropertyId;
            
            if (!userPropertyId.HasValue)
            {
                _logger.LogWarning("User {UserId} has no associated property", _currentUserService.UserId);
                return null;
            }

            // تجاهل المعرف المطلوب وإرجاع معرف المستخدم
            if (requestedPropertyId.HasValue && requestedPropertyId.Value != userPropertyId.Value)
            {
                _logger.LogInformation(
                    "Overriding requested property {RequestedId} with user's property {UserId}", 
                    requestedPropertyId.Value, userPropertyId.Value);
            }

            return userPropertyId.Value;
        }

        /// <summary>
        /// التحقق من أن المستخدم يمكنه الوصول إلى جميع العقارات المحددة
        /// Verify user can access all specified properties
        /// </summary>
        public async Task<ResultDto<bool>> VerifyMultiplePropertiesAccessAsync(
            Guid[] propertyIds,
            bool allowStaff = false,
            CancellationToken cancellationToken = default)
        {
            foreach (var propertyId in propertyIds)
            {
                var result = await VerifyPropertyAccessAsync(propertyId, allowStaff, cancellationToken);
                if (!result.IsSuccess)
                {
                    return result;
                }
            }

            return ResultDto<bool>.Succeeded(true);
        }
    }
}
