using MediatR;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Amenities;
using YemenBooking.Application.Features.Amenities.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Amenities.Queries.GetAllAmenities;

/// <summary>
/// استعلام الحصول على جميع وسائل الراحة مع دعم الترقيم
/// Query to get all amenities with pagination support
/// </summary>
public class GetAllAmenitiesQuery : IRequest<ResultDto<PaginatedResultDto<AmenityDto>>>
{
    /// <summary>
    /// رقم الصفحة (افتراضي: 1)
    /// </summary>
    public int PageNumber { get; set; } = 1;
    
    /// <summary>
    /// حجم الصفحة (افتراضي: 10)
    /// </summary>
    public int PageSize { get; set; } = 10;
    
    /// <summary>
    /// نص البحث (اختياري)
    /// </summary>
    public string? SearchTerm { get; set; }
    
    /// <summary>
    /// فلترة حسب العقار (اختياري)
    /// </summary>
    public Guid? PropertyId { get; set; }
    
    /// <summary>
    /// فلترة المرافق المعينة فقط (اختياري)
    /// </summary>
    public bool? IsAssigned { get; set; }
    
    /// <summary>
    /// فلترة المرافق المجانية فقط (اختياري)
    /// </summary>
    public bool? IsFree { get; set; }
    
    /// <summary>
    /// فلترة حسب نوع العقار (اختياري)
    /// </summary>
    public Guid? PropertyTypeId { get; set; }
}