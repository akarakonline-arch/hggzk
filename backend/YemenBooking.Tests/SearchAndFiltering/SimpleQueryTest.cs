using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;
using Xunit.Abstractions;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Tests.SearchAndFiltering;

public class SimpleQueryTest : IAsyncLifetime
{
    private readonly ITestOutputHelper _output;
    private YemenBookingDbContext _dbContext = null!;
    private IServiceProvider _serviceProvider = null!;
    
    public SimpleQueryTest(ITestOutputHelper output)
    {
        _output = output;
    }
    
    public async Task InitializeAsync()
    {
        var services = new ServiceCollection();
        services.AddDbContext<YemenBookingDbContext>(options =>
            options.UseNpgsql("Host=localhost;Database=YemenBookingDb;Username=postgres;Password=postgres"));
        _serviceProvider = services.BuildServiceProvider();
        _dbContext = _serviceProvider.GetRequiredService<YemenBookingDbContext>();
        await _dbContext.Database.MigrateAsync();
    }
    
    public async Task DisposeAsync()
    {
        if (_dbContext != null) await _dbContext.DisposeAsync();
        if (_serviceProvider != null && _serviceProvider is IDisposable disposable) disposable.Dispose();
    }
    
    [Fact]
    public async Task Test_CountUnits()
    {
        var count = await _dbContext.Units.CountAsync();
        _output.WriteLine($"Total units in DB: {count}");
        
        var approvedCount = await _dbContext.Units
            .Where(u => u.Property.IsApproved)
            .CountAsync();
        _output.WriteLine($"Units with approved properties: {approvedCount}");
    }
    
    [Fact]
    public async Task Test_BasicProjection()
    {
        _output.WriteLine("Testing basic projection...");
        
        var results = await _dbContext.Units
            .AsNoTracking()
            .Include(u => u.Property)
            .Where(u => u.Property.IsApproved)
            .Take(5)
            .Select(u => new
            {
                UnitId = u.Id,
                UnitName = u.Name,
                PropertyName = u.Property.Name,
                City = u.Property.City
            })
            .ToListAsync();
            
        _output.WriteLine($"Results: {results.Count}");
        foreach (var r in results)
        {
            _output.WriteLine($"  - {r.UnitName} in {r.PropertyName} ({r.City})");
        }
    }
    
    [Fact]
    public async Task Test_ProjectionWithReviews()
    {
        _output.WriteLine("Testing projection with Reviews subquery...");
        
        try
        {
            var results = await _dbContext.Units
                .AsNoTracking()
                .Include(u => u.Property)
                .Where(u => u.Property.IsApproved)
                .Take(5)
                .Select(u => new
                {
                    UnitId = u.Id,
                    UnitName = u.Name,
                    PropertyName = u.Property.Name,
                    City = u.Property.City,
                    AverageRating = _dbContext.Reviews
                        .Where(r => r.PropertyId == u.PropertyId)
                        .Average(r => (decimal?)r.AverageRating) ?? 0
                })
                .ToListAsync();
                
            _output.WriteLine($"Results: {results.Count}");
            foreach (var r in results)
            {
                _output.WriteLine($"  - {r.UnitName} - Rating: {r.AverageRating:F2}");
            }
        }
        catch (Exception ex)
        {
            _output.WriteLine($"ERROR: {ex.Message}");
        }
    }
    
    [Fact]
    public async Task Test_ProjectionWithDailySchedules()
    {
        _output.WriteLine("Testing projection with DailySchedules subquery...");
        
        try
        {
            var results = await _dbContext.Units
                .AsNoTracking()
                .Include(u => u.Property)
                .Where(u => u.Property.IsApproved)
                .Take(5)
                .Select(u => new
                {
                    UnitId = u.Id,
                    UnitName = u.Name,
                    BasePrice = _dbContext.DailyUnitSchedules
                        .Where(ds => ds.UnitId == u.Id &&
                                    ds.PriceAmount.HasValue &&
                                    ds.Status == "Available" &&
                                    ds.Date >= DateTime.UtcNow.Date)
                        .OrderBy(ds => ds.PriceAmount)
                        .Select(ds => (decimal?)ds.PriceAmount)
                        .FirstOrDefault() ?? 0
                })
                .ToListAsync();
                
            _output.WriteLine($"Results: {results.Count}");
            foreach (var r in results)
            {
                _output.WriteLine($"  - {r.UnitName}: {r.BasePrice} YER");
            }
        }
        catch (Exception ex)
        {
            _output.WriteLine($"ERROR: {ex.Message}");
            _output.WriteLine($"Inner: {ex.InnerException?.Message}");
        }
    }
}
