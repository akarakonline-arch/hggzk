namespace YemenBooking.Core.Indexing.Enums;

/// <summary>
/// مستويات تخفيف معايير البحث
/// Search Relaxation Levels
/// </summary>
public enum SearchRelaxationLevel
{
    /// <summary>
    /// بحث دقيق - تطابق تام مع جميع المعايير
    /// Exact match - all criteria must match
    /// </summary>
    Exact = 0,

    /// <summary>
    /// تخفيف بسيط - 15-20% توسع في المعايير
    /// Minor relaxation - 15-20% expansion in criteria
    /// </summary>
    MinorRelaxation = 1,

    /// <summary>
    /// تخفيف متوسط - 30-40% توسع في المعايير
    /// Moderate relaxation - 30-40% expansion in criteria
    /// </summary>
    ModerateRelaxation = 2,

    /// <summary>
    /// تخفيف كبير - 50%+ توسع في المعايير
    /// Major relaxation - 50%+ expansion in criteria
    /// </summary>
    MajorRelaxation = 3,

    /// <summary>
    /// اقتراحات بديلة - البحث بمعايير أساسية فقط
    /// Alternative suggestions - search with basic criteria only
    /// </summary>
    AlternativeSuggestions = 4
}
