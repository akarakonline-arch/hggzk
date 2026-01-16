using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.DependencyInjection;

namespace YemenBooking.Infrastructure.Data.Context;

/// <summary>
/// تعليمات EF Tools لاستخدام DbContextFactory في Design-Time فقط
/// </summary>
public class DesignTimeServices : IDesignTimeServices
{
    public void ConfigureDesignTimeServices(IServiceCollection services)
    {
        // إخبار EF Tools باستخدام DbContextFactory بدلاً من application services
        // هذا يمنع EF من محاولة بناء application service provider الذي قد يفشل
    }
}
