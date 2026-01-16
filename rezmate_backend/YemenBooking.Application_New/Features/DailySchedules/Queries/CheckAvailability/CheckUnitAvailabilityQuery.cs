using MediatR;
using YemenBooking.Application.Common.Models;
using System.Text.Json.Serialization;

namespace YemenBooking.Application.Features.DailySchedules.Queries.CheckAvailability;

public class CheckUnitAvailabilityQuery : IRequest<ResultDto<AvailabilityCheckResultDto>>
{
    public Guid UnitId { get; set; }

    [JsonPropertyName("checkInDate")]
    public DateTime StartDate { get; set; }

    [JsonPropertyName("checkOutDate")]
    public DateTime EndDate { get; set; }

    [JsonPropertyName("excludeBookingId")]
    public Guid? ExcludeBookingId { get; set; }
}

public class AvailabilityCheckResultDto
{
    public bool IsAvailable { get; set; }
    public int TotalDays { get; set; }
    public int AvailableDays { get; set; }
    public int UnavailableDays { get; set; }
    public List<DateTime> UnavailableDates { get; set; } = new();
    public string? Message { get; set; }

    /// <summary>
    /// إجمالي السعر للفترة المحددة (إن توفر)
    /// Total price for the requested period (if available)
    /// </summary>
    public decimal? TotalPrice { get; set; }

    /// <summary>
    /// متوسط سعر الليلة الواحدة في الفترة المحددة (إن توفر)
    /// Average price per night for the requested period (if available)
    /// </summary>
    public decimal? PricePerNight { get; set; }

    /// <summary>
    /// عملة السعر المحسوب
    /// Currency of the calculated price
    /// </summary>
    public string? Currency { get; set; }
}
