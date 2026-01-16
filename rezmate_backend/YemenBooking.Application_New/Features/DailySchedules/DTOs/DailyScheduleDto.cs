namespace YemenBooking.Application.Features.DailySchedules.DTOs;

public class DailyScheduleDto
{
    public Guid Id { get; set; }
    public Guid UnitId { get; set; }
    public DateTime Date { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? Reason { get; set; }
    public string? Notes { get; set; }
    public Guid? BookingId { get; set; }
    public decimal? PriceAmount { get; set; }
    public string? Currency { get; set; }
    public string? PriceType { get; set; }
    public string? PricingTier { get; set; }
    public decimal? PercentageChange { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
    public TimeSpan? StartTime { get; set; }
    public TimeSpan? EndTime { get; set; }
    public string? CreatedBy { get; set; }
    public string? ModifiedBy { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
