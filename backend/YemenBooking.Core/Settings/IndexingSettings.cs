namespace YemenBooking.Core.Settings;

/// <summary>
/// إعدادات نظام الفهرسة والبحث في Redis
/// 
/// الاستخدام:
/// في appsettings.json:
/// {
///   "IndexingSettings": {
///     "DefaultExpiryDays": 30,
///     "IndexingLockTimeoutSeconds": 10,
///     "BatchSize": 100,
///     "MaxRetryAttempts": 2,
///     "MaxPropertyImages": 3,
///     "AvailabilityMonthsAhead": 12,
///     "PricingMonthsAhead": 12,
///     "TempKeyTtlSeconds": 60,
///     "MaxResultsBeforePagination": 1000,
///     "MaxDegreeOfParallelism": 0
///   }
/// }
/// 
/// في Program.cs:
/// builder.Services.Configure&lt;IndexingSettings&gt;(
///     builder.Configuration.GetSection("IndexingSettings"));
/// </summary>
public sealed class IndexingSettings
{
    /// <summary>
    /// مدة انتهاء صلاحية المفاتيح في Redis (بالأيام)
    /// القيمة الافتراضية: 30 يوم
    /// </summary>
    public int DefaultExpiryDays { get; set; } = 30;
    
    /// <summary>
    /// مهلة الانتظار للحصول على قفل الفهرسة (بالثواني)
    /// القيمة الافتراضية: 10 ثوانٍ
    /// </summary>
    public int IndexingLockTimeoutSeconds { get; set; } = 10;
    
    /// <summary>
    /// حجم الدفعة عند إعادة بناء الفهرس الكامل
    /// القيمة الافتراضية: 100 وحدة
    /// </summary>
    public int BatchSize { get; set; } = 100;
    
    /// <summary>
    /// الحد الأقصى لعدد محاولات إعادة العملية عند الفشل
    /// القيمة الافتراضية: 2 محاولات
    /// </summary>
    public int MaxRetryAttempts { get; set; } = 2;
    
    /// <summary>
    /// الحد الأقصى لعدد صور العقار المضافة للفهرس
    /// القيمة الافتراضية: 3 صور
    /// </summary>
    public int MaxPropertyImages { get; set; } = 3;
    
    /// <summary>
    /// عدد الأشهر المستقبلية لفهرسة الإتاحات
    /// القيمة الافتراضية: 12 شهر
    /// </summary>
    public int AvailabilityMonthsAhead { get; set; } = 12;
    
    /// <summary>
    /// عدد الأشهر المستقبلية لفهرسة قواعد التسعير
    /// القيمة الافتراضية: 12 شهر
    /// </summary>
    public int PricingMonthsAhead { get; set; } = 12;
    
    /// <summary>
    /// مدة انتهاء صلاحية المفاتيح المؤقتة (بالثواني)
    /// القيمة الافتراضية: 60 ثانية
    /// </summary>
    public int TempKeyTtlSeconds { get; set; } = 60;
    
    /// <summary>
    /// الحد الأقصى لعدد النتائج قبل التصفح (Pagination)
    /// القيمة الافتراضية: 1000 نتيجة
    /// </summary>
    public int MaxResultsBeforePagination { get; set; } = 1000;
    
    /// <summary>
    /// الحد الأقصى لدرجة التوازي في المعالجة
    /// القيمة الافتراضية: 0 (يستخدم Environment.ProcessorCount تلقائياً)
    /// </summary>
    public int MaxDegreeOfParallelism { get; set; } = 0;
    
    /// <summary>
    /// الحصول على MaxDegreeOfParallelism الفعلي
    /// إذا كان 0، يُرجع Environment.ProcessorCount
    /// </summary>
    public int GetMaxDegreeOfParallelism()
    {
        return MaxDegreeOfParallelism > 0 
            ? MaxDegreeOfParallelism 
            : Environment.ProcessorCount;
    }
    
    /// <summary>
    /// الحصول على Timeout كـ TimeSpan
    /// </summary>
    public TimeSpan GetIndexingLockTimeout()
    {
        return TimeSpan.FromSeconds(IndexingLockTimeoutSeconds);
    }
    
    /// <summary>
    /// الحصول على Default Expiry كـ TimeSpan
    /// </summary>
    public TimeSpan GetDefaultExpiry()
    {
        return TimeSpan.FromDays(DefaultExpiryDays);
    }
    
    /// <summary>
    /// الحصول على Temp Key TTL كـ TimeSpan
    /// </summary>
    public TimeSpan GetTempKeyTtl()
    {
        return TimeSpan.FromSeconds(TempKeyTtlSeconds);
    }
    
    /// <summary>
    /// التحقق من صحة الإعدادات
    /// </summary>
    public void Validate()
    {
        if (DefaultExpiryDays <= 0)
            throw new InvalidOperationException($"{nameof(DefaultExpiryDays)} يجب أن يكون أكبر من صفر");
        
        if (IndexingLockTimeoutSeconds <= 0)
            throw new InvalidOperationException($"{nameof(IndexingLockTimeoutSeconds)} يجب أن يكون أكبر من صفر");
        
        if (BatchSize <= 0)
            throw new InvalidOperationException($"{nameof(BatchSize)} يجب أن يكون أكبر من صفر");
        
        if (MaxRetryAttempts < 0)
            throw new InvalidOperationException($"{nameof(MaxRetryAttempts)} لا يمكن أن يكون سالباً");
        
        if (MaxPropertyImages < 0)
            throw new InvalidOperationException($"{nameof(MaxPropertyImages)} لا يمكن أن يكون سالباً");
        
        if (AvailabilityMonthsAhead <= 0)
            throw new InvalidOperationException($"{nameof(AvailabilityMonthsAhead)} يجب أن يكون أكبر من صفر");
        
        if (PricingMonthsAhead <= 0)
            throw new InvalidOperationException($"{nameof(PricingMonthsAhead)} يجب أن يكون أكبر من صفر");
        
        if (TempKeyTtlSeconds <= 0)
            throw new InvalidOperationException($"{nameof(TempKeyTtlSeconds)} يجب أن يكون أكبر من صفر");
        
        if (MaxResultsBeforePagination <= 0)
            throw new InvalidOperationException($"{nameof(MaxResultsBeforePagination)} يجب أن يكون أكبر من صفر");
        
        if (MaxDegreeOfParallelism < 0)
            throw new InvalidOperationException($"{nameof(MaxDegreeOfParallelism)} لا يمكن أن يكون سالباً");
    }
}
