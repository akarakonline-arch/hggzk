using Microsoft.AspNetCore.Mvc;
using MediatR;
using YemenBooking.Application.Features.DailySchedules.Commands.SetAvailability;
using YemenBooking.Application.Features.DailySchedules.Commands.SetPricing;
using YemenBooking.Application.Features.DailySchedules.Commands.CloneSchedule;
using YemenBooking.Application.Features.DailySchedules.Queries.CheckAvailability;
using YemenBooking.Application.Features.DailySchedules.Queries.GetSchedule;
using YemenBooking.Application.Features.DailySchedules.Queries.CalculatePrice;

namespace YemenBooking.Api.Controllers.Admin;

/// <summary>
/// كونترولر إدارة الجدول اليومي الموحد للوحدات (الإتاحة والتسعير)
/// Daily Unit Schedule Controller (Availability & Pricing)
/// </summary>
[ApiController]
[Route("api/admin/units/{unitId}/schedule")]
public class DailyScheduleController : BaseAdminController
{
    public DailyScheduleController(IMediator mediator) : base(mediator)
    {
    }

    #region Get Schedule (الحصول على الجدول)

    /// <summary>
    /// الحصول على الجدول اليومي لفترة محددة
    /// Get daily schedule for a specific period
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetScheduleForPeriod(
        Guid unitId, 
        [FromQuery] DateTime startDate, 
        [FromQuery] DateTime endDate)
    {
        var query = new GetScheduleForPeriodQuery
        {
            UnitId = unitId,
            StartDate = startDate,
            EndDate = endDate
        };

        var result = await _mediator.Send(query);
        return Ok(result);
    }

    /// <summary>
    /// الحصول على الجدول الشهري
    /// Get monthly schedule
    /// </summary>
    [HttpGet("month/{year}/{month}")]
    public async Task<IActionResult> GetMonthlySchedule(Guid unitId, int year, int month)
    {
        var startDate = new DateTime(year, month, 1);
        var endDate = startDate.AddMonths(1).AddDays(-1);
        
        var query = new GetScheduleForPeriodQuery
        {
            UnitId = unitId,
            StartDate = startDate,
            EndDate = endDate
        };

        var result = await _mediator.Send(query);
        return Ok(result);
    }

    #endregion

    #region Availability Management (إدارة الإتاحة)

    /// <summary>
    /// تعيين حالة الإتاحة لفترة محددة
    /// Set availability status for a specific period
    /// </summary>
    [HttpPost("availability")]
    public async Task<IActionResult> SetAvailability(Guid unitId, [FromBody] SetAvailabilityForPeriodCommand command)
    {
        command.UnitId = unitId;
        var result = await _mediator.Send(command);
        return Ok(result);
    }

    /// <summary>
    /// التحقق من توفر الوحدة في فترة محددة
    /// Check unit availability for a specific period
    /// </summary>
    [HttpGet("availability/check")]
    public async Task<IActionResult> CheckAvailability(
        Guid unitId, 
        [FromQuery] DateTime startDate, 
        [FromQuery] DateTime endDate)
    {
        var query = new CheckUnitAvailabilityQuery
        {
            UnitId = unitId,
            StartDate = startDate,
            EndDate = endDate
        };

        var result = await _mediator.Send(query);
        return Ok(result);
    }

    #endregion

    #region Pricing Management (إدارة التسعير)

    /// <summary>
    /// تعيين الأسعار لفترة محددة
    /// Set pricing for a specific period
    /// </summary>
    [HttpPost("pricing")]
    public async Task<IActionResult> SetPricing(Guid unitId, [FromBody] SetPricingForPeriodCommand command)
    {
        command.UnitId = unitId;
        var result = await _mediator.Send(command);
        return Ok(result);
    }

    /// <summary>
    /// حساب السعر الإجمالي لفترة محددة
    /// Calculate total price for a specific period
    /// </summary>
    [HttpPost("pricing/calculate")]
    public async Task<IActionResult> CalculatePrice(Guid unitId, [FromBody] CalculatePriceForPeriodQuery query)
    {
        query.UnitId = unitId;
        var result = await _mediator.Send(query);
        return Ok(result);
    }

    #endregion

    #region Clone Schedule (نسخ الجدول)

    /// <summary>
    /// نسخ الجدول من فترة إلى فترة أخرى
    /// Clone daily schedule from a source period to a target period
    /// </summary>
    [HttpPost("clone")]
    public async Task<IActionResult> CloneSchedule(Guid unitId, [FromBody] CloneScheduleCommand command)
    {
        command.UnitId = unitId;
        var result = await _mediator.Send(command);
        return Ok(result);
    }

    #endregion
}
