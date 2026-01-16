namespace YemenBooking.Core.Indexing.Options;

/// <summary>
/// خيارات استراتيجية البحث مع التخفيف التدريجي (Fallback)
/// Fallback Search Strategy Options
/// 
/// يتحكم في سلوك محرك البحث عند عدم وجود نتائج مطابقة
/// Controls search engine behavior when no exact matches are found
/// </summary>
public class FallbackSearchOptions
{
    /// <summary>
    /// تفعيل/تعطيل استراتيجية التخفيف التدريجي بالكامل
    /// Enable/Disable fallback strategy completely
    /// </summary>
    public bool EnableFallback { get; set; } = true;

    /// <summary>
    /// الحد الأدنى لعدد النتائج قبل تطبيق التخفيف
    /// Minimum number of results before applying relaxation
    /// إذا كان عدد النتائج أكبر من هذا الحد، لا يتم التخفيف
    /// If results exceed this threshold, no relaxation is applied
    /// </summary>
    public int MinResultsThreshold { get; set; } = 5;

    #region === تفعيل/تعطيل المراحل (Enable/Disable Levels) ===

    /// <summary>
    /// تفعيل المرحلة 1: التخفيف البسيط (15-20%)
    /// Enable Level 1: Minor Relaxation (15-20%)
    /// </summary>
    public bool EnableMinorRelaxation { get; set; } = true;

    /// <summary>
    /// تفعيل المرحلة 2: التخفيف المتوسط (30-40%)
    /// Enable Level 2: Moderate Relaxation (30-40%)
    /// </summary>
    public bool EnableModerateRelaxation { get; set; } = true;

    /// <summary>
    /// تفعيل المرحلة 3: التخفيف الكبير (50%+)
    /// Enable Level 3: Major Relaxation (50%+)
    /// </summary>
    public bool EnableMajorRelaxation { get; set; } = true;

    /// <summary>
    /// تفعيل المرحلة 4: الاقتراحات البديلة
    /// Enable Level 4: Alternative Suggestions
    /// </summary>
    public bool EnableAlternativeSuggestions { get; set; } = true;

    #endregion

    #region === نسب التخفيف للسعر (Price Relaxation Percentages) ===

    /// <summary>
    /// نسبة التخفيف للسعر في المرحلة البسيطة (0.15 = 15%)
    /// Price relaxation percentage for minor level (0.15 = 15%)
    /// </summary>
    public decimal PriceRelaxationMinor { get; set; } = 0.15m;

    /// <summary>
    /// نسبة التخفيف للسعر في المرحلة المتوسطة (0.30 = 30%)
    /// Price relaxation percentage for moderate level (0.30 = 30%)
    /// </summary>
    public decimal PriceRelaxationModerate { get; set; } = 0.30m;

    /// <summary>
    /// نسبة التخفيف للسعر في المرحلة الكبيرة (0.50 = 50%)
    /// Price relaxation percentage for major level (0.50 = 50%)
    /// </summary>
    public decimal PriceRelaxationMajor { get; set; } = 0.50m;

    #endregion

    #region === مضاعفات النطاق الجغرافي (Geographic Radius Multipliers) ===

    /// <summary>
    /// مضاعف النطاق في المرحلة البسيطة (1.5 = ضعف ونصف)
    /// Radius multiplier for minor level (1.5 = one and a half times)
    /// </summary>
    public double RadiusMultiplierMinor { get; set; } = 1.5;

    /// <summary>
    /// مضاعف النطاق في المرحلة المتوسطة (2.0 = ضعفين)
    /// Radius multiplier for moderate level (2.0 = double)
    /// </summary>
    public double RadiusMultiplierModerate { get; set; } = 2.0;

    /// <summary>
    /// مضاعف النطاق في المرحلة الكبيرة (3.0 = ثلاثة أضعاف)
    /// Radius multiplier for major level (3.0 = triple)
    /// </summary>
    public double RadiusMultiplierMajor { get; set; } = 3.0;

    #endregion

    #region === إعدادات إضافية (Additional Settings) ===

    /// <summary>
    /// عدد أيام المرونة في التواريخ (±3 أيام)
    /// Date flexibility in days (±3 days)
    /// يُستخدم في المرحلة الكبيرة
    /// Used in major relaxation level
    /// </summary>
    public int DateFlexibilityDays { get; set; } = 3;

    /// <summary>
    /// نسبة المرافق المطلوبة في المرحلة البسيطة (0.5 = النصف)
    /// Required amenities percentage for minor level (0.5 = half)
    /// </summary>
    public decimal AmenitiesRetentionRatio { get; set; } = 0.5m;

    /// <summary>
    /// تخفيض التقييم في المرحلة البسيطة (0.5 نجمة)
    /// Rating reduction for minor level (0.5 stars)
    /// </summary>
    public decimal RatingReduction { get; set; } = 0.5m;

    /// <summary>
    /// تخفيض عدد الضيوف في المرحلة المتوسطة (1 ضيف)
    /// Guests count reduction for moderate level (1 guest)
    /// </summary>
    public int GuestsCountReduction { get; set; } = 1;

    #endregion

    #region === العرض والتسجيل (Display & Logging) ===

    /// <summary>
    /// عرض معلومات التخفيف للمستخدم في النتائج
    /// Show relaxation info to user in results
    /// </summary>
    public bool ShowRelaxationInfo { get; set; } = true;

    /// <summary>
    /// تسجيل خطوات التخفيف في الـ Logs
    /// Log relaxation steps to logs
    /// </summary>
    public bool LogRelaxationSteps { get; set; } = true;

    /// <summary>
    /// مستوى التفصيل في الـ Logging
    /// Logging detail level
    /// 0 = معلومات أساسية، 1 = متوسط، 2 = تفصيلي
    /// 0 = basic info, 1 = medium, 2 = detailed
    /// </summary>
    public int LoggingDetailLevel { get; set; } = 1;

    #endregion

    #region === Validation Methods ===

    /// <summary>
    /// التحقق من صحة القيم
    /// Validate option values
    /// </summary>
    public void Validate()
    {
        // التحقق من نسب السعر
        if (PriceRelaxationMinor < 0 || PriceRelaxationMinor > 1)
            PriceRelaxationMinor = 0.15m;

        if (PriceRelaxationModerate < 0 || PriceRelaxationModerate > 1)
            PriceRelaxationModerate = 0.30m;

        if (PriceRelaxationMajor < 0 || PriceRelaxationMajor > 1)
            PriceRelaxationMajor = 0.50m;

        // التحقق من مضاعفات النطاق
        if (RadiusMultiplierMinor < 1 || RadiusMultiplierMinor > 10)
            RadiusMultiplierMinor = 1.5;

        if (RadiusMultiplierModerate < 1 || RadiusMultiplierModerate > 10)
            RadiusMultiplierModerate = 2.0;

        if (RadiusMultiplierMajor < 1 || RadiusMultiplierMajor > 10)
            RadiusMultiplierMajor = 3.0;

        // التحقق من القيم الأخرى
        if (MinResultsThreshold < 0)
            MinResultsThreshold = 5;

        if (DateFlexibilityDays < 0 || DateFlexibilityDays > 14)
            DateFlexibilityDays = 3;

        if (AmenitiesRetentionRatio < 0 || AmenitiesRetentionRatio > 1)
            AmenitiesRetentionRatio = 0.5m;

        if (RatingReduction < 0 || RatingReduction > 5)
            RatingReduction = 0.5m;

        if (GuestsCountReduction < 0 || GuestsCountReduction > 10)
            GuestsCountReduction = 1;
    }

    #endregion
}
