using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Application.Common.Authorization
{
    /// <summary>
    /// معالج التفويض للتحقق من ملكية العقار
    /// Authorization handler to verify property ownership
    /// </summary>
    public class PropertyOwnershipHandler : AuthorizationHandler<PropertyOwnershipRequirement>
    {
        private readonly ICurrentUserService _currentUserService;
        private readonly IPropertyRepository _propertyRepository;
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly ILogger<PropertyOwnershipHandler> _logger;

        public PropertyOwnershipHandler(
            ICurrentUserService currentUserService,
            IPropertyRepository propertyRepository,
            IHttpContextAccessor httpContextAccessor,
            ILogger<PropertyOwnershipHandler> logger)
        {
            _currentUserService = currentUserService;
            _propertyRepository = propertyRepository;
            _httpContextAccessor = httpContextAccessor;
            _logger = logger;
        }

        protected override async Task HandleRequirementAsync(
            AuthorizationHandlerContext context,
            PropertyOwnershipRequirement requirement)
        {
            var userId = _currentUserService.UserId;
            var userRole = _currentUserService.Role;

            if (userId == Guid.Empty)
            {
                _logger.LogWarning("Authorization failed: User is not authenticated");
                context.Fail();
                return;
            }

            // السماح للمسؤول
            if (requirement.AllowAdmin && string.Equals(userRole, "Admin", StringComparison.OrdinalIgnoreCase))
            {
                _logger.LogInformation("Authorization succeeded: User {UserId} is Admin", userId);
                context.Succeed(requirement);
                return;
            }

            // محاولة الحصول على PropertyId من Route أو Query أو Body
            var propertyId = await GetPropertyIdFromRequestAsync();

            if (!propertyId.HasValue || propertyId.Value == Guid.Empty)
            {
                _logger.LogWarning("Authorization failed: PropertyId not found in request");
                context.Fail();
                return;
            }

            // التحقق من ملكية العقار
            var property = await _propertyRepository.GetPropertyByIdAsync(propertyId.Value);
            if (property == null)
            {
                _logger.LogWarning("Authorization failed: Property {PropertyId} not found", propertyId.Value);
                context.Fail();
                return;
            }

            // التحقق من المالك
            if (property.OwnerId == userId)
            {
                _logger.LogInformation("Authorization succeeded: User {UserId} owns property {PropertyId}", 
                    userId, propertyId.Value);
                context.Succeed(requirement);
                return;
            }

            // التحقق من الموظف إذا كان مسموحاً
            if (requirement.AllowStaff && _currentUserService.IsStaffInProperty(propertyId.Value))
            {
                _logger.LogInformation("Authorization succeeded: User {UserId} is staff in property {PropertyId}", 
                    userId, propertyId.Value);
                context.Succeed(requirement);
                return;
            }

            _logger.LogWarning(
                "Authorization failed: User {UserId} does not have access to property {PropertyId}", 
                userId, propertyId.Value);
            context.Fail();
        }

        private async Task<Guid?> GetPropertyIdFromRequestAsync()
        {
            var httpContext = _httpContextAccessor.HttpContext;
            if (httpContext == null) return null;

            // من Route parameters
            if (httpContext.Request.RouteValues.TryGetValue("propertyId", out var routePropertyId))
            {
                if (Guid.TryParse(routePropertyId?.ToString(), out var propId))
                    return propId;
            }

            // من Query parameters
            if (httpContext.Request.Query.TryGetValue("propertyId", out var queryPropertyId))
            {
                if (Guid.TryParse(queryPropertyId.ToString(), out var propId))
                    return propId;
            }

            // من الـ Body (للـ POST/PUT)
            if (httpContext.Request.HasFormContentType)
            {
                if (httpContext.Request.Form.TryGetValue("propertyId", out var formPropertyId))
                {
                    if (Guid.TryParse(formPropertyId.ToString(), out var propId))
                        return propId;
                }
            }

            // من الـ Headers
            if (httpContext.Request.Headers.TryGetValue("X-Property-Id", out var headerPropertyId))
            {
                if (Guid.TryParse(headerPropertyId.ToString(), out var propId))
                    return propId;
            }

            return null;
        }
    }
}
