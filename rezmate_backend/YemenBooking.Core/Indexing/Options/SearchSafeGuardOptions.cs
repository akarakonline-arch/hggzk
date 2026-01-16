using System;

namespace YemenBooking.Core.Indexing.Options;

/// <summary>
/// خيارات حماية البحث من الطلبات الخطيرة
/// Search Safe Guard Options for protecting against dangerous queries
/// 
/// تُستخدم لضبط حدود الأمان عند البحث بدون معايير كافية
/// Used to configure safety limits when searching without sufficient criteria
/// </summary>
public class SearchSafeGuardOptions
{
    /// <summary>
    /// الحد الأقصى لعدد النتائج عند عدم وجود فلاتر كافية
    /// Maximum results when no sufficient filters exist
    /// </summary>
    public int MaxResultsWithoutFilters { get; set; } = 100;

    /// <summary>
    /// الحد الأقصى لـ PageSize عند عدم وجود فلاتر كافية
    /// Maximum page size when no sufficient filters exist
    /// </summary>
    public int MaxPageSizeWithoutFilters { get; set; } = 50;

    /// <summary>
    /// هل يُطلب عرض العقارات المميزة فقط عند عدم وجود فلاتر؟
    /// Require featured properties only when no filters exist?
    /// </summary>
    public bool RequireFeaturedWhenNoFilters { get; set; } = true;

    /// <summary>
    /// هل يُرفض الطلب إذا كان فارغاً تماماً؟
    /// Reject completely empty search requests?
    /// </summary>
    public bool RejectEmptyRequests { get; set; } = true;

    /// <summary>
    /// الحد الأقصى لعدد الحقول الديناميكية المسموح بها
    /// Maximum allowed dynamic field filters
    /// </summary>
    public int MaxDynamicFieldFilters { get; set; } = 10;

    /// <summary>
    /// التحقق من صحة القيم المُدخلة
    /// Validate configured values
    /// </summary>
    public void Validate()
    {
        if (MaxResultsWithoutFilters < 1 || MaxResultsWithoutFilters > 1000)
            throw new InvalidOperationException(
                "MaxResultsWithoutFilters يجب أن يكون بين 1 و 1000");

        if (MaxPageSizeWithoutFilters < 1 || MaxPageSizeWithoutFilters > 200)
            throw new InvalidOperationException(
                "MaxPageSizeWithoutFilters يجب أن يكون بين 1 و 200");

        if (MaxDynamicFieldFilters < 1 || MaxDynamicFieldFilters > 50)
            throw new InvalidOperationException(
                "MaxDynamicFieldFilters يجب أن يكون بين 1 و 50");
    }
}
