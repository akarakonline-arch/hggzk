using Microsoft.EntityFrameworkCore;

namespace YemenBooking.Infrastructure.Postgres.Extensions;

/// <summary>
/// توسيعات لـ EF.Functions لدعم دوال PostgreSQL المخصصة
/// </summary>
public static class PostgreSqlDbFunctionsExtensions
{
    /// <summary>
    /// التحقق من أن القيمة النصية هي رقم ضمن نطاق محدد
    /// يستخدم دالة PostgreSQL: is_numeric_in_range()
    /// </summary>
    /// <param name="_">EF Functions instance</param>
    /// <param name="value">القيمة المراد فحصها</param>
    /// <param name="minValue">الحد الأدنى</param>
    /// <param name="maxValue">الحد الأقصى</param>
    /// <returns>true إذا كانت القيمة رقمية وضمن النطاق</returns>
    public static bool IsNumericInRange(
        this DbFunctions _,
        string? value,
        decimal minValue,
        decimal maxValue)
    {
        // هذا الميثود لن يُنفذ أبداً - فقط للترجمة إلى SQL
        throw new NotSupportedException(
            "This method is for use with Entity Framework Core only and has no in-memory implementation.");
    }
}
