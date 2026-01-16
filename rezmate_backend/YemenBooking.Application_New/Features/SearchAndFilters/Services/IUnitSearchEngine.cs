using YemenBooking.Core.Indexing.Models;

namespace YemenBooking.Application.Features.SearchAndFilters.Services;

/// <summary>
/// واجهة محرك البحث عن الوحدات
/// Unit search engine interface
/// </summary>
public interface IUnitSearchEngine
{
    /// <summary>
    /// تحميل Lua Scripts إلى Redis
    /// Preload Lua Scripts to Redis
    /// </summary>
    Task PreloadScriptsAsync();

    /// <summary>
    /// البحث عن الوحدات
    /// Search for units
    /// </summary>
    Task<UnitSearchResult> SearchUnitsAsync(
        UnitSearchRequest request,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// البحث عن العقارات مع وحداتها المتاحة
    /// Search for properties with their available units
    /// </summary>
    Task<PropertyWithUnitsSearchResult> SearchPropertiesWithUnitsAsync(
        PropertyWithUnitsSearchRequest request,
        CancellationToken cancellationToken = default);
}
