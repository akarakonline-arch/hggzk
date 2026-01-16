using System;
using System.Collections.Generic;
using System.Linq;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Indexing.RediSearch;

public static class DateRangeHelper
{
    public static decimal CalculateTotalPrice(
        DateTime checkIn,
        DateTime checkOut,
        decimal basePrice,
        List<DailyUnitSchedule> schedules)
    {
        if (checkIn >= checkOut)
            throw new ArgumentException("تاريخ الوصول يجب أن يكون قبل تاريخ المغادرة");
        
        decimal totalPrice = 0;
        var currentDate = checkIn.Date;
        
        while (currentDate < checkOut.Date)
        {
            var dailyPrice = GetPriceForDate(currentDate, basePrice, schedules);
            totalPrice += dailyPrice;
            currentDate = currentDate.AddDays(1);
        }
        
        return totalPrice;
    }
    
    public static decimal GetPriceForDate(
        DateTime date,
        decimal basePrice,
        List<DailyUnitSchedule> schedules)
    {
        var schedule = schedules
            .FirstOrDefault(s => s.Date.Date == date.Date);
        
        if (schedule != null && schedule.PriceAmount.HasValue)
        {
            return schedule.PriceAmount.Value;
        }
        
        return basePrice;
    }
    
    public static decimal CalculateAveragePricePerNight(
        DateTime checkIn,
        DateTime checkOut,
        decimal basePrice,
        List<DailyUnitSchedule> schedules)
    {
        var totalPrice = CalculateTotalPrice(checkIn, checkOut, basePrice, schedules);
        var numberOfNights = (checkOut.Date - checkIn.Date).Days;
        
        if (numberOfNights <= 0)
            return basePrice;
        
        return totalPrice / numberOfNights;
    }
    
    public static bool IsAvailableForPeriod(
        DateTime checkIn,
        DateTime checkOut,
        List<DailyUnitSchedule> schedules)
    {
        if (checkIn >= checkOut)
            throw new ArgumentException("تاريخ الوصول يجب أن يكون قبل تاريخ المغادرة");
        
        if (schedules == null || !schedules.Any())
            return true;
        
        var currentDate = checkIn.Date;
        while (currentDate < checkOut.Date)
        {
            var schedule = schedules.FirstOrDefault(s => s.Date.Date == currentDate);
            if (schedule != null && schedule.Status != "Available")
            {
                return false;
            }
            currentDate = currentDate.AddDays(1);
        }
        
        return true;
    }
    
    public static bool PeriodsOverlap(
        DateTime start1, DateTime end1,
        DateTime start2, DateTime end2)
    {
        return start1 < end2 && start2 < end1;
    }
    
    public static List<DateTime> GetBlockedDates(
        DateTime checkIn,
        DateTime checkOut,
        List<DailyUnitSchedule> schedules)
    {
        var blockedDates = new List<DateTime>();
        
        if (schedules == null || !schedules.Any())
            return blockedDates;
        
        var currentDate = checkIn.Date;
        while (currentDate < checkOut.Date)
        {
            var schedule = schedules.FirstOrDefault(s => s.Date.Date == currentDate);
            if (schedule != null && schedule.Status != "Available")
            {
                blockedDates.Add(currentDate);
            }
            
            currentDate = currentDate.AddDays(1);
        }
        
        return blockedDates;
    }
    
    public static int CalculateNumberOfNights(DateTime checkIn, DateTime checkOut)
    {
        if (checkIn >= checkOut)
            throw new ArgumentException("تاريخ الوصول يجب أن يكون قبل تاريخ المغادرة");
        
        return (checkOut.Date - checkIn.Date).Days;
    }
    
    public static (decimal Min, decimal Max, decimal Avg) CalculatePriceRange(
        DateTime checkIn,
        DateTime checkOut,
        decimal basePrice,
        List<DailyUnitSchedule> schedules)
    {
        if (checkIn >= checkOut)
            throw new ArgumentException("تاريخ الوصول يجب أن يكون قبل تاريخ المغادرة");
        
        var dailyPrices = new List<decimal>();
        var currentDate = checkIn.Date;
        
        while (currentDate < checkOut.Date)
        {
            var dailyPrice = GetPriceForDate(currentDate, basePrice, schedules);
            dailyPrices.Add(dailyPrice);
            currentDate = currentDate.AddDays(1);
        }
        
        if (!dailyPrices.Any())
            return (basePrice, basePrice, basePrice);
        
        return (
            Min: dailyPrices.Min(),
            Max: dailyPrices.Max(),
            Avg: dailyPrices.Average()
        );
    }
    
    public static string BuildBlockedPeriodsString(List<DailyUnitSchedule> schedules)
    {
        if (schedules == null || !schedules.Any())
            return "";
        
        var now = DateTime.UtcNow;
        var blockedSchedules = schedules
            .Where(s => s.Status != "Available" && s.Date >= now.Date)
            .OrderBy(s => s.Date)
            .ToList();
        
        if (!blockedSchedules.Any())
            return "";
        
        var periods = new List<(long Start, long End)>();
        DateTime? periodStart = null;
        DateTime? periodEnd = null;
        
        foreach (var schedule in blockedSchedules)
        {
            if (periodStart == null)
            {
                periodStart = schedule.Date;
                periodEnd = schedule.Date.AddDays(1);
            }
            else if (schedule.Date == periodEnd)
            {
                periodEnd = schedule.Date.AddDays(1);
            }
            else
            {
                periods.Add((
                    new DateTimeOffset(periodStart.Value).ToUnixTimeSeconds(),
                    new DateTimeOffset(periodEnd.Value).ToUnixTimeSeconds()
                ));
                periodStart = schedule.Date;
                periodEnd = schedule.Date.AddDays(1);
            }
        }
        
        if (periodStart != null && periodEnd != null)
        {
            periods.Add((
                new DateTimeOffset(periodStart.Value).ToUnixTimeSeconds(),
                new DateTimeOffset(periodEnd.Value).ToUnixTimeSeconds()
            ));
        }
        
        return string.Join(",", periods.Select(p => $"{p.Start}-{p.End}"));
    }
    
    public static bool IsAvailableFromBlockedPeriodsString(
        DateTime checkIn,
        DateTime checkOut,
        string blockedPeriodsString)
    {
        if (string.IsNullOrWhiteSpace(blockedPeriodsString))
            return true;
        
        var checkInTs = new DateTimeOffset(checkIn).ToUnixTimeSeconds();
        var checkOutTs = new DateTimeOffset(checkOut).ToUnixTimeSeconds();
        
        var periods = blockedPeriodsString.Split(',', StringSplitOptions.RemoveEmptyEntries);
        
        foreach (var period in periods)
        {
            var parts = period.Split('-');
            if (parts.Length != 2)
                continue;
            
            if (long.TryParse(parts[0], out var start) && long.TryParse(parts[1], out var end))
            {
                if (checkInTs < end && start < checkOutTs)
                {
                    return false;
                }
            }
        }
        
        return true;
    }
}
