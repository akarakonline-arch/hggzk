using MediatR;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Application.Features;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.SearchAndFilters.Services;

namespace YemenBooking.Application.Features.DynamicFields.Events {

    /// <summary>
    /// معالج أحداث الحقول الديناميكية
    /// ملاحظة: هذا الـ Event Handler غير مستخدم حالياً
    /// الفهرسة تتم مباشرة من Command Handlers
    /// </summary>
    public class DynamicFieldEventHandler : INotificationHandler<DynamicFieldChangedEvent>
    {
    private readonly IUnitIndexingService _indexService;
        private readonly ILogger<DynamicFieldEventHandler> _logger;

        public DynamicFieldEventHandler(
            IUnitIndexingService indexService,
            ILogger<DynamicFieldEventHandler> logger)
        {
            _indexService = indexService;
            _logger = logger;
        }

        public Task Handle(DynamicFieldChangedEvent notification, CancellationToken cancellationToken)
        {
            // TODO: تحديث لاستخدام الدوال الجديدة في IIndexingService
            _logger.LogWarning("DynamicFieldChangedEvent is deprecated. Use direct indexing from Command Handlers.");
            return Task.CompletedTask;
        }
    }
}