using MediatR;
using System;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.DailySchedules.Commands.CloneSchedule;

public class CloneScheduleCommand : IRequest<ResultDto<int>>
{
    public Guid UnitId { get; set; }
    public DateTime SourceStartDate { get; set; }
    public DateTime SourceEndDate { get; set; }
    public DateTime TargetStartDate { get; set; }
    public bool Overwrite { get; set; } = false;
}
