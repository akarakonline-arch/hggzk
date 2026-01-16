using System;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Indexing.Enums;

namespace YemenBooking.Application.Features.SearchAndFilters.DTOs
{
    /// <summary>
    /// استجابة البحث عن العقارات
    /// Search properties response
    /// </summary>
    public class SearchPropertiesResponse
    {
        /// <summary>
        /// قائمة العقارات المطابقة للبحث
        /// List of properties matching the search
        /// </summary>
        public List<PropertySearchResultDto> Properties { get; set; } = new();

        /// <summary>
        /// العدد الإجمالي للنتائج
        /// Total count of results
        /// </summary>
        public int TotalCount { get; set; }

        /// <summary>
        /// رقم الصفحة الحالية
        /// Current page number
        /// </summary>
        public int CurrentPage { get; set; }

        /// <summary>
        /// حجم الصفحة
        /// Page size
        /// </summary>
        public int PageSize { get; set; }

        /// <summary>
        /// العدد الإجمالي للصفحات
        /// Total pages count
        /// </summary>
        public int TotalPages { get; set; }

        /// <summary>
        /// هل يوجد صفحة سابقة
        /// Whether there is a previous page
        /// </summary>
        public bool HasPreviousPage { get; set; }

        /// <summary>
        /// هل يوجد صفحة تالية
        /// Whether there is a next page
        /// </summary>
        public bool HasNextPage { get; set; }

        /// <summary>
        /// فلاتر البحث المطبقة
        /// Applied search filters
        /// </summary>
        public SearchFiltersDto AppliedFilters { get; set; } = null!;

        /// <summary>
        /// وقت البحث بالميلي ثانية
        /// Search time in milliseconds
        /// </summary>
        public long SearchTimeMs { get; set; }

        /// <summary>
        /// إحصائيات البحث
        /// Search statistics
        /// </summary>
        public SearchStatisticsDto Statistics { get; set; } = null!;

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // معلومات استراتيجية Fallback Search
        // Fallback Search Strategy Information
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        /// <summary>
        /// مستوى التخفيف المستخدم في البحث
        /// Relaxation level used in search
        /// </summary>
        public SearchRelaxationLevel RelaxationLevel { get; set; } = SearchRelaxationLevel.Exact;

        /// <summary>
        /// هل تم تطبيق تخفيف على معايير البحث
        /// Whether search criteria were relaxed
        /// </summary>
        public bool WasRelaxed => RelaxationLevel > SearchRelaxationLevel.Exact;

        /// <summary>
        /// قائمة المعايير التي تم تخفيفها
        /// List of relaxed criteria
        /// </summary>
        public List<string>? RelaxedFilters { get; set; }

        /// <summary>
        /// رسالة للمستخدم توضح نتيجة البحث
        /// User message explaining search results
        /// </summary>
        public string? UserMessage { get; set; }

        /// <summary>
        /// اقتراحات لتحسين نتائج البحث
        /// Suggestions to improve search results
        /// </summary>
        public List<string>? SuggestedActions { get; set; }
    }
}
