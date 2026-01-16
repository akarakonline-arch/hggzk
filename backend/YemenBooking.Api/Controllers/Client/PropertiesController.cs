using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Properties.Commands.PropertyToWishlist;
using YemenBooking.Application.Features.Properties.Commands.UpdateProperty;
using YemenBooking.Application.Features.Properties.Queries.SearchProperties;
using YemenBooking.Application.Features.Properties.Queries.GetPropertyDetails;
using YemenBooking.Application.Features.Properties.Queries.GetNearbyProperties;
using YemenBooking.Application.Features.Properties.Queries.GetCheckPropertyAvailability;
using YemenBooking.Application.Features.Policies.Queries.GetPropertyPolicies;
using YemenBooking.Application.Features.Policies.DTOs;
using YemenBooking.Application.Features.SearchAndFilters.DTOs;
using YemenBooking.Application.Features.Properties.DTOs;
using PropertyDetailsDto = YemenBooking.Application.Features.Properties.DTOs.PropertyDetailsDto;
using NearbyPropertyDto = YemenBooking.Application.Features.Properties.DTOs.NearbyPropertyDto;
using YemenBooking.Application.Common.Models;
using System.Collections.Generic;

namespace YemenBooking.Api.Controllers.Client
{
    /// <summary>
    /// كونترولر إدارة العقارات للعملاء
    /// Client Properties Management Controller
    /// </summary>
    public class PropertiesController : BaseClientController
    {
        private readonly ILogger<PropertiesController> _logger;

        public PropertiesController(IMediator mediator, ILogger<PropertiesController> logger) : base(mediator)
        {
            _logger = logger;
        }

        /// <summary>
        /// إضافة عقار لقائمة الرغبات للعميل
        /// Add property to client's wishlist
        /// </summary>
        /// <param name="command">بيانات إضافة للرغبات</param>
        /// <returns>نتيجة الإضافة</returns>
        [HttpPost("wishlist")]
        public async Task<ActionResult<ResultDto<bool>>> AddToWishlist([FromBody] ClientAddPropertyToWishlistCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// تحديث عداد المشاهدات للعقار
        /// Update property view count
        /// </summary>
        /// <param name="command">بيانات العقار</param>
        /// <returns>نتيجة التحديث</returns>
        [HttpPost("view-count")]
        public async Task<ActionResult<ResultDto<bool>>> UpdateViewCount([FromBody] ClientUpdatePropertyViewCountCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// البحث في العقارات (GET)
        /// Search properties (GET)
        /// </summary>
        /// <param name="query">معايير البحث</param>
        /// <returns>نتائج البحث</returns>
        [HttpGet("search")]
        [AllowAnonymous]
        public async Task<ActionResult<ResultDto<SearchPropertiesResponse>>> SearchProperties([FromQuery] SearchPropertiesQuery query)
        {
            // ━━━ Logging تشخيصي للحقول الديناميكية عند استقبال الطلب ━━━
            _logger.LogInformation("🔍 [Controller] استقبال طلب البحث GET /api/client/properties/search");
            
            if (query.DynamicFieldFilters != null)
            {
                _logger.LogInformation(
                    "📥 [Controller] DynamicFieldFilters استُقبل بـ {Count} حقل",
                    query.DynamicFieldFilters.Count);
                
                foreach (var filter in query.DynamicFieldFilters)
                {
                    _logger.LogInformation(
                        "   • [{Key}] = [{Value}] (Type: {Type})",
                        filter.Key,
                        filter.Value,
                        filter.Value?.GetType().Name ?? "null");
                }
            }
            else
            {
                _logger.LogWarning("⚠️ [Controller] DynamicFieldFilters = NULL في الطلب!");
            }
            
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// البحث في العقارات (POST)
        /// Search properties (POST) - allows complex filters in request body (e.g., DynamicFieldFilters)
        /// </summary>
        /// <param name="query">معايير البحث</param>
        /// <returns>نتائج البحث</returns>
        [HttpPost("search")]
        [AllowAnonymous]
        public async Task<ActionResult<ResultDto<SearchPropertiesResponse>>> SearchPropertiesPost([FromBody] SearchPropertiesQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// الحصول على تفاصيل عقار محدد
        /// Get specific property details
        /// </summary>
        /// <param name="id">معرف العقار</param>
        /// <param name="userId">معرف المستخدم (اختياري)</param>
        /// <returns>تفاصيل العقار</returns>
        [HttpGet("{id}")]
        [AllowAnonymous]
        public async Task<ActionResult<ResultDto<PropertyDetailsDto>>> GetPropertyDetails(Guid id, [FromQuery] Guid? userId = null)
        {
            // استخراج دور المستخدم من JWT Token إن وجد
            string? userRole = User.Identity?.IsAuthenticated == true 
                ? User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value 
                : null;
            
            var query = new GetPropertyDetailsQuery 
            { 
                PropertyId = id, 
                UserId = userId,
                UserRole = userRole
            };
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// الحصول على سياسات العقار
        /// Get property policies
        /// </summary>
        [HttpGet("{id}/policies")]
        [AllowAnonymous]
        public async Task<ActionResult<ResultDto<IEnumerable<PolicyDto>>>> GetPropertyPolicies(Guid id)
        {
            var query = new GetPropertyPoliciesQuery { PropertyId = id };
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// الحصول على العقارات القريبة
        /// Get nearby properties
        /// </summary>
        /// <param name="query">معايير الموقع</param>
        /// <returns>قائمة العقارات القريبة</returns>
        [HttpGet("nearby")]
        [AllowAnonymous]
        public async Task<ActionResult<ResultDto<List<NearbyPropertyDto>>>> GetNearbyProperties([FromQuery] GetNearbyPropertiesQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// التحقق من توفر العقار
        /// Check property availability
        /// </summary>
        /// <param name="query">معايير التحقق</param>
        /// <returns>حالة التوفر</returns>
        [HttpGet("availability")]
        [AllowAnonymous]
        public async Task<ActionResult<ResultDto<PropertyAvailabilityResponse>>> CheckAvailability([FromQuery] CheckPropertyAvailabilityQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

    }
}
