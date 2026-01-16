using YemenBooking.Core.Indexing.Enums;
using YemenBooking.Core.Indexing.Models;

namespace YemenBooking.Infrastructure.Services;

/// <summary>
/// مولد رسائل البحث الذكية للمستخدم
/// Smart Search Message Generator
/// </summary>
public class SearchMessageGenerator
{
    /// <summary>
    /// توليد رسالة للمستخدم بناءً على مستوى التخفيف
    /// Generate user message based on relaxation level
    /// </summary>
    public string GenerateUserMessage(
        SearchRelaxationLevel level,
        int resultCount,
        List<string> relaxedFilters)
    {
        // صيغ الجمع/المفرد للعقارات
        var propertyWord = resultCount == 1 ? "عقار" :
                           resultCount == 2 ? "عقارين" :
                           resultCount <= 10 ? $"{resultCount} عقارات" :
                           $"{resultCount} عقار";
        
        var message = level switch
        {
            SearchRelaxationLevel.Exact =>
                $"وجدنا لك {propertyWord} مطابق تماماً لمعاييرك!",
            
            SearchRelaxationLevel.MinorRelaxation =>
                $"وجدنا لك {propertyWord} رائع قريب جداً من طلبك!",
            
            SearchRelaxationLevel.ModerateRelaxation =>
                $"اخترنا لك {propertyWord} ممتاز بمعايير مرنة",
            
            SearchRelaxationLevel.MajorRelaxation =>
                resultCount == 1 
                    ? "لدينا اقتراح مميز قد ينال إعجابك"
                    : $"لدينا {resultCount} اقتراح مميز قد ينال إعجابك",
            
            SearchRelaxationLevel.AlternativeSuggestions =>
                $"عقارات بديلة ({resultCount}) قد تكون خياراً ممتازاً لك",
            
            _ => $"وجدنا {resultCount} نتيجة"
        };

        // إضافة تفاصيل التعديلات (إذا لم يكن Exact Match)
        if (level != SearchRelaxationLevel.Exact && relaxedFilters.Any())
        {
            message += "\n\nالتعديلات المطبقة:\n• " + string.Join("\n• ", relaxedFilters);
        }

        return message;
    }

    /// <summary>
    /// توليد اقتراحات لتحسين البحث
    /// Generate suggestions to improve search
    /// </summary>
    public List<string> GenerateSuggestedActions(UnitSearchRequest request)
    {
        var suggestions = new List<string>();

        // اقتراحات بناءً على معايير البحث الحالية
        if (request.CheckIn.HasValue && request.CheckOut.HasValue)
        {
            suggestions.Add("جرب تغيير تواريخ السفر");
        }

        if (request.MinPrice.HasValue || request.MaxPrice.HasValue)
        {
            suggestions.Add("عدّل نطاق السعر لمزيد من الخيارات");
        }

        if (!string.IsNullOrWhiteSpace(request.City))
        {
            suggestions.Add($"ابحث في مدن قريبة من {request.City}");
        }

        if (request.RequiredAmenities?.Any() == true)
        {
            suggestions.Add("قلل من المرافق المطلوبة");
        }

        if (request.UnitTypeId.HasValue)
        {
            suggestions.Add("جرب أنواع وحدات أخرى");
        }

        if (request.MinRating.HasValue)
        {
            suggestions.Add("خفض الحد الأدنى للتقييم");
        }

        if (request.GuestsCount.HasValue && request.GuestsCount > 2)
        {
            suggestions.Add("قلل عدد الضيوف للحصول على المزيد من الخيارات");
        }

        // إضافة اقتراحات عامة إذا لم يكن هناك اقتراحات محددة
        if (!suggestions.Any())
        {
            suggestions.Add("جرب تبسيط معايير البحث");
            suggestions.Add("ابحث في تواريخ أخرى");
        }

        return suggestions;
    }

    /// <summary>
    /// توليد ملخص للتعديلات المطبقة
    /// Generate summary of applied modifications
    /// </summary>
    public string GenerateModificationsSummary(
        Dictionary<string, object> originalCriteria,
        Dictionary<string, object> actualCriteria)
    {
        var changes = new List<string>();

        foreach (var key in originalCriteria.Keys)
        {
            if (actualCriteria.ContainsKey(key))
            {
                var original = originalCriteria[key];
                var actual = actualCriteria[key];

                if (!Equals(original, actual))
                {
                    changes.Add($"{key}: {original} ← {actual}");
                }
            }
        }

        // معايير تمت إزالتها
        foreach (var key in originalCriteria.Keys)
        {
            if (!actualCriteria.ContainsKey(key))
            {
                changes.Add($"{key}: تمت الإزالة");
            }
        }

        // معايير جديدة أضيفت
        foreach (var key in actualCriteria.Keys)
        {
            if (!originalCriteria.ContainsKey(key))
            {
                changes.Add($"{key}: {actualCriteria[key]} (جديد)");
            }
        }

        return changes.Any()
            ? "التعديلات:\n" + string.Join("\n", changes)
            : "لا توجد تعديلات";
    }
}
