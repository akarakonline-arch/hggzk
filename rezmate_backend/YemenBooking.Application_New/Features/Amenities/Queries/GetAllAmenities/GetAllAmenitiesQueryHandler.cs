using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Amenities;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.Amenities.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Amenities.Queries.GetAllAmenities;

/// <summary>
/// معالج استعلام الحصول على جميع وسائل الراحة مع دعم الترقيم
/// Handler for get all amenities query with pagination support
/// </summary>
public class GetAllAmenitiesQueryHandler : IRequestHandler<GetAllAmenitiesQuery, ResultDto<PaginatedResultDto<AmenityDto>>>
{
    private readonly IAmenityRepository _amenityRepository;
    private readonly ILogger<GetAllAmenitiesQueryHandler> _logger;

    /// <summary>
    /// منشئ معالج استعلام الحصول على جميع وسائل الراحة
    /// Constructor for get all amenities query handler
    /// </summary>
    /// <param name="amenityRepository">مستودع وسائل الراحة</param>
    /// <param name="logger">مسجل الأحداث</param>
    public GetAllAmenitiesQueryHandler(
        IAmenityRepository amenityRepository,
        ILogger<GetAllAmenitiesQueryHandler> logger)
    {
        _amenityRepository = amenityRepository;
        _logger = logger;
    }

    /// <summary>
    /// معالجة استعلام الحصول على جميع وسائل الراحة
    /// Handle get all amenities query
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة مرقمة من وسائل الراحة</returns>
    public async Task<ResultDto<PaginatedResultDto<AmenityDto>>> Handle(GetAllAmenitiesQuery request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء استعلام الحصول على جميع وسائل الراحة. الصفحة: {Page}, الحجم: {Size}", 
                request.PageNumber, request.PageSize);

            // الحصول على وسائل الراحة من قاعدة البيانات
            var allAmenities = await _amenityRepository.GetAllAsync(cancellationToken);
            
            // فلترة المرافق النشطة فقط
            var query = allAmenities?.Where(a => a.IsActive) ?? Enumerable.Empty<YemenBooking.Core.Entities.Amenity>();

            // تطبيق البحث إذا تم تحديده
            if (!string.IsNullOrWhiteSpace(request.SearchTerm))
            {
                var searchTerm = request.SearchTerm.ToLower();
                query = query.Where(a => 
                    (a.Name != null && a.Name.ToLower().Contains(searchTerm)) ||
                    (a.Description != null && a.Description.ToLower().Contains(searchTerm)));
            }

            // الحصول على العدد الإجمالي قبل الترقيم
            var totalCount = query.Count();
            
            // تطبيق الترقيم
            var pagedAmenities = query
                .OrderBy(a => a.Name)
                .Skip((request.PageNumber - 1) * request.PageSize)
                .Take(request.PageSize)
                .ToList();

            // تحويل البيانات إلى DTO
            var amenityDtos = pagedAmenities.Select(amenity => new AmenityDto
            {
                Id = amenity.Id,
                Name = amenity.Name,
                Description = amenity.Description ?? string.Empty,
                Icon = amenity.Icon ?? string.Empty,
                IconUrl = amenity.Icon ?? string.Empty,
                Category = amenity.Name ?? string.Empty,
                IsActive = amenity.IsActive
            }).ToList();

            // حساب عدد الصفحات
            var totalPages = (int)Math.Ceiling((double)totalCount / request.PageSize);

            // إنشاء نتيجة مرقمة
            var paginatedResult = new PaginatedResultDto<AmenityDto>
            {
                Items = amenityDtos,
                Total = totalCount,
                Page = request.PageNumber,
                Limit = request.PageSize,
                TotalPages = totalPages
            };

            _logger.LogInformation("تم الحصول على {Count} وسيلة راحة من إجمالي {Total}", 
                amenityDtos.Count, totalCount);

            return ResultDto<PaginatedResultDto<AmenityDto>>.Ok(
                paginatedResult, 
                $"تم الحصول على {amenityDtos.Count} وسيلة راحة من إجمالي {totalCount}"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء الحصول على وسائل الراحة");
            return ResultDto<PaginatedResultDto<AmenityDto>>.Failed(
                $"حدث خطأ أثناء الحصول على وسائل الراحة: {ex.Message}", 
                "GET_AMENITIES_ERROR"
            );
        }
    }
}
