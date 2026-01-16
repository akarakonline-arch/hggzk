using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;
using Xunit.Abstractions;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Tests.SearchAndFiltering;

public class FullProjectionTest : IAsyncLifetime
{
    private readonly ITestOutputHelper _output;
    private YemenBookingDbContext _dbContext = null!;
    private IServiceProvider _serviceProvider = null!;
    
    public FullProjectionTest(ITestOutputHelper output)
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
    public async Task Test_FullProjectionLikeSearchEngine()
    {
        _output.WriteLine("Testing FULL projection exactly like PostgresUnitSearchEngine...");
        
        try
        {
            var query = _dbContext.Units
                .AsNoTracking()
                .Include(u => u.Property)
                    .ThenInclude(p => p.PropertyType)
                .Include(u => u.Property.Images)
                .Include(u => u.UnitType)
                .Include(u => u.Images)
                .Where(u => u.Property.IsApproved);
                
            var count = await query.CountAsync();
            _output.WriteLine($"Query count: {count}");
            
            var results = await query
                .Take(2)
                .Select(u => new
                {
                    // Basic info
                    UnitId = u.Id,
                    UnitName = u.Name,
                    PropertyName = u.Property.Name,
                    City = u.Property.City,
                    
                    // Reviews subquery
                    AverageRating = _dbContext.Reviews
                        .Where(r => r.PropertyId == u.PropertyId)
                        .Average(r => (decimal?)r.AverageRating) ?? 0,
                    
                    // Property Images subquery
                    MainImageUrl = _dbContext.PropertyImages
                        .Where(i => i.PropertyId == u.PropertyId)
                        .OrderBy(i => i.DisplayOrder)
                        .Select(i => i.Url)
                        .FirstOrDefault(),
                    
                    // Daily Schedules - Base Price
                    BasePrice = _dbContext.DailyUnitSchedules
                        .Where(ds => ds.UnitId == u.Id &&
                                    ds.PriceAmount.HasValue &&
                                    ds.Status == "Available" &&
                                    ds.Date >= DateTime.UtcNow.Date)
                        .OrderBy(ds => ds.PriceAmount)
                        .Select(ds => (decimal?)ds.PriceAmount)
                        .FirstOrDefault() ?? 0,
                    
                    // Currency
                    Currency = _dbContext.DailyUnitSchedules
                        .Where(ds => ds.UnitId == u.Id && ds.PriceAmount.HasValue)
                        .OrderBy(ds => ds.Date)
                        .Select(ds => ds.Currency)
                        .FirstOrDefault() ?? "YER",
                    
                    // Amenities
                    MainAmenities = _dbContext.PropertyAmenities
                        .Where(pa => pa.PropertyId == u.PropertyId)
                        .Select(pa => pa.PropertyTypeAmenity.Amenity.Name)
                        .Take(5)
                        .ToList(),
                    
                    // Field Values - THIS MIGHT BE THE PROBLEM
                    DisplayFields = _dbContext.UnitFieldValues
                        .Where(fv => fv.UnitId == u.Id && fv.UnitTypeField.ShowInCards)
                        .Take(5)
                        .ToDictionary(
                            fv => fv.UnitTypeField.DisplayName ?? fv.UnitTypeField.FieldName ?? "",
                            fv => fv.FieldValue ?? ""
                        )
                })
                .ToListAsync();
            
            _output.WriteLine($"Results count: {results.Count}");
            foreach (var r in results)
            {
                _output.WriteLine($"\n  ✅ {r.UnitName} in {r.PropertyName} ({r.City})");
                _output.WriteLine($"     Rating: {r.AverageRating:F2}");
                _output.WriteLine($"     Price: {r.BasePrice} {r.Currency}");
                _output.WriteLine($"     Image: {(r.MainImageUrl != null ? "Yes" : "No")}");
                _output.WriteLine($"     Amenities: {r.MainAmenities.Count}");
                _output.WriteLine($"     DisplayFields: {r.DisplayFields.Count}");
            }
        }
        catch (Exception ex)
        {
            _output.WriteLine($"\n❌ ERROR: {ex.Message}");
            _output.WriteLine($"Stack: {ex.StackTrace}");
            if (ex.InnerException != null)
            {
                _output.WriteLine($"\nInner Exception: {ex.InnerException.Message}");
            }
        }
    }
    
    [Fact]
    public async Task Test_WithoutDisplayFields()
    {
        _output.WriteLine("Testing WITHOUT DisplayFields...");
        
        try
        {
            var query = _dbContext.Units
                .AsNoTracking()
                .Include(u => u.Property)
                .Where(u => u.Property.IsApproved);
                
            var results = await query
                .Take(5)
                .Select(u => new
                {
                    UnitId = u.Id,
                    UnitName = u.Name,
                    PropertyName = u.Property.Name,
                    City = u.Property.City,
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
        }
    }
}
