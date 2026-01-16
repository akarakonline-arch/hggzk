using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.DailySchedules.Commands.SetAvailability;

public class SetAvailabilityForPeriodCommand : IRequest<ResultDto<int>>
{
    public Guid UnitId { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? Reason { get; set; }
    public string? Notes { get; set; }
    public Guid? BookingId { get; set; }
    public bool OverwriteExisting { get; set; }
}
