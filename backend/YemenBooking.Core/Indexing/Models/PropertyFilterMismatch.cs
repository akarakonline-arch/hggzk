namespace YemenBooking.Core.Indexing.Models;

/// <summary>
/// يمثل فرقاً بين معيار مطلوب وقيمة فعلية في العقار
/// Represents a mismatch between a requested criterion and actual property value
/// </summary>
public class PropertyFilterMismatch
{
    /// <summary>
    /// نوع الفلتر (GuestsCount, DynamicField, Price)
    /// Filter type
    /// </summary>
    public string FilterType { get; set; } = string.Empty;
    
    /// <summary>
    /// اسم الفلتر (عربي للعرض)
    /// Display name in Arabic
    /// مثال: "السعة"، "مسبح"، "المساحة"
    /// Example: "Capacity", "Pool", "Area"
    /// </summary>
    public string FilterDisplayName { get; set; } = string.Empty;
    
    /// <summary>
    /// القيمة المطلوبة من المستخدم
    /// Requested value from user
    /// مثال: "5 ضيوف"، "نعم"، "82-90 م²"
    /// Example: "5 guests", "Yes", "82-90 m²"
    /// </summary>
    public string RequestedValue { get; set; } = string.Empty;
    
    /// <summary>
    /// القيمة الفعلية في العقار (أو الوحدة)
    /// Actual value in the property (or unit)
    /// مثال: "4 ضيوف"، "لا"، "75 م²"
    /// Example: "4 guests", "No", "75 m²"
    /// </summary>
    public string ActualValue { get; set; } = string.Empty;
    
    /// <summary>
    /// رسالة مختصرة للعرض في UI
    /// Brief message for UI display
    /// مثال: "يستوعب 4 ضيوف (طلبت 5)"، "بدون مسبح"
    /// Example: "Accommodates 4 guests (requested 5)", "No pool"
    /// </summary>
    public string DisplayMessage { get; set; } = string.Empty;
    
    /// <summary>
    /// شدة الفرق (Minor, Moderate, Major)
    /// Severity of the mismatch
    /// </summary>
    public MismatchSeverity Severity { get; set; }
}

/// <summary>
/// شدة الفرق بين المطلوب والفعلي
/// Severity of the mismatch between requested and actual values
/// </summary>
public enum MismatchSeverity
{
    /// <summary>
    /// فرق بسيط (مثل: طلب 5 ضيوف، يوفر 4)
    /// Minor difference (e.g., requested 5 guests, provides 4)
    /// </summary>
    Minor,
    
    /// <summary>
    /// فرق متوسط (مثل: طلب مسبح، لا يوفر)
    /// Moderate difference (e.g., requested pool, doesn't provide)
    /// </summary>
    Moderate,
    
    /// <summary>
    /// فرق كبير (مثل: طلب نطاق سعر 5000-8000، يوفر 12000)
    /// Major difference (e.g., requested price range 5000-8000, provides 12000)
    /// </summary>
    Major
}
