using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Infrastructure.Services;

public class PricingService
{
    private readonly IDailyUnitScheduleRepository _scheduleRepository;
    private readonly IUnitRepository _unitRepository;

    public PricingService(
        IDailyUnitScheduleRepository scheduleRepository,
        IUnitRepository unitRepository)
    {
        _scheduleRepository = scheduleRepository;
        _unitRepository = unitRepository;
    }

    public async Task<decimal> CalculatePriceAsync(Guid unitId, DateTime checkIn, DateTime checkOut)
    {
        var unit = await _unitRepository.GetByIdAsync(unitId);
        if (unit == null)
            throw new Exception("Unit not found");

        var totalPrice = 0m;
        var currentDate = checkIn.Date;

        // حساب متوسط الأسعار المتاحة كـ fallback
        var allSchedules = await _scheduleRepository.GetByUnitAndDateRangeAsync(
            unitId, 
            checkIn.Date, 
            checkOut.Date);
        
        var averagePrice = allSchedules?
            .Where(s => s.PriceAmount.HasValue)
            .Select(s => s.PriceAmount!.Value)
            .DefaultIfEmpty(0)
            .Average() ?? 0m;

        while (currentDate < checkOut.Date)
        {
            var dayPrice = await GetDayPriceAsync(unitId, currentDate, averagePrice);
            totalPrice += dayPrice;
            currentDate = currentDate.AddDays(1);
        }

        return totalPrice;
    }

    private async Task<decimal> GetDayPriceAsync(Guid unitId, DateTime date, decimal fallbackPrice = 0m)
    {
        var schedule = await _scheduleRepository.GetByUnitAndDateAsync(unitId, date);
        
        if (schedule == null || !schedule.PriceAmount.HasValue)
            return fallbackPrice;

        return schedule.PriceAmount.Value;
    }

    public async Task<Dictionary<DateTime, decimal>> GetPricingCalendarAsync(Guid unitId, int year, int month)
    {
        var unit = await _unitRepository.GetByIdAsync(unitId);
        if (unit == null)
            return new Dictionary<DateTime, decimal>();

        var startDate = new DateTime(year, month, 1);
        var endDate = startDate.AddMonths(1);
        
        var schedules = await _scheduleRepository.GetByUnitAndDateRangeAsync(unitId, startDate, endDate);
        
        // حساب متوسط الأسعار المتاحة كـ fallback
        var averagePrice = schedules?
            .Where(s => s.PriceAmount.HasValue)
            .Select(s => s.PriceAmount!.Value)
            .DefaultIfEmpty(0)
            .Average() ?? 0m;
        
        var calendar = new Dictionary<DateTime, decimal>();
        var currentDate = startDate;
        
        while (currentDate < endDate)
        {
            var schedule = schedules?.FirstOrDefault(s => s.Date.Date == currentDate.Date);
            var price = schedule?.PriceAmount ?? averagePrice;
            calendar[currentDate] = price;
            currentDate = currentDate.AddDays(1);
        }
        
        return calendar;
    }
}