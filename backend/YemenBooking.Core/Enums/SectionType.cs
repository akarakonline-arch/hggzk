namespace YemenBooking.Core.Enums;

/// <summary>
/// أنواع واجهات الأقسام - يحدد أي ويدجت سيستخدم في تطبيق العميل
/// Section UI types - defines which widget to use in client app
/// </summary>
public enum SectionType
{
    Grid = 0,
    BigCards = 1,
    List = 2
}

/// <summary>
/// Extension methods for SectionType
/// </summary>
public static class SectionTypeExtensions
{
    public static string GetValue(this SectionType type)
    {
        return type switch
        {
            SectionType.Grid => "grid",
            SectionType.BigCards => "bigCards",
            SectionType.List => "list",
            _ => type.ToString()
        };
    }
    
    public static string GetDisplayName(this SectionType type)
    {
        return type switch
        {
            SectionType.Grid => "شبكة (Grid)",
            SectionType.BigCards => "كروت كبيرة (Big Cards)",
            SectionType.List => "قائمة (List)",
            _ => type.ToString()
        };
    }
}
