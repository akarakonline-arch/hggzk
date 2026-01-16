using System;
using System.Collections.Generic;
using YemenBooking.Application.Features.Units.DTOs;

namespace YemenBooking.Application.Features.SearchAndFilters.DTOs {
    /// <summary>
    /// Response DTO for availability search
    /// </summary>
    public class SearchAvailabilityResponseDto
    {
        public IEnumerable<DailyUnitScheduleDto> Availabilities { get; set; } = new List<DailyUnitScheduleDto>();
        public IEnumerable<object> Conflicts { get; set; } = new List<object>();
        public int TotalCount { get; set; }
        public bool HasMore { get; set; }
    }

    /// <summary>
    /// Daily unit schedule DTO for availability search
    /// </summary>
    public class DailyUnitScheduleDto
    {
        public Guid Id { get; set; }
        public Guid UnitId { get; set; }
        public DateTime Date { get; set; }
        public string Status { get; set; } = string.Empty;
        public decimal? PriceAmount { get; set; }
        public string? Currency { get; set; }
        public string? PriceType { get; set; }
        public string? Reason { get; set; }
        public string? Notes { get; set; }
    }
}