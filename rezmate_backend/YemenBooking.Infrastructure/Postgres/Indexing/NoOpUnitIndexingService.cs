using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Indexing.Models;

namespace YemenBooking.Infrastructure.Postgres.Indexing;

/// <summary>
/// تنفيذ No-Op لـ IUnitIndexingService - يستخدم فقط في Design-Time
/// </summary>
public class NoOpUnitIndexingService : IUnitIndexingService
{
    public Task<bool> OnUnitCreatedAsync(Guid unitId, CancellationToken cancellationToken = default) 
        => Task.FromResult(true);
    public Task<bool> OnUnitUpdatedAsync(Guid unitId, CancellationToken cancellationToken = default) 
        => Task.FromResult(true);
    public Task<bool> OnUnitDeletedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default) 
        => Task.FromResult(true);
    public Task<int> OnUnitTypeDeletedAsync(Guid unitTypeId, CancellationToken cancellationToken = default) 
        => Task.FromResult(0);
    public Task<int> OnUnitTypeFieldUpdatedAsync(string oldFieldName, string newFieldName, string fieldTypeId, bool isPrimaryFilter, Guid unitTypeId, CancellationToken cancellationToken = default) 
        => Task.FromResult(0);
    public Task<int> OnUnitTypeFieldDeletedAsync(string fieldName, Guid unitTypeId, CancellationToken cancellationToken = default) 
        => Task.FromResult(0);
    public Task<int> OnPropertyCreatedAsync(Guid propertyId, CancellationToken cancellationToken = default) 
        => Task.FromResult(0);
    public Task<int> OnPropertyUpdatedAsync(Guid propertyId, CancellationToken cancellationToken = default) 
        => Task.FromResult(0);
    public Task<int> OnPropertyDeletedAsync(Guid propertyId, CancellationToken cancellationToken = default) 
        => Task.FromResult(0);
    public Task<bool> OnAvailabilityChangedAsync(Guid unitId, CancellationToken cancellationToken = default) 
        => Task.FromResult(true);
    public Task<bool> OnDailyScheduleChangedAsync(Guid unitId, CancellationToken cancellationToken = default) 
        => Task.FromResult(true);
    public Task<UnitSearchResult> SearchUnitsAsync(UnitSearchRequest request, CancellationToken cancellationToken = default) 
        => Task.FromResult(new UnitSearchResult { Units = new List<UnitSearchItem>(), TotalCount = 0 });
    public Task<PropertyWithUnitsSearchResult> SearchPropertiesWithUnitsAsync(PropertyWithUnitsSearchRequest request, CancellationToken cancellationToken = default) 
        => Task.FromResult(new PropertyWithUnitsSearchResult());
    public Task<bool> RebuildUnitIndexAsync(Guid unitId, CancellationToken cancellationToken = default) 
        => Task.FromResult(true);
    public Task<int> RebuildPropertyUnitsIndexAsync(Guid propertyId, CancellationToken cancellationToken = default) 
        => Task.FromResult(0);
    public Task<int> RebuildAllIndexesAsync(int batchSize = 100, CancellationToken cancellationToken = default) 
        => Task.FromResult(0);
    public Task<int> CleanupIndexesAsync(CancellationToken cancellationToken = default) 
        => Task.FromResult(0);
    public Task<Dictionary<string, object>> GetIndexStatisticsAsync(CancellationToken cancellationToken = default) 
        => Task.FromResult(new Dictionary<string, object>());
}
