using System;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Xunit;
using Xunit.Abstractions;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Infrastructure.Postgres.Indexing;

namespace YemenBooking.Tests.SearchAndFiltering;

public class SearchEngineTest : IAsyncLifetime
{
    private readonly ITestOutputHelper _output;
    private YemenBookingDbContext _dbContext = null!;
    private IUnitSearchEngine _searchEngine = null!;
    private IServiceProvider _serviceProvider = null!;
    
    public SearchEngineTest(ITestOutputHelper output)
    {
        _output = output;
    }
    
    public async Task InitializeAsync()
    {
        var services = new ServiceCollection();
        
        services.AddDbContext<YemenBookingDbContext>(options =>
            options.UseNpgsql("Host=localhost;Database=YemenBookingDb;Username=postgres;Password=postgres"));
        
        services.AddMemoryCache();
        services.AddLogging(builder => builder.AddConsole().SetMinimumLevel(LogLevel.Debug));
        services.AddScoped<IUnitSearchEngine, PostgresUnitSearchEngine>();
        
        _serviceProvider = services.BuildServiceProvider();
        _dbContext = _serviceProvider.GetRequiredService<YemenBookingDbContext>();
        _searchEngine = _serviceProvider.GetRequiredService<IUnitSearchEngine>();
        
        await _dbContext.Database.MigrateAsync();
    }
    
    public async Task DisposeAsync()
    {
        if (_dbContext != null) await _dbContext.DisposeAsync();
        if (_serviceProvider != null && _serviceProvider is IDisposable disposable) disposable.Dispose();
    }
    
    [Fact]
    public async Task Test_SearchWithoutFilters()
    {
        _output.WriteLine("Testing search WITHOUT any filters...");
        
        try
        {
            var request = new UnitSearchRequest
            {
                PageNumber = 1,
                PageSize = 10
            };
            
            var result = await _searchEngine.SearchUnitsAsync(request);
            
            _output.WriteLine($"✅ Results: {result.Units.Count} units");
            _output.WriteLine($"   Total Count: {result.TotalCount}");
            
            foreach (var unit in result.Units)
            {
                _output.WriteLine($"   - {unit.UnitName} in {unit.PropertyName} ({unit.City})");
            }
        }
        catch (Exception ex)
        {
            _output.WriteLine($"❌ ERROR: {ex.Message}");
            _output.WriteLine($"Stack: {ex.StackTrace}");
            if (ex.InnerException != null)
            {
                _output.WriteLine($"Inner: {ex.InnerException.Message}");
            }
        }
    }
    
    [Fact]
    public async Task Test_SearchByCity()
    {
        _output.WriteLine("Testing search BY CITY (صنعاء)...");
        
        try
        {
            var request = new UnitSearchRequest
            {
                City = "صنعاء",
                PageNumber = 1,
                PageSize = 10
            };
            
            var result = await _searchEngine.SearchUnitsAsync(request);
            
            _output.WriteLine($"✅ Results: {result.Units.Count} units");
            _output.WriteLine($"   Total Count: {result.TotalCount}");
        }
        catch (Exception ex)
        {
            _output.WriteLine($"❌ ERROR: {ex.Message}");
            _output.WriteLine($"Stack: {ex.StackTrace}");
            if (ex.InnerException != null)
            {
                _output.WriteLine($"Inner: {ex.InnerException.Message}");
                _output.WriteLine($"Inner Stack: {ex.InnerException.StackTrace}");
            }
        }
    }
}
