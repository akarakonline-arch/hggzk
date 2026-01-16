using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;
using Xunit.Abstractions;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Tests.SearchAndFiltering;

/// <summary>
/// اختبارات تشخيصية للتحقق من البيانات في قاعدة البيانات
/// </summary>
public class DiagnosticTests : IAsyncLifetime
{
    private readonly ITestOutputHelper _output;
    private YemenBookingDbContext _dbContext = null!;
    private IServiceProvider _serviceProvider = null!;
    
    public DiagnosticTests(ITestOutputHelper output)
    {
        _output = output ?? throw new ArgumentNullException(nameof(output));
    }
    
    public async Task InitializeAsync()
    {
        var services = new ServiceCollection();
        
        services.AddDbContext<YemenBookingDbContext>(options =>
            options.UseNpgsql(
                "Host=localhost;Database=YemenBookingDb;Username=postgres;Password=postgres"
            ));
        
        _serviceProvider = services.BuildServiceProvider();
        _dbContext = _serviceProvider.GetRequiredService<YemenBookingDbContext>();
        
        await _dbContext.Database.MigrateAsync();
    }
    
    public async Task DisposeAsync()
    {
        if (_dbContext != null)
        {
            await _dbContext.DisposeAsync();
        }
        
        if (_serviceProvider != null && _serviceProvider is IDisposable disposable)
        {
            disposable.Dispose();
        }
    }
    
    [Fact]
    public async Task Diagnostic01_CheckPropertiesByCity()
    {
        _output.WriteLine("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        _output.WriteLine("🔍 تشخيص 1: فحص العقارات حسب المدينة");
        _output.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        
        var propertiesByCity = await _dbContext.Properties
            .Where(p => p.IsApproved)
            .GroupBy(p => p.City)
            .Select(g => new { City = g.Key, Count = g.Count() })
            .ToListAsync();
        
        _output.WriteLine($"📊 العقارات حسب المدينة:");
        foreach (var item in propertiesByCity.OrderByDescending(x => x.Count))
        {
            _output.WriteLine($"   - {item.City}: {item.Count} عقارات");
        }
    }
    
    [Fact]
    public async Task Diagnostic02_CheckUnitsByCity()
    {
        _output.WriteLine("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        _output.WriteLine("🔍 تشخيص 2: فحص الوحدات حسب المدينة");
        _output.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        
        var unitsByCity = await _dbContext.Units
            .Include(u => u.Property)
            .Where(u => u.Property.IsApproved)
            .GroupBy(u => u.Property.City)
            .Select(g => new { City = g.Key, Count = g.Count() })
            .ToListAsync();
        
        _output.WriteLine($"📊 الوحدات حسب المدينة:");
        foreach (var item in unitsByCity.OrderByDescending(x => x.Count))
        {
            _output.WriteLine($"   - {item.City}: {item.Count} وحدة");
        }
    }
    
    [Fact]
    public async Task Diagnostic03_CheckSampleProperties()
    {
        _output.WriteLine("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        _output.WriteLine("🔍 تشخيص 3: فحص عينة من العقارات");
        _output.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        
        var properties = await _dbContext.Properties
            .Where(p => p.IsApproved)
            .OrderBy(p => p.City)
            .Take(10)
            .ToListAsync();
        
        _output.WriteLine($"📋 عينة من العقارات:");
        foreach (var prop in properties)
        {
            _output.WriteLine($"   - {prop.Name}");
            _output.WriteLine($"     • المدينة: {prop.City}");
            _output.WriteLine($"     • معتمد: {prop.IsApproved}");
            _output.WriteLine($"     • ID: {prop.Id}");
        }
    }
    
    [Fact]
    public async Task Diagnostic04_CheckUnitsBasicQuery()
    {
        _output.WriteLine("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        _output.WriteLine("🔍 تشخيص 4: استعلام بسيط للوحدات");
        _output.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        
        var units = await _dbContext.Units
            .Include(u => u.Property)
            .Where(u => u.Property.IsApproved)
            .Take(5)
            .ToListAsync();
        
        _output.WriteLine($"📋 عينة من الوحدات:");
        foreach (var unit in units)
        {
            _output.WriteLine($"   - {unit.Name} في {unit.Property.Name}");
            _output.WriteLine($"     • المدينة: {unit.Property.City}");
            _output.WriteLine($"     • السعة: {unit.MaxCapacity}");
        }
    }
    
    [Fact]
    public async Task Diagnostic05_TestCityFilterDirectly()
    {
        _output.WriteLine("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        _output.WriteLine("🔍 تشخيص 5: اختبار فلتر المدينة مباشرة");
        _output.WriteLine("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
        
        var city = "صنعاء";
        _output.WriteLine($"🔎 البحث عن وحدات في: {city}");
        
        var units = await _dbContext.Units
            .Include(u => u.Property)
            .Where(u => u.Property.IsApproved && u.Property.City == city)
            .ToListAsync();
        
        _output.WriteLine($"✅ النتائج: {units.Count} وحدة");
        
        if (units.Any())
        {
            foreach (var unit in units.Take(5))
            {
                _output.WriteLine($"   - {unit.Name}: {unit.Property.City}");
            }
        }
        else
        {
            _output.WriteLine("⚠️ لم يتم العثور على وحدات في صنعاء");
            
            // فحص جميع المدن المتاحة
            var cities = await _dbContext.Properties
                .Where(p => p.IsApproved)
                .Select(p => p.City)
                .Distinct()
                .ToListAsync();
            
            _output.WriteLine($"\n📍 المدن المتاحة:");
            foreach (var c in cities)
            {
                _output.WriteLine($"   - {c}");
            }
        }
    }
}
