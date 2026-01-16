using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Units;
using YemenBooking.Application.Features.Units.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Units.Queries.GetAvailableUnits;

/// <summary>
/// استعلام الحصول على الوحدات المتاحة
/// Query to get available units
/// </summary>
public class GetAvailableUnitsQuery : IRequest<ResultDto<AvailableUnitsResponse>>
{
    /// <summary>
    /// معرف الكيان
    /// </summary>
    public Guid PropertyId { get; set; }
    
    /// <summary>
    /// تاريخ الوصول
    /// </summary>
    public DateTime? CheckIn { get; set; }
    
    /// <summary>
    /// تاريخ المغادرة
    /// </summary>
    public DateTime? CheckOut { get; set; }
    
    /// <summary>
    /// عدد الضيوف (محسوب من عدد البالغين والأطفال)
    /// Total guests count (calculated from adults and children)
    /// </summary>
    public int GuestsCount { get; set; }
    
    /// <summary>
    /// عدد البالغين
    /// Number of adults
    /// </summary>
    public int? Adults { get; set; }
    
    /// <summary>
    /// عدد الأطفال
    /// Number of children
    /// </summary>
    public int? Children { get; set; }

    /// <summary>
    /// معرف نوع الوحدة (اختياري لفلترة الوحدات حسب النوع)
    /// Optional unit type ID filter
    /// </summary>
    public Guid? UnitTypeId { get; set; }
    
    /// <summary>
    /// العملة المطلوبة للتسعير
    /// Currency for pricing
    /// </summary>
    public string? Currency { get; set; }
}