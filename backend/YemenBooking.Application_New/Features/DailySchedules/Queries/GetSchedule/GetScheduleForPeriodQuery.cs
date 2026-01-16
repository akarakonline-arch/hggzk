using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.DailySchedules.DTOs;

namespace YemenBooking.Application.Features.DailySchedules.Queries.GetSchedule;

public class GetScheduleForPeriodQuery : IRequest<ResultDto<List<DailyScheduleDto>>>
{
    public Guid UnitId { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public bool IncludeUnit { get; set; }
    public bool IncludeBooking { get; set; }
}
