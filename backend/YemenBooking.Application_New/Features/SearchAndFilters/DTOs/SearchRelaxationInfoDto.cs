using YemenBooking.Core.Indexing.Enums;

namespace YemenBooking.Application.Features.SearchAndFilters.DTOs;

/// <summary>
/// معلومات تفصيلية عن تخفيف معايير البحث
/// Search Relaxation Information DTO
/// </summary>
public class SearchRelaxationInfoDto
{
    /// <summary>
    /// مستوى التخفيف المطبق
    /// Applied relaxation level
    /// </summary>
    public SearchRelaxationLevel RelaxationLevel { get; set; }

    /// <summary>
    /// قائمة الفلاتر التي تم تخفيفها
    /// List of relaxed filters
    /// </summary>
    public List<string> RelaxedFilters { get; set; } = new();

    /// <summary>
    /// المعايير الأصلية (قبل التخفيف)
    /// Original criteria (before relaxation)
    /// </summary>
    public Dictionary<string, object> OriginalCriteria { get; set; } = new();

    /// <summary>
    /// المعايير الفعلية (بعد التخفيف)
    /// Actual criteria (after relaxation)
    /// </summary>
    public Dictionary<string, object> ActualCriteria { get; set; } = new();

    /// <summary>
    /// هل تم تطبيق تخفيف؟
    /// Was relaxation applied?
    /// </summary>
    public bool WasRelaxed => RelaxationLevel > SearchRelaxationLevel.Exact;

    /// <summary>
    /// عدد الفلاتر المخففة
    /// Number of relaxed filters
    /// </summary>
    public int RelaxedFiltersCount => RelaxedFilters.Count;
}
