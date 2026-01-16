using MediatR;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Amenities;
using YemenBooking.Application.Features.Amenities.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Amenities.Queries.GetAllAmenities;

/// <summary>
/// استعلام الحصول على جميع وسائل الراحة مع pagination
/// Query to get all amenities with pagination
/// </summary>
public class GetAllAmenitiesQuery : IRequest<ResultDto<PaginatedResultDto<AmenityDto>>>
{
    /// <summary>
    /// رقم الصفحة
    /// Page number (1-based)
    /// </summary>
    public int PageNumber { get; set; } = 1;

    /// <summary>
    /// حجم الصفحة
    /// Page size
    /// </summary>
    public int PageSize { get; set; } = 10;

    /// <summary>
    /// كلمة البحث
    /// Search term
    /// </summary>
    public string? SearchTerm { get; set; }

    /// <summary>
    /// معرف العقار (للفلترة)
    /// Property ID for filtering
    /// </summary>
    public Guid? PropertyId { get; set; }

    /// <summary>
    /// هل مخصص (للفلترة)
    /// Is assigned filter
    /// </summary>
    public bool? IsAssigned { get; set; }

    /// <summary>
    /// هل مجاني (للفلترة)
    /// Is free filter
    /// </summary>
    public bool? IsFree { get; set; }

    /// <summary>
    /// معرف نوع العقار (للفلترة)
    /// Property type ID for filtering
    /// </summary>
    public Guid? PropertyTypeId { get; set; }
}