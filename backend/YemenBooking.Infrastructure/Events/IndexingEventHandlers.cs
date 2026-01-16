using System.Threading.Tasks;
using System.Threading;
using Microsoft.Extensions.Logging;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Events;

namespace YemenBooking.Infrastructure.Events
{
    // Property handlers
    public sealed class PropertyCreatedEventHandler : IDomainEventHandler<PropertyCreatedEvent>
    {
        private readonly IUnitIndexingService _indexing;
        private readonly ILogger<PropertyCreatedEventHandler> _logger;

        public PropertyCreatedEventHandler(IUnitIndexingService indexing, ILogger<PropertyCreatedEventHandler> logger)
        {
            _indexing = indexing;
            _logger = logger;
        }

        public async Task Handle(PropertyCreatedEvent domainEvent)
        {
            _logger.LogDebug("Handling PropertyCreatedEvent {PropertyId}", domainEvent.PropertyId);
            await _indexing.OnPropertyCreatedAsync(domainEvent.PropertyId, CancellationToken.None);
        }
    }

    public sealed class PropertyUpdatedEventHandler : IDomainEventHandler<PropertyUpdatedEvent>
    {
        private readonly IUnitIndexingService _indexing;
        private readonly ILogger<PropertyUpdatedEventHandler> _logger;

        public PropertyUpdatedEventHandler(IUnitIndexingService indexing, ILogger<PropertyUpdatedEventHandler> logger)
        {
            _indexing = indexing;
            _logger = logger;
        }

        public async Task Handle(PropertyUpdatedEvent domainEvent)
        {
            _logger.LogDebug("Handling PropertyUpdatedEvent {PropertyId}", domainEvent.PropertyId);
            await _indexing.OnPropertyUpdatedAsync(domainEvent.PropertyId, CancellationToken.None);
        }
    }

    public sealed class PropertyDeletedEventHandler : IDomainEventHandler<PropertyDeletedEvent>
    {
        private readonly IUnitIndexingService _indexing;
        private readonly ILogger<PropertyDeletedEventHandler> _logger;

        public PropertyDeletedEventHandler(IUnitIndexingService indexing, ILogger<PropertyDeletedEventHandler> logger)
        {
            _indexing = indexing;
            _logger = logger;
        }

        public async Task Handle(PropertyDeletedEvent domainEvent)
        {
            _logger.LogDebug("Handling PropertyDeletedEvent {PropertyId}", domainEvent.PropertyId);
            await _indexing.OnPropertyDeletedAsync(domainEvent.PropertyId, CancellationToken.None);
        }
    }

    // Unit handlers
    public sealed class UnitCreatedEventHandler : IDomainEventHandler<UnitCreatedEvent>
    {
        private readonly IUnitIndexingService _indexing;
        private readonly ILogger<UnitCreatedEventHandler> _logger;

        public UnitCreatedEventHandler(IUnitIndexingService indexing, ILogger<UnitCreatedEventHandler> logger)
        {
            _indexing = indexing;
            _logger = logger;
        }

        public async Task Handle(UnitCreatedEvent domainEvent)
        {
            _logger.LogDebug("Handling UnitCreatedEvent {UnitId}", domainEvent.UnitId);
            await _indexing.OnUnitCreatedAsync(domainEvent.UnitId, CancellationToken.None);
        }
    }

    public sealed class UnitUpdatedEventHandler : IDomainEventHandler<UnitUpdatedEvent>
    {
        private readonly IUnitIndexingService _indexing;
        private readonly ILogger<UnitUpdatedEventHandler> _logger;

        public UnitUpdatedEventHandler(IUnitIndexingService indexing, ILogger<UnitUpdatedEventHandler> logger)
        {
            _indexing = indexing;
            _logger = logger;
        }

        public async Task Handle(UnitUpdatedEvent domainEvent)
        {
            _logger.LogDebug("Handling UnitUpdatedEvent {UnitId}", domainEvent.UnitId);
            await _indexing.OnUnitUpdatedAsync(domainEvent.UnitId, CancellationToken.None);
        }
    }

    public sealed class UnitDeletedEventHandler : IDomainEventHandler<UnitDeletedEvent>
    {
        private readonly IUnitIndexingService _indexing;
        private readonly ILogger<UnitDeletedEventHandler> _logger;

        public UnitDeletedEventHandler(IUnitIndexingService indexing, ILogger<UnitDeletedEventHandler> logger)
        {
            _indexing = indexing;
            _logger = logger;
        }

        public async Task Handle(UnitDeletedEvent domainEvent)
        {
            _logger.LogDebug("Handling UnitDeletedEvent {UnitId}", domainEvent.UnitId);
            await _indexing.OnUnitDeletedAsync(domainEvent.UnitId, domainEvent.PropertyId, CancellationToken.None);
        }
    }

    // Availability handler
    public sealed class AvailabilityChangedEventHandler : IDomainEventHandler<AvailabilityChangedEvent>
    {
        private readonly IUnitIndexingService _indexing;
        private readonly ILogger<AvailabilityChangedEventHandler> _logger;

        public AvailabilityChangedEventHandler(IUnitIndexingService indexing, ILogger<AvailabilityChangedEventHandler> logger)
        {
            _indexing = indexing;
            _logger = logger;
        }

        public async Task Handle(AvailabilityChangedEvent domainEvent)
        {
            _logger.LogDebug("Handling AvailabilityChangedEvent {UnitId}", domainEvent.UnitId);
            await _indexing.OnAvailabilityChangedAsync(domainEvent.UnitId, CancellationToken.None);
        }
    }

    // Dynamic fields handler - deprecated
    public sealed class DynamicFieldChangedEventHandler : IDomainEventHandler<DynamicFieldChangedEvent>
    {
        private readonly ILogger<DynamicFieldChangedEventHandler> _logger;

        public DynamicFieldChangedEventHandler(ILogger<DynamicFieldChangedEventHandler> logger)
        {
            _logger = logger;
        }

        public Task Handle(DynamicFieldChangedEvent domainEvent)
        {
            _logger.LogDebug("DynamicFieldChangedEvent is deprecated. PropertyId: {PropertyId}, Field: {FieldName}", 
                domainEvent.PropertyId, domainEvent.FieldName);
            return Task.CompletedTask;
        }
    }
}
