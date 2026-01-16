using Microsoft.EntityFrameworkCore;

namespace YemenBooking.Infrastructure.Postgres.Configuration;

/// <summary>
/// تكوين دوال PostgreSQL المخصصة في EF Core
/// </summary>
public static class PostgreSqlFunctionsConfiguration
{
    /// <summary>
    /// تسجيل دوال PostgreSQL المخصصة في DbContext
    /// </summary>
    public static void ConfigurePostgreSqlFunctions(this ModelBuilder modelBuilder)
    {
        // ✅ تسجيل is_numeric_in_range function
        modelBuilder.HasDbFunction(
            typeof(PostgreSqlFunctionsConfiguration).GetMethod(nameof(IsNumericInRange))!
        ).HasName("is_numeric_in_range");
        
        // ✅ تسجيل calculate_distance_km function
        modelBuilder.HasDbFunction(
            typeof(PostgreSqlFunctionsConfiguration).GetMethod(nameof(CalculateDistanceKm))!
        ).HasName("calculate_distance_km");
        
        // ✅ تسجيل is_unit_available function
        modelBuilder.HasDbFunction(
            typeof(PostgreSqlFunctionsConfiguration).GetMethod(nameof(IsUnitAvailable))!
        ).HasName("is_unit_available");
        
        // ✅ تسجيل check_unit_price_in_range function
        modelBuilder.HasDbFunction(
            typeof(PostgreSqlFunctionsConfiguration).GetMethod(nameof(CheckUnitPriceInRange))!
        ).HasName("check_unit_price_in_range");
        
        // ✅ تسجيل check_unit_any_price_in_range function
        modelBuilder.HasDbFunction(
            typeof(PostgreSqlFunctionsConfiguration).GetMethod(nameof(CheckUnitAnyPriceInRange))!
        ).HasName("check_unit_any_price_in_range");
        
        // ✅ تسجيل get_unit_display_fields_json function
        modelBuilder.HasDbFunction(
            typeof(PostgreSqlFunctionsConfiguration).GetMethod(nameof(GetUnitDisplayFieldsJson))!
        ).HasName("get_unit_display_fields_json");
    }
    
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // Method Signatures (لن يتم تنفيذها - فقط للتعريف)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    
    public static bool IsNumericInRange(string? value, decimal minValue, decimal maxValue)
        => throw new NotSupportedException();
    
    public static double CalculateDistanceKm(double lat1, double lng1, double lat2, double lng2)
        => throw new NotSupportedException();
    
    public static bool IsUnitAvailable(Guid unitId, DateTime checkIn, DateTime checkOut)
        => throw new NotSupportedException();
    
    public static bool CheckUnitPriceInRange(
        Guid unitId, 
        DateTime checkIn, 
        DateTime checkOut,
        decimal? yerMin = null, 
        decimal? yerMax = null,
        decimal? usdMin = null, 
        decimal? usdMax = null,
        decimal? eurMin = null, 
        decimal? eurMax = null,
        decimal? sarMin = null, 
        decimal? sarMax = null,
        decimal? gbpMin = null, 
        decimal? gbpMax = null)
        => throw new NotSupportedException();
    
    public static bool CheckUnitAnyPriceInRange(
        Guid unitId,
        decimal? yerMin = null, 
        decimal? yerMax = null,
        decimal? usdMin = null, 
        decimal? usdMax = null,
        decimal? eurMin = null, 
        decimal? eurMax = null,
        decimal? sarMin = null, 
        decimal? sarMax = null,
        decimal? gbpMin = null, 
        decimal? gbpMax = null)
        => throw new NotSupportedException();
    
    /// <summary>
    /// إرجاع الحقول الديناميكية للوحدة كـ JSONB - تنفيذ كامل في SQL
    /// </summary>
    public static string GetUnitDisplayFieldsJson(Guid unitId)
        => throw new NotSupportedException();
}
