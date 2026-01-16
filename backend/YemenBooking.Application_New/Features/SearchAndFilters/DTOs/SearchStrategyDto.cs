using YemenBooking.Core.Indexing.Enums;

namespace YemenBooking.Application.Features.SearchAndFilters.DTOs;

/// <summary>
/// استراتيجية البحث المطبقة
/// Applied Search Strategy DTO
/// </summary>
public class SearchStrategyDto
{
    /// <summary>
    /// مستوى التخفيف
    /// Relaxation level
    /// </summary>
    public SearchRelaxationLevel Level { get; set; }

    /// <summary>
    /// اسم الاستراتيجية (بالعربية)
    /// Strategy name (Arabic)
    /// </summary>
    public string StrategyName { get; set; } = string.Empty;

    /// <summary>
    /// اسم الاستراتيجية (بالإنجليزية)
    /// Strategy name (English)
    /// </summary>
    public string StrategyNameEn { get; set; } = string.Empty;

    /// <summary>
    /// وصف الاستراتيجية
    /// Strategy description
    /// </summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// رسالة للمستخدم
    /// Message to user
    /// </summary>
    public string? UserMessage { get; set; }

    /// <summary>
    /// اقتراحات لتحسين البحث
    /// Suggestions to improve search
    /// </summary>
    public List<string> SuggestedActions { get; set; } = new();

    /// <summary>
    /// معلومات التخفيف التفصيلية
    /// Detailed relaxation info
    /// </summary>
    public SearchRelaxationInfoDto? RelaxationInfo { get; set; }

    /// <summary>
    /// إنشاء استراتيجية من مستوى معين
    /// Create strategy from level
    /// </summary>
    public static SearchStrategyDto FromLevel(SearchRelaxationLevel level)
    {
        return level switch
        {
            SearchRelaxationLevel.Exact => new SearchStrategyDto
            {
                Level = level,
                StrategyName = "تطابق دقيق",
                StrategyNameEn = "Exact Match",
                Description = "جميع معايير البحث مطابقة تماماً"
            },
            SearchRelaxationLevel.MinorRelaxation => new SearchStrategyDto
            {
                Level = level,
                StrategyName = "تخفيف بسيط",
                StrategyNameEn = "Minor Relaxation",
                Description = "توسيع طفيف في معايير البحث (15-20%)"
            },
            SearchRelaxationLevel.ModerateRelaxation => new SearchStrategyDto
            {
                Level = level,
                StrategyName = "تخفيف متوسط",
                StrategyNameEn = "Moderate Relaxation",
                Description = "توسيع متوسط في معايير البحث (30-40%)"
            },
            SearchRelaxationLevel.MajorRelaxation => new SearchStrategyDto
            {
                Level = level,
                StrategyName = "تخفيف كبير",
                StrategyNameEn = "Major Relaxation",
                Description = "توسيع كبير في معايير البحث (50%+)"
            },
            SearchRelaxationLevel.AlternativeSuggestions => new SearchStrategyDto
            {
                Level = level,
                StrategyName = "اقتراحات بديلة",
                StrategyNameEn = "Alternative Suggestions",
                Description = "عرض خيارات بديلة بمعايير أساسية"
            },
            _ => new SearchStrategyDto
            {
                Level = SearchRelaxationLevel.Exact,
                StrategyName = "تطابق دقيق",
                StrategyNameEn = "Exact Match",
                Description = "افتراضي"
            }
        };
    }
}
