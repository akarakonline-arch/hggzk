using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties;
using YemenBooking.Application.Features.Properties;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Helpers;
using YemenBooking.Application.Features.Amenities.DTOs;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features.Services.DTOs;
using YemenBooking.Application.Features.Units.DTOs;
using YemenBooking.Application.Features;
using System.Text.Json;

namespace YemenBooking.Application.Features.Properties.Queries.GetPropertyDetails;

/// <summary>
/// معالج استعلام الحصول على تفاصيل الكيان للعميل
/// Handler for client get property details query
/// </summary>
public class ClientGetPropertyDetailsQueryHandler : IRequestHandler<GetPropertyDetailsQuery, ResultDto<PropertyDetailsDto>>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IAmenityRepository _amenityRepository;
    private readonly IPropertyServiceRepository _propertyServiceRepository;
    private readonly IPropertyPolicyRepository _propertyPolicyRepository;
    private readonly ILogger<ClientGetPropertyDetailsQueryHandler> _logger;

    public ClientGetPropertyDetailsQueryHandler(
        IUnitOfWork unitOfWork,
        IAmenityRepository amenityRepository,
        IPropertyServiceRepository propertyServiceRepository,
        IPropertyPolicyRepository propertyPolicyRepository,
        ILogger<ClientGetPropertyDetailsQueryHandler> logger)
    {
        _unitOfWork = unitOfWork;
        _amenityRepository = amenityRepository;
        _propertyServiceRepository = propertyServiceRepository;
        _propertyPolicyRepository = propertyPolicyRepository;
        _logger = logger;
    }

    /// <summary>
    /// معالجة استعلام الحصول على تفاصيل الكيان
    /// Handle get property details query
    /// </summary>
    /// <param name="request">الطلب</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة العملية</returns>
    public async Task<ResultDto<PropertyDetailsDto>> Handle(GetPropertyDetailsQuery request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("جلب تفاصيل الكيان {PropertyId} للمستخدم {UserId}", request.PropertyId, request.UserId);

            // التحقق من صحة المعاملات
            if (request.PropertyId == Guid.Empty)
            {
                return ResultDto<PropertyDetailsDto>.Failure("معرف الكيان غير صحيح");
            }

            // البحث عن الكيان
            var propertyRepo = _unitOfWork.Repository<Core.Entities.Property>();
            var property = await propertyRepo.GetByIdAsync(request.PropertyId);

            if (property == null)
            {
                _logger.LogWarning("الكيان غير موجود {PropertyId}", request.PropertyId);
                return ResultDto<PropertyDetailsDto>.Failure("الكيان غير موجود");
            }

            // تحويل إلى DTO
            var propertyDetails = await MapToPropertyDetailsDto(property, request.UserId);

            _logger.LogInformation("تم جلب تفاصيل الكيان {PropertyId} بنجاح", request.PropertyId);

            return ResultDto<PropertyDetailsDto>.SuccessResult(propertyDetails);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء جلب تفاصيل الكيان {PropertyId}", request.PropertyId);
            return ResultDto<PropertyDetailsDto>.Failure("حدث خطأ أثناء جلب التفاصيل");
        }
    }

    /// <summary>
    /// تحويل الكيان إلى DTO
    /// Map property to details DTO
    /// </summary>
    private async Task<PropertyDetailsDto> MapToPropertyDetailsDto(Core.Entities.Property property, Guid? userId)
    {
        var dto = new PropertyDetailsDto
        {
            Id = property.Id,
            Name = property.Name,
            TypeId = property.TypeId,
            PropertyType = await GetPropertyTypeDto(property.TypeId),
            Address = property.Address,
            City = property.City,
            Latitude = property.Latitude,
            Longitude = property.Longitude,
            StarRating = property.StarRating,
            Description = property.Description,
            AverageRating = property.AverageRating,
            ReviewsCount = await GetReviewsCount(property.Id),
            ViewCount = await GetViewCount(property.Id),
            BookingCount = await GetBookingCount(property.Id),
            IsFavorite = await IsInFavorites(property.Id, userId),
            Images = await GetPropertyImages(property.Id),
            Amenities = await GetPropertyAmenities(property.Id),
            Services = await GetPropertyServices(property.Id),
            Policies = await GetPropertyPolicies(property.Id),
            Units = await GetPropertyUnits(property.Id),
            IsApproved = property.IsApproved,
        };

        dto.UnitsCount = dto.Units?.Count ?? 0;

        return dto;
    }

    /// <summary>
    /// الحصول على بيانات نوع الكيان
    /// Get property type DTO
    /// </summary>
    private async Task<PropertyTypeDto> GetPropertyTypeDto(Guid propertyTypeId)
    {
        try
        {
            var propertyTypeRepo = _unitOfWork.Repository<Core.Entities.PropertyType>();
            var propertyType = await propertyTypeRepo.GetByIdAsync(propertyTypeId);

            if (propertyType == null)
            {
                return new PropertyTypeDto
                {
                    Id = Guid.Empty,
                    Name = "غير محدد",
                    Description = "نوع غير محدد"
                };
            }

            return new PropertyTypeDto
            {
                Id = propertyType.Id,
                Name = propertyType.Name,
                Description = propertyType.Description ?? string.Empty
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في جلب نوع الكيان {PropertyTypeId}", propertyTypeId);
            return new PropertyTypeDto
            {
                Id = Guid.Empty,
                Name = "غير محدد",
                Description = "خطأ في جلب البيانات"
            };
        }
    }

    /// <summary>
    /// الحصول على عدد المراجعات
    /// Get reviews count
    /// </summary>
    private async Task<int> GetReviewsCount(Guid propertyId)
    {
        try
        {
            var reviewRepo = _unitOfWork.Repository<Core.Entities.Review>();
            var reviews = await reviewRepo.GetAllAsync();
            return reviews.Count(r => r.PropertyId == propertyId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في جلب عدد المراجعات للكيان {PropertyId}", propertyId);
            return 0;
        }
    }

    /// <summary>
    /// الحصول على عدد المشاهدات
    /// Get view count
    /// </summary>
    private async Task<int> GetViewCount(Guid propertyId)
    {
        try
        {
            // سيتم تطوير هذا لاحقاً عند إضافة نظام تتبع المشاهدات
            return 0;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في جلب عدد المشاهدات للكيان {PropertyId}", propertyId);
            return 0;
        }
    }

    /// <summary>
    /// الحصول على عدد الحجوزات
    /// Get booking count
    /// </summary>
    private async Task<int> GetBookingCount(Guid propertyId)
    {
        try
        {
            var bookingRepo = _unitOfWork.Repository<Core.Entities.Booking>();
            var bookings = await bookingRepo.GetAllAsync();
            
            // جلب جميع الوحدات للكيان أولاً
            var unitRepo = _unitOfWork.Repository<Core.Entities.Unit>();
            var units = await unitRepo.GetAllAsync();
            var propertyUnitIds = units.Where(u => u.PropertyId == propertyId).Select(u => u.Id).ToList();

            // حساب الحجوزات لجميع وحدات الكيان
            return bookings.Count(b => propertyUnitIds.Contains(b.UnitId));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في جلب عدد الحجوزات للكيان {PropertyId}", propertyId);
            return 0;
        }
    }

    /// <summary>
    /// التحقق من وجود الكيان في المفضلات
    /// Check if property is in favorites
    /// </summary>
    private async Task<bool> IsInFavorites(Guid propertyId, Guid? userId)
    {
        try
        {
            if (!userId.HasValue) return false;

            var favoriteRepo = _unitOfWork.Repository<Core.Entities.Favorite>();
            var favorites = await favoriteRepo.GetAllAsync();
            return favorites.Any(f =>
                f.UserId == userId.Value &&
                f.PropertyId == propertyId &&
                !f.IsDeleted);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في التحقق من المفضلات للكيان {PropertyId} والمستخدم {UserId}", propertyId, userId);
            return false;
        }
    }

    /// <summary>
    /// الحصول على صور الكيان
    /// Get property images
    /// </summary>
    private async Task<List<PropertyImageDto>> GetPropertyImages(Guid propertyId)
    {
        try
        {
            var imageRepo = _unitOfWork.Repository<Core.Entities.PropertyImage>();
            var images = await imageRepo.GetAllAsync();

            var propertyImages = images
                .Where(img => img.PropertyId.HasValue && img.PropertyId.Value == propertyId && !img.IsDeleted)
                .OrderBy(img => img.DisplayOrder)
                .ThenBy(img => img.CreatedAt)
                .ToList();

            var dtos = propertyImages.Select(img => new PropertyImageDto
            {
                Id = img.Id,
                PropertyId = img.PropertyId,
                UnitId = img.UnitId,
                SectionId = img.SectionId,
                PropertyInSectionId = img.PropertyInSectionId,
                UnitInSectionId = img.UnitInSectionId,
                CityName = img.CityName,
                Name = img.Name ?? string.Empty,
                Url = img.Url ?? string.Empty,
                SizeBytes = img.SizeBytes,
                Type = img.Type ?? string.Empty,
                Category = img.Category,
                Caption = img.Caption ?? string.Empty,
                AltText = img.AltText ?? string.Empty,
                Tags = img.Tags ?? string.Empty,
                Sizes = img.Sizes ?? string.Empty,
                IsMain = img.IsMain || img.IsMainImage,
                DisplayOrder = img.DisplayOrder != 0 ? img.DisplayOrder : img.SortOrder,
                UploadedAt = img.UploadedAt,
                Status = img.Status,
                Is360 = img.Is360,
                AssociationType = img.UnitId.HasValue ? "Unit" : "Property"
            }).ToList();

            return dtos;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في جلب صور الكيان {PropertyId}", propertyId);
            return new List<PropertyImageDto>();
        }
    }

    /// <summary>
    /// الحصول على وسائل الراحة
    /// Get property amenities
    /// </summary>
    private async Task<List<PropertyAmenityDto>> GetPropertyAmenities(Guid propertyId)
    {
        try
        {
            var amenities = await _amenityRepository.GetAmenitiesByPropertyAsync(propertyId, CancellationToken.None);

            var amenityDtos = amenities?.Select(amenity => new PropertyAmenityDto
            {
                Id = amenity.Id,
                AmenityId = amenity.PropertyTypeAmenity.Amenity.Id,
                Name = amenity.PropertyTypeAmenity.Amenity.Name ?? string.Empty,
                Description = amenity.PropertyTypeAmenity.Amenity.Description ?? string.Empty,
                IconUrl = string.Empty,
                Category = amenity.PropertyTypeAmenity.Amenity.Name ?? string.Empty,
                Icon = amenity.PropertyTypeAmenity.Amenity.Icon,
                IsAvailable = amenity.IsAvailable,
                ExtraCost = amenity.ExtraCost
            }).ToList() ?? new List<PropertyAmenityDto>();

            _logger.LogInformation("تم جلب {Count} مرفق للكيان {PropertyId}", amenityDtos.Count, propertyId);

            return amenityDtos;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في جلب وسائل الراحة للكيان {PropertyId}", propertyId);
            return new List<PropertyAmenityDto>();
        }
    }

    /// <summary>
    /// الحصول على خدمات الكيان
    /// Get property services
    /// </summary>
    private async Task<List<PropertyServiceDto>> GetPropertyServices(Guid propertyId)
    {
        try
        {
            var services = await _propertyServiceRepository.GetPropertyServicesAsync(propertyId, CancellationToken.None);

            var serviceDtos = services?.Select(service => new PropertyServiceDto
            {
                Id = service.Id,
                Name = service.Name ?? string.Empty,
                Price = service.Price,
                Currency = service.Price.Currency ?? "YER",
                PricingModel = service.PricingModel.ToString() ?? string.Empty,
                Description = service.Description ?? string.Empty,
                Icon = service.Icon ?? string.Empty
            }).ToList() ?? new List<PropertyServiceDto>();

            _logger.LogInformation("تم جلب {Count} خدمة للكيان {PropertyId}", serviceDtos.Count, propertyId);

            return serviceDtos;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في جلب خدمات الكيان {PropertyId}", propertyId);
            return new List<PropertyServiceDto>();
        }
    }

    /// <summary>
    /// الحصول على سياسات الكيان من قاعدة البيانات
    /// Get property policies from repository
    /// </summary>
    private async Task<List<PropertyPolicyDto>> GetPropertyPolicies(Guid propertyId)
    {
        try
        {
            var policies = await _propertyPolicyRepository.GetByPropertyIdAsync(propertyId, CancellationToken.None);

            return policies.Select(policy => new PropertyPolicyDto
            {
                Id = policy.Id,
                PolicyType = policy.Type.ToString(),
                PolicyContent = policy.Description ?? string.Empty,
                IsActive = policy.IsActive,
                Type = policy.Type.ToString(),
                Description = policy.Description ?? string.Empty,
                Rules = ParseRules(policy.Rules)
            }).ToList();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في جلب سياسات الكيان {PropertyId}", propertyId);
            return new List<PropertyPolicyDto>();
        }
    }

    private Dictionary<string, object> ParseRules(string rulesJson)
    {
        return JsonHelper.SafeDeserializeDictionary(rulesJson);
    }

    /// <summary>
    /// الحصول على وحدات الكيان مع صورها
    /// Get property units with their images
    /// </summary>
    private async Task<List<UnitDetailsDto>> GetPropertyUnits(Guid propertyId)
    {
        try
        {
            var unitRepo = _unitOfWork.Repository<Core.Entities.Unit>();
            var units = await unitRepo.GetAllAsync();

            var propertyUnits = units
                .Where(u => u.PropertyId == propertyId && !u.IsDeleted)
                .OrderBy(u => u.Name)
                .ToList();

            var unitDtos = new List<UnitDetailsDto>();

            foreach (var unit in propertyUnits)
            {
                var unitImages = await GetUnitImages(unit.Id);

                var unitDto = new UnitDetailsDto
                {
                    Id = unit.Id,
                    PropertyId = unit.PropertyId,
                    Name = unit.Name ?? string.Empty,
                    UnitTypeId = unit.UnitTypeId,
                    UnitTypeName = unit.UnitType?.Name ?? string.Empty,
                    PricingMethod = unit.PricingMethod.ToString(),
                    Images = unitImages,
                    CustomFeatures = unit.CustomFeatures ?? string.Empty,
                    MaxCapacity = unit.MaxCapacity,
                    ViewCount = unit.ViewCount,
                    BookingCount = unit.BookingCount,
                };

                unitDtos.Add(unitDto);
            }

            _logger.LogInformation("تم جلب {Count} وحدة للكيان {PropertyId}", unitDtos.Count, propertyId);
            return unitDtos;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في جلب وحدات الكيان {PropertyId}", propertyId);
            return new List<UnitDetailsDto>();
        }
    }

    /// <summary>
    /// الحصول على صور الوحدة
    /// Get unit images
    /// </summary>
    private async Task<List<UnitImageDto>> GetUnitImages(Guid unitId)
    {
        try
        {
            var imageRepo = _unitOfWork.Repository<Core.Entities.PropertyImage>();
            var images = await imageRepo.GetAllAsync();

            var unitImages = images
                .Where(img => img.UnitId.HasValue && img.UnitId.Value == unitId && !img.IsDeleted)
                .OrderBy(img => img.DisplayOrder)
                .ThenBy(img => img.CreatedAt)
                .ToList();

            var dtos = unitImages.Select(img => new UnitImageDto
            {
                Id = img.Id,
                Url = img.Url ?? string.Empty,
                Caption = img.Caption ?? string.Empty,
                IsMain = img.IsMain || img.IsMainImage,
                DisplayOrder = img.DisplayOrder != 0 ? img.DisplayOrder : img.SortOrder,
                Is360 = img.Is360,
            }).ToList();

            return dtos;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في جلب صور الوحدة {UnitId}", unitId);
            return new List<UnitImageDto>();
        }
    }
}