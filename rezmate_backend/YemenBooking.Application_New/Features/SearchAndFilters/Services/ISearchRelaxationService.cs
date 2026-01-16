using YemenBooking.Core.Indexing.Enums;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Core.Indexing.Options;

namespace YemenBooking.Application.Features.SearchAndFilters.Services;

/// <summary>
/// خدمة تخفيف معايير البحث التدريجية
/// Search Relaxation Service Interface
/// </summary>
public interface ISearchRelaxationService
{
    /// <summary>
    /// تطبيق التخفيف على معايير البحث حسب المستوى المحدد
    /// Apply relaxation to search criteria based on specified level
    /// </summary>
    /// <param name="originalRequest">طلب البحث الأصلي</param>
    /// <param name="level">مستوى التخفيف</param>
    /// <param name="options">خيارات التخفيف</param>
    /// <param name="relaxedFilters">قائمة الفلاتر المخففة (output)</param>
    /// <returns>طلب بحث مخفف</returns>
    UnitSearchRequest RelaxSearchCriteria(
        UnitSearchRequest originalRequest,
        SearchRelaxationLevel level,
        FallbackSearchOptions options,
        out List<string> relaxedFilters);

    /// <summary>
    /// استخراج المعايير من طلب البحث لعرضها
    /// Extract criteria from search request for display
    /// </summary>
    /// <param name="request">طلب البحث</param>
    /// <returns>قاموس المعايير</returns>
    Dictionary<string, object> ExtractCriteria(UnitSearchRequest request);

    /// <summary>
    /// نسخ عميق لطلب البحث
    /// Deep clone of search request
    /// </summary>
    /// <param name="original">الطلب الأصلي</param>
    /// <returns>نسخة مستقلة</returns>
    UnitSearchRequest CloneRequest(UnitSearchRequest original);
}
