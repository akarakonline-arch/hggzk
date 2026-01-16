using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.SearchAndFilters.DTOs;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Application.Features.Units.Services;

namespace YemenBooking.Application.Features.Properties.Queries.SearchProperties
{
    /// <summary>
    /// معالج استعلام البحث عن العقارات المتقدم - مبني على Redis Indexing
    /// Handler for SearchPropertiesQuery using Redis Indexing System
    /// </summary>
    public class SearchPropertiesQueryHandler : IRequestHandler<SearchPropertiesQuery, ResultDto<SearchPropertiesResponse>>
    {
    private readonly IUnitIndexingService _indexingService;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<SearchPropertiesQueryHandler> _logger;
        private readonly IUnitRepository _unitRepository;
        private readonly IAvailabilityService _availabilityService;
        private readonly IDailyUnitScheduleRepository _scheduleRepository;
        private readonly ICurrencyExchangeRepository _currencyExchangeRepository;

        public SearchPropertiesQueryHandler(
            IUnitIndexingService indexingService,
            ICurrentUserService currentUserService,
            ILogger<SearchPropertiesQueryHandler> logger,
            IUnitRepository unitRepository,
            IAvailabilityService availabilityService,
            IDailyUnitScheduleRepository scheduleRepository,
            ICurrencyExchangeRepository currencyExchangeRepository)
        {
            _indexingService = indexingService ?? throw new ArgumentNullException(nameof(indexingService));
            _currentUserService = currentUserService ?? throw new ArgumentNullException(nameof(currentUserService));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            _unitRepository = unitRepository ?? throw new ArgumentNullException(nameof(unitRepository));
            _availabilityService = availabilityService ?? throw new ArgumentNullException(nameof(availabilityService));
            _scheduleRepository = scheduleRepository ?? throw new ArgumentNullException(nameof(scheduleRepository));
            _currencyExchangeRepository = currencyExchangeRepository ?? throw new ArgumentNullException(nameof(currencyExchangeRepository));
        }

        public async Task<ResultDto<SearchPropertiesResponse>> Handle(
            SearchPropertiesQuery request,
            CancellationToken cancellationToken)
        {
            var startTime = DateTime.UtcNow;

            _logger.LogInformation(
                "🔍 بدء البحث عن العقارات - المدينة: {City}, السعر: {MinPrice}-{MaxPrice}, الصفحة: {PageNumber}/{PageSize}",
                request.City, request.MinPrice, request.MaxPrice, request.PageNumber, request.PageSize);
            
            // ━━━ تسجيل الحقول الديناميكية ━━━
            if (request.DynamicFieldFilters != null && request.DynamicFieldFilters.Any())
            {
                _logger.LogInformation(
                    "📋 الحقول الديناميكية المستقبلة: {Count} حقل",
                    request.DynamicFieldFilters.Count);
                
                foreach (var filter in request.DynamicFieldFilters)
                {
                    _logger.LogInformation(
                        "   • {Key} = {Value} ({Type})",
                        filter.Key,
                        filter.Value,
                        filter.Value?.GetType().Name ?? "null");
                }
            }
            else
            {
                _logger.LogInformation("📋 لا توجد حقول ديناميكية في الطلب");
            }

            try
            {
                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                // المرحلة 1: التحقق من صحة الطلب
                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                var validationResult = ValidateRequest(request);
                if (!validationResult.IsSuccess)
                {
                    _logger.LogWarning("⚠️ طلب البحث غير صالح: {Error}", validationResult.Message);
                    return validationResult;
                }

                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                // المرحلة 2: بناء طلب البحث في Redis
                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                var searchRequest = await BuildRedisSearchRequest(request, cancellationToken);

                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                // المرحلة 3: تنفيذ البحث في Redis Index
                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                var searchResult = await _indexingService.SearchPropertiesWithUnitsAsync(searchRequest, cancellationToken);

                _logger.LogInformation(
                    "✅ اكتمل البحث: وجد {TotalPropertiesCount} عقار و {TotalUnitsCount} وحدة - المستوى: {RelaxationLevel}",
                    searchResult.TotalPropertiesCount,
                    searchResult.TotalUnitsCount,
                    searchResult.RelaxationLevel);

                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                // المرحلة 4: تطبيق فلاتر الأمان حسب الدور
                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                var filteredProperties = await ApplySecurityFilters(searchResult.Properties, cancellationToken);

                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                // المرحلة 5: تحويل النتائج إلى DTOs
                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                var propertyDtos = await ConvertToPropertyDtos(filteredProperties, request, cancellationToken);

                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                // المرحلة 6: إعادة حساب التصفح بعد فلاتر الأمان
                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                var totalCount = propertyDtos.Count;
                var totalPages = (int)Math.Ceiling(totalCount / (double)request.PageSize);

                var pagedDtos = propertyDtos
                    .Skip((request.PageNumber - 1) * request.PageSize)
                    .Take(request.PageSize)
                    .ToList();

                _logger.LogInformation(
                    "📄 تم إرجاع {ReturnedCount} عقار من إجمالي {TotalCount}",
                    pagedDtos.Count, totalCount);

                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                // المرحلة 7: بناء النتيجة النهائية
                // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                var response = new SearchPropertiesResponse
                {
                    Properties = pagedDtos,
                    TotalCount = totalCount,
                    CurrentPage = request.PageNumber,
                    PageSize = request.PageSize,
                    TotalPages = totalPages,
                    HasPreviousPage = request.PageNumber > 1,
                    HasNextPage = request.PageNumber < totalPages,
                    AppliedFilters = BuildAppliedFilters(request),
                    SearchTimeMs = (long)(DateTime.UtcNow - startTime).TotalMilliseconds,
                    Statistics = BuildStatistics(propertyDtos, totalCount, startTime),
                    
                    // ✅ استخراج معلومات استراتيجية Fallback Search
                    RelaxationLevel = searchResult.RelaxationLevel,
                    RelaxedFilters = searchResult.RelaxedFilters,
                    UserMessage = searchResult.UserMessage,
                    SuggestedActions = searchResult.SuggestedActions
                };

                _logger.LogInformation(
                    "🎯 اكتمل البحث بنجاح في {ElapsedMs}ms - WasRelaxed: {WasRelaxed}",
                    response.SearchTimeMs,
                    response.WasRelaxed);

                return ResultDto<SearchPropertiesResponse>.Ok(response, "تم البحث بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ خطأ أثناء البحث عن العقارات");
                return ResultDto<SearchPropertiesResponse>.Failed(
                    $"حدث خطأ أثناء البحث: {ex.Message}",
                    "SEARCH_ERROR");
            }
        }

        #region === التحقق من صحة الطلب ===

        /// <summary>
        /// التحقق من صحة طلب البحث
        /// Validate search request
        /// </summary>
        private ResultDto<SearchPropertiesResponse> ValidateRequest(SearchPropertiesQuery request)
        {
            // التحقق من رقم الصفحة
            if (request.PageNumber < 1)
            {
                return ResultDto<SearchPropertiesResponse>.Failed(
                    "رقم الصفحة يجب أن يكون أكبر من صفر",
                    "INVALID_PAGE_NUMBER");
            }

            // التحقق من حجم الصفحة
            if (request.PageSize < 1 || request.PageSize > 100)
            {
                return ResultDto<SearchPropertiesResponse>.Failed(
                    "حجم الصفحة يجب أن يكون بين 1 و 100",
                    "INVALID_PAGE_SIZE");
            }

            // التحقق من نطاق التواريخ
            if (request.CheckIn.HasValue && request.CheckOut.HasValue)
            {
                // التحقق من أن CheckOut بعد CheckIn (مقارنة بسيطة بدون timezone)
                if (request.CheckIn.Value.Date >= request.CheckOut.Value.Date)
                {
                    return ResultDto<SearchPropertiesResponse>.Failed(
                        "تاريخ الوصول يجب أن يكون قبل تاريخ المغادرة",
                        "INVALID_DATE_RANGE");
                }
            }

            // التحقق من نطاق السعر
            if (request.MinPrice.HasValue && request.MaxPrice.HasValue)
            {
                if (request.MinPrice > request.MaxPrice)
                {
                    return ResultDto<SearchPropertiesResponse>.Failed(
                        "السعر الأدنى يجب أن يكون أقل من السعر الأقصى",
                        "INVALID_PRICE_RANGE");
                }
            }

            // التحقق من نصف القطر
            if (request.RadiusKm.HasValue && request.RadiusKm <= 0)
            {
                return ResultDto<SearchPropertiesResponse>.Failed(
                    "نصف القطر يجب أن يكون أكبر من صفر",
                    "INVALID_RADIUS");
            }

            return ResultDto<SearchPropertiesResponse>.Ok(null);
        }

        #endregion

        #region === بناء طلب البحث في Redis ===

        /// <summary>
        /// بناء طلب البحث في Redis من طلب البحث الأصلي
        /// Building Redis search request from the original search query
        /// </summary>
        private async Task<PropertyWithUnitsSearchRequest> BuildRedisSearchRequest(
            SearchPropertiesQuery query,
            CancellationToken cancellationToken)
        {
            // ━━━ تحويل التواريخ إلى UTC ━━━
            var checkInUtc = query.CheckIn.HasValue
                ? await _currentUserService.ConvertFromUserLocalToUtcAsync(query.CheckIn.Value)
                : (DateTime?)null;

            var checkOutUtc = query.CheckOut.HasValue
                ? await _currentUserService.ConvertFromUserLocalToUtcAsync(query.CheckOut.Value)
                : (DateTime?)null;

            // ━━━ حساب عدد الضيوف الفعلي ━━━
            // إعطاء الأولوية لـ Adults + Children إذا كانا موجودين
            int? effectiveGuests = null;
            if (query.Adults.HasValue || query.Children.HasValue)
            {
                var adults = Math.Max(0, query.Adults ?? 0);
                var children = Math.Max(0, query.Children ?? 0);
                effectiveGuests = adults + children;
            }
            else if (query.GuestsCount.HasValue)
            {
                effectiveGuests = query.GuestsCount;
            }

            // ━━━ بناء طلب البحث ━━━
            var searchRequest = new PropertyWithUnitsSearchRequest
            {
                // ━━━ النص والموقع (Text & Location) ━━━
                SearchText = NormalizeSearchText(query.SearchTerm),
                City = NormalizeCity(query.City),

                // ━━━ التواريخ (Dates) ━━━
                CheckIn = checkInUtc,
                CheckOut = checkOutUtc,

                // ━━━ السعة (Capacity) ━━━
                GuestsCount = effectiveGuests,
                AdultsCount = query.Adults,
                ChildrenCount = query.Children,

                // ━━━ السعر (Price) ━━━
                MinPrice = query.MinPrice,
                MaxPrice = query.MaxPrice,
                PreferredCurrency = NormalizeCurrency(query.PreferredCurrency),

                // ━━━ التقييم (Rating) ━━━
                MinRating = query.MinStarRating.HasValue ? (decimal)query.MinStarRating.Value : null,

                // ━━━ نوع العقار (Property Type) ━━━
                PropertyTypeId = query.PropertyTypeId,

                // ━━━ نوع الوحدة (Unit Type) ━━━
                UnitTypeId = query.UnitTypeId,

                // ━━━ المرافق والخدمات (Amenities & Services) ━━━
                RequiredAmenities = query.RequiredAmenities?.ToList(),

                // ━━━ الحقول الديناميكية (Dynamic Fields) ━━━
                DynamicFieldFilters = BuildDynamicFieldFilters(query.DynamicFieldFilters),

                // ━━━ البحث الجغرافي (Geographic Search) ━━━
                Latitude = query.Latitude,
                Longitude = query.Longitude,
                RadiusKm = query.RadiusKm.HasValue ? (double)query.RadiusKm.Value : null,

                // ━━━ الترتيب والتصفح (Sorting & Pagination) ━━━
                SortBy = NormalizeSortBy(query.SortBy, query.Latitude, query.Longitude),
                PageNumber = query.PageNumber,
                PageSize = query.PageSize,
                
                // ━━━ إعدادات تجميع النتائج (Grouping Settings) ━━━
                GroupByProperty = true, // نريد تجميع النتائج حسب العقار
                MaxUnitsPerProperty = null // عرض جميع الوحدات المطابقة
            };

            return searchRequest;
        }

        /// <summary>
        /// تطبيع نص البحث
        /// </summary>
        private string? NormalizeSearchText(string? searchText)
        {
            if (string.IsNullOrWhiteSpace(searchText))
                return null;

            return searchText.Trim();
        }

        /// <summary>
        /// تطبيع اسم المدينة
        /// </summary>
        private string? NormalizeCity(string? city)
        {
            if (string.IsNullOrWhiteSpace(city))
                return null;

            return city.Trim();
        }

        /// <summary>
        /// تطبيع رمز العملة
        /// </summary>
        private string NormalizeCurrency(string? currency)
        {
            if (string.IsNullOrWhiteSpace(currency))
                return "YER";

            return currency.ToUpperInvariant();
        }

        /// <summary>
        /// بناء فلاتر الحقول الديناميكية - إزالة القيم الفارغة فقط
        /// Build dynamic field filters - remove empty values only
        /// </summary>
        private Dictionary<string, string>? BuildDynamicFieldFilters(
            Dictionary<string, string>? filters)
        {
            if (filters == null || !filters.Any())
                return null;

            // فلترة القيم الفارغة فقط
            // Filter empty values only
            var result = filters
                .Where(f => !string.IsNullOrWhiteSpace(f.Value))
                .ToDictionary(f => f.Key, f => f.Value);

            return result.Any() ? result : null;
        }

        /// <summary>
        /// تطبيع قيمة الترتيب
        /// </summary>
        private string? NormalizeSortBy(string? sortBy, decimal? latitude, decimal? longitude)
        {
            if (string.IsNullOrWhiteSpace(sortBy))
                return null;

            var normalized = sortBy.Trim().ToLowerInvariant();

            return normalized switch
            {
                "distance" => (latitude.HasValue && longitude.HasValue) ? "distance" : null,
                "price_asc" => "price_asc",
                "price_desc" => "price_desc",
                "rating" => "rating",
                "newest" => "newest",
                "popularity" => "popular",
                "recommended" => null,
                _ => normalized
            };
        }

        #endregion

        #region === فلاتر الأمان ===

        /// <summary>
        /// تطبيق فلاتر الأمان حسب دور المستخدم
        /// Apply security filters based on user role
        /// </summary>
        private async Task<List<PropertyGroupSearchItem>> ApplySecurityFilters(
            List<PropertyGroupSearchItem> properties,
            CancellationToken cancellationToken)
        {
            var userRole = _currentUserService.Role;
            var userId = _currentUserService.UserId;

            // ━━━ Admin: لا قيود ━━━
            if (string.Equals(userRole, "Admin", StringComparison.OrdinalIgnoreCase))
            {
                _logger.LogDebug("🔓 Admin - لا توجد فلاتر أمان");
                return properties;
            }

            // ━━━ Owner: فقط عقاراته ━━━
            if (string.Equals(userRole, "Owner", StringComparison.OrdinalIgnoreCase))
            {
                _logger.LogDebug("👤 Owner - فلترة حسب المالك {UserId}", userId);

                // TODO: PropertySearchItem يجب أن يحتوي على OwnerId
                // مؤقتاً نُرجع جميع العقارات
                return properties;
            }

            // ━━━ Guest/User: فقط العقارات المعتمدة ━━━
            _logger.LogDebug("👥 Guest/User - فلترة العقارات المعتمدة فقط");

            // TODO: PropertySearchItem يجب أن يحتوي على IsApproved
            // مؤقتاً نُرجع جميع العقارات
            return properties;
        }

        #endregion

        #region === تحويل إلى DTOs ===

        /// <summary>
        /// تحويل PropertySearchItem إلى PropertySearchResultDto
        /// </summary>
        private async Task<List<PropertySearchResultDto>> ConvertToPropertyDtos(
            List<PropertyGroupSearchItem> items,
            SearchPropertiesQuery query,
            CancellationToken cancellationToken)
        {
            var dtos = new List<PropertySearchResultDto>();

            foreach (var item in items)
            {
                try
                {
                    var dto = await ConvertToPropertyDto(item, query, cancellationToken);
                    
                    // ✅ نسخ الفروقات من نتيجة البحث إلى DTO
                    dto.FilterMismatches = item.FilterMismatches;
                    
                    dtos.Add(dto);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "⚠️ خطأ في تحويل العقار {PropertyId}", item.PropertyId);
                }
            }

            return dtos;
        }

        /// <summary>
        /// تحويل عنصر واحد من PropertyGroupSearchItem إلى PropertySearchResultDto
        /// </summary>
        private async Task<PropertySearchResultDto> ConvertToPropertyDto(
            PropertyGroupSearchItem item,
            SearchPropertiesQuery query,
            CancellationToken cancellationToken)
        {
            var propertyId = item.PropertyId;

            // ━━━ بناء DTO أساسي ━━━
            var dto = new PropertySearchResultDto
            {
                Id = propertyId,
                Name = item.PropertyName,
                Description = string.Empty,
                PropertyType = item.PropertyTypeName ?? string.Empty,
                Address = item.Address,
                City = item.City,
                MinPrice = item.PriceRange?.Min ?? 0,
                DiscountedPrice = item.PriceRange?.Min ?? 0,
                Currency = "YER",
                StarRating = item.StarRating,
                AverageRating = item.AverageRating,
                ReviewsCount = 0,
                MainImageUrl = item.MainImageUrl ?? item.ImageUrls?.FirstOrDefault() ?? string.Empty,
                ImageUrls = item.ImageUrls ?? new List<string>(),
                IsAvailable = true,
                IsFavorite = false,
                IsFeatured = item.IsFeatured,
                Latitude = item.Latitude,
                Longitude = item.Longitude,
                MaxCapacity = item.MatchedUnits?.Max(u => u.MaxCapacity) ?? 0,
                AvailableUnitsCount = item.MatchedUnitsCount,
                DynamicFieldValues = new Dictionary<string, object>(),
                MainAmenities = item.AvailableAmenities ?? new List<string>(),
                LastUpdated = await _currentUserService.ConvertFromUtcToUserLocalAsync(DateTime.UtcNow)
            };

            // ━━━ حساب الإتاحة والسعر إذا كانت هناك تواريخ ━━━
            if (query.CheckIn.HasValue && query.CheckOut.HasValue)
            {
                await CalculateAvailabilityAndPricing(dto, query, cancellationToken);
            }
            else if (query.UnitTypeId.HasValue || query.GuestsCount.HasValue)
            {
                await SelectBestUnit(dto, query, cancellationToken);
            }

            // ━━━ تحويل العملة إذا طُلب ━━━
            if (!string.IsNullOrWhiteSpace(query.PreferredCurrency) &&
                !string.Equals(dto.Currency, query.PreferredCurrency, StringComparison.OrdinalIgnoreCase))
            {
                await ConvertCurrency(dto, query.PreferredCurrency, cancellationToken);
            }

            // ━━━ حساب المسافة إذا كان بحث جغرافي ━━━
            if (query.Latitude.HasValue && query.Longitude.HasValue)
            {
                dto.DistanceKm = CalculateDistance(
                    (double)query.Latitude.Value,
                    (double)query.Longitude.Value,
                    (double)dto.Latitude,
                    (double)dto.Longitude);
            }

            return dto;
        }

        /// <summary>
        /// حساب الإتاحة والتسعير للعقار بناءً على التواريخ
        /// </summary>
        private async Task CalculateAvailabilityAndPricing(
            PropertySearchResultDto dto,
            SearchPropertiesQuery query,
            CancellationToken cancellationToken)
        {
            try
            {
                var checkIn = query.CheckIn!.Value;
                var checkOut = query.CheckOut!.Value;
                var guestCount = query.GuestsCount ?? 1;

                // ━━━ الحصول على الوحدات المتاحة ━━━
                var availableUnitIds = await _availabilityService
                    .GetAvailableUnitsInPropertyAsync(dto.Id, checkIn, checkOut, guestCount, cancellationToken);

                // ━━━ تطبيق فلاتر إضافية (نوع الوحدة، السعة) ━━━
                var filteredAvailable = new List<Guid>();
                foreach (var unitId in availableUnitIds)
                {
                    var unit = await _unitRepository.GetUnitByIdAsync(unitId, cancellationToken);
                    if (unit != null &&
                        (!query.UnitTypeId.HasValue || unit.UnitTypeId == query.UnitTypeId.Value) &&
                        unit.MaxCapacity >= guestCount)
                    {
                        filteredAvailable.Add(unitId);
                    }
                }

                dto.AvailableUnitsCount = filteredAvailable.Count;
                dto.IsAvailable = dto.AvailableUnitsCount > 0;

                if (!filteredAvailable.Any())
                {
                    _logger.LogDebug("⚠️ لا توجد وحدات متاحة للعقار {PropertyId}", dto.Id);
                    return;
                }

                // ━━━ اختيار الوحدة المناسبة ━━━
                var selectedUnitId = await SelectBestAvailableUnit(
                    filteredAvailable, query.UnitTypeId, guestCount, cancellationToken);

                if (selectedUnitId != Guid.Empty)
                {
                    await SetUnitPricing(dto, selectedUnitId, checkIn, checkOut, cancellationToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "⚠️ خطأ في حساب الإتاحة والتسعير للعقار {PropertyId}", dto.Id);
            }
        }

        /// <summary>
        /// اختيار أفضل وحدة متاحة
        /// </summary>
        private async Task<Guid> SelectBestAvailableUnit(
            List<Guid> availableUnitIds,
            Guid? preferredUnitTypeId,
            int guestCount,
            CancellationToken cancellationToken)
        {
            // ━━━ البحث عن وحدة من النوع المفضل أولاً ━━━
            if (preferredUnitTypeId.HasValue)
            {
                foreach (var unitId in availableUnitIds)
                {
                    var unit = await _unitRepository.GetUnitByIdAsync(unitId, cancellationToken);
                    if (unit != null &&
                        unit.UnitTypeId == preferredUnitTypeId.Value &&
                        unit.MaxCapacity >= guestCount)
                    {
                        return unitId;
                    }
                }
            }

            // ━━━ إذا لم توجد، نختار أول وحدة متاحة ━━━
            return availableUnitIds.FirstOrDefault();
        }

        /// <summary>
        /// تعيين بيانات التسعير من الوحدة المحددة
        /// </summary>
        private async Task SetUnitPricing(
            PropertySearchResultDto dto,
            Guid unitId,
            DateTime checkIn,
            DateTime checkOut,
            CancellationToken cancellationToken)
        {
            var unit = await _unitRepository.GetUnitByIdAsync(unitId, cancellationToken);
            if (unit == null)
                return;

            dto.UnitId = unitId;
            dto.UnitName = unit.Name;
            dto.MaxCapacity = unit.MaxCapacity;

            // ━━━ حساب السعر الإجمالي من الجداول اليومية ━━━
            var schedules = await _scheduleRepository.GetByUnitAndDateRangeAsync(
                unitId, checkIn, checkOut);
            
            var totalPrice = schedules.Sum(s => s.PriceAmount ?? 0);
            var nights = Math.Max(1, (checkOut - checkIn).Days);
            var perNight = totalPrice / nights;

            dto.MinPrice = perNight;
            dto.DiscountedPrice = perNight;
            dto.Currency = schedules.FirstOrDefault()?.Currency ?? dto.Currency;
        }

        /// <summary>
        /// اختيار أفضل وحدة بدون تواريخ (بناءً على السعر)
        /// </summary>
        private async Task SelectBestUnit(
            PropertySearchResultDto dto,
            SearchPropertiesQuery query,
            CancellationToken cancellationToken)
        {
            try
            {
                var units = await _unitRepository.GetByPropertyIdAsync(dto.Id, cancellationToken);
                var guestCount = query.GuestsCount ?? 1;

                // ━━━ فلترة الوحدات حسب المعايير ━━━
                var filteredUnits = units
                    .Where(u => !query.UnitTypeId.HasValue || u.UnitTypeId == query.UnitTypeId.Value)
                    .Where(u => u.MaxCapacity >= guestCount)
                    .ToList();

                if (!filteredUnits.Any())
                {
                    _logger.LogDebug("⚠️ لا توجد وحدات مناسبة للعقار {PropertyId}", dto.Id);
                    return;
                }

                // ━━━ جلب السعر من DailyUnitSchedule لكل وحدة ━━━
                var today = DateTime.UtcNow.Date;
                var unitsWithPrices = new List<(Core.Entities.Unit Unit, decimal Price, string Currency)>();

                foreach (var unit in filteredUnits)
                {
                    var schedule = await _scheduleRepository.GetByUnitAndDateAsync(unit.Id, today);
                    if (schedule != null && schedule.PriceAmount.HasValue)
                    {
                        var discountedPrice = schedule.PriceAmount.Value * (1 - unit.DiscountPercentage / 100);
                        unitsWithPrices.Add((unit, discountedPrice, schedule.Currency ?? "YER"));
                    }
                }

                if (!unitsWithPrices.Any())
                {
                    _logger.LogDebug("⚠️ لا توجد أسعار متاحة في DailyUnitSchedule للعقار {PropertyId}", dto.Id);
                    return;
                }

                // ━━━ اختيار الوحدة الأرخص ━━━
                var chosenUnitWithPrice = unitsWithPrices.OrderBy(u => u.Price).First();

                dto.UnitId = chosenUnitWithPrice.Unit.Id;
                dto.UnitName = chosenUnitWithPrice.Unit.Name;
                dto.MinPrice = chosenUnitWithPrice.Price;
                dto.DiscountedPrice = chosenUnitWithPrice.Price;
                dto.Currency = chosenUnitWithPrice.Currency;
                dto.MaxCapacity = chosenUnitWithPrice.Unit.MaxCapacity;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "⚠️ خطأ في اختيار وحدة للعقار {PropertyId}", dto.Id);
            }
        }

        /// <summary>
        /// تحويل العملة
        /// </summary>
        private async Task ConvertCurrency(
            PropertySearchResultDto dto,
            string targetCurrency,
            CancellationToken cancellationToken)
        {
            try
            {
                var target = targetCurrency.ToUpperInvariant();
                if (string.Equals(dto.Currency, target, StringComparison.OrdinalIgnoreCase))
                    return;

                var rate = await _currencyExchangeRepository.GetExchangeRateAsync(
                    dto.Currency, target);

                if (rate != null && rate.Rate > 0)
                {
                    dto.MinPrice = Math.Round(dto.MinPrice * rate.Rate, 2);
                    dto.DiscountedPrice = Math.Round(dto.DiscountedPrice * rate.Rate, 2);
                    dto.Currency = target;

                    _logger.LogDebug("💱 تم تحويل العملة من {From} إلى {To}", dto.Currency, target);
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "⚠️ خطأ في تحويل العملة للعقار {PropertyId}", dto.Id);
            }
        }

        /// <summary>
        /// حساب المسافة بين نقطتين (Haversine formula)
        /// </summary>
        private double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
        {
            const double R = 6371; // نصف قطر الأرض بالكيلومتر

            var dLat = ToRadians(lat2 - lat1);
            var dLon = ToRadians(lon2 - lon1);

            var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                    Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                    Math.Sin(dLon / 2) * Math.Sin(dLon / 2);

            var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));

            return R * c;
        }

        private double ToRadians(double degrees) => degrees * Math.PI / 180;

        #endregion

        #region === بناء البيانات الوصفية ===

        /// <summary>
        /// بناء الفلاتر المطبقة
        /// </summary>
        private SearchFiltersDto BuildAppliedFilters(SearchPropertiesQuery request)
        {
            var filters = new SearchFiltersDto();

            // TODO: ملء الفلاتر المطبقة
            // يمكن إضافة الحقول المطلوبة حسب SearchFiltersDto

            return filters;
        }

        /// <summary>
        /// بناء إحصائيات البحث
        /// </summary>
        private SearchStatisticsDto BuildStatistics(
            List<PropertySearchResultDto> properties,
            int totalCount,
            DateTime startTime)
        {
            var duration = (long)(DateTime.UtcNow - startTime).TotalMilliseconds;

            var priceRange = properties.Any() ? new PriceRangeDto
            {
                MinPrice = properties.Min(p => p.MinPrice),
                MaxPrice = properties.Max(p => p.MinPrice),
                AveragePrice = properties.Average(p => p.MinPrice)
            } : null;

            var propertiesByType = properties
                .GroupBy(p => string.IsNullOrWhiteSpace(p.PropertyType) ? "غير محدد" : p.PropertyType)
                .ToDictionary(g => g.Key, g => g.Count());

            return new SearchStatisticsDto
            {
                SearchDurationMs = duration,
                AppliedFiltersCount = CountAppliedFilters(),
                TotalResultsBeforePaging = totalCount,
                PriceRange = priceRange,
                PropertiesByType = propertiesByType,
                AverageRating = properties.Any() ? (double)properties.Average(p => p.AverageRating) : 0
            };
        }

        /// <summary>
        /// عد الفلاتر المطبقة
        /// </summary>
        private int CountAppliedFilters()
        {
            // TODO: حساب عدد الفلاتر المطبقة
            return 0;
        }

        #endregion
    }
}
