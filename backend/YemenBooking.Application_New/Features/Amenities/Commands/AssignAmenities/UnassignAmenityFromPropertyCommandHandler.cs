using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Amenities;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.SearchAndFilters.Services;

namespace YemenBooking.Application.Features.Amenities.Commands.AssignAmenities;

/// <summary>
/// معالج أمر إلغاء إسناد مرفق من عقار
/// </summary>
public class UnassignAmenityFromPropertyCommandHandler : IRequestHandler<UnassignAmenityFromPropertyCommand, ResultDto<bool>>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly ILogger<UnassignAmenityFromPropertyCommandHandler> _logger;
    private readonly IUnitIndexingService _indexingService;

    public UnassignAmenityFromPropertyCommandHandler(
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        ILogger<UnassignAmenityFromPropertyCommandHandler> logger,
    IUnitIndexingService indexingService)
    {
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _logger = logger;
        _indexingService = indexingService;
    }

    public async Task<ResultDto<bool>> Handle(UnassignAmenityFromPropertyCommand request, CancellationToken cancellationToken)
    {
        try
        {
            if (request.PropertyId == Guid.Empty || request.AmenityId == Guid.Empty)
                return ResultDto<bool>.Failed("بيانات غير صحيحة");

            var isAdmin = string.Equals(_currentUserService.Role, "Admin", StringComparison.OrdinalIgnoreCase)
                || string.Equals(_currentUserService.AccountRole, "Admin", StringComparison.OrdinalIgnoreCase)
                || (_currentUserService.UserRoles?.Any(r => string.Equals(r, "Admin", StringComparison.OrdinalIgnoreCase)) ?? false);
            if (!isAdmin)
            {
                var property = await _unitOfWork.Repository<Property>().GetByIdAsync(request.PropertyId, cancellationToken);
                if (property == null)
                    return ResultDto<bool>.Failed("الكيان غير موجود");

                var isOwnerAuthorized = property.OwnerId == _currentUserService.UserId;
                var isStaffAuthorized = _currentUserService.IsStaffInProperty(request.PropertyId);
                if (!(isOwnerAuthorized || isStaffAuthorized))
                    return ResultDto<bool>.Failed("ليس لديك صلاحية لإلغاء إسناد المرفق من هذا الكيان");
            }

            // Find PropertyTypeAmenity for this Amenity
            var ptaList = await _unitOfWork.Repository<PropertyTypeAmenity>()
                .FindAsync(x => x.AmenityId == request.AmenityId, cancellationToken);

            if (!ptaList.Any())
                return ResultDto<bool>.Failed("المرفق غير مرتبط بأي نوع");

            // Remove PropertyAmenity row for this property and matching PTA
            var propertyAmenityRepo = _unitOfWork.Repository<PropertyAmenity>();
            var toRemove = await propertyAmenityRepo
                .FindAsync(x => x.PropertyId == request.PropertyId && ptaList.Select(p => p.Id).Contains(x.PtaId), cancellationToken);

            if (!toRemove.Any())
                return ResultDto<bool>.Failed("لا يوجد إسناد لهذا المرفق على هذا العقار");

            foreach (var pa in toRemove)
            {
                await propertyAmenityRepo.DeleteAsync(pa, cancellationToken);
            }

            await _unitOfWork.SaveChangesAsync(cancellationToken);

            // تحديث فهرس العقار بعد حذف المرفق مع retry mechanism
            var indexingSuccess = false;
            var indexingAttempts = 0;
            const int maxIndexingAttempts = 3;
            
            while (!indexingSuccess && indexingAttempts < maxIndexingAttempts)
            {
                try
                {
                    indexingAttempts++;
                    await _indexingService.OnPropertyUpdatedAsync(request.PropertyId, cancellationToken);
                    indexingSuccess = true;
                    _logger.LogInformation("✅ تم تحديث فهرس العقار بعد حذف المرفق {PropertyId} (محاولة {Attempt}/{Max})", 
                        request.PropertyId, indexingAttempts, maxIndexingAttempts);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "⚠️ فشلت محاولة {Attempt}/{Max} لتحديث فهرس العقار بعد حذف المرفق {PropertyId}", 
                        indexingAttempts, maxIndexingAttempts, request.PropertyId);
                    
                    if (indexingAttempts < maxIndexingAttempts)
                    {
                        await Task.Delay(TimeSpan.FromSeconds(Math.Pow(2, indexingAttempts - 1)), cancellationToken);
                    }
                    else
                    {
                        _logger.LogCritical("❌ CRITICAL: فشل تحديث فهرس العقار بعد {Attempts} محاولات للعقار {PropertyId}. " +
                            "المرفق محذوف من DB لكن موجود في البحث! يجب تشغيل re-index يدوي.", 
                            maxIndexingAttempts, request.PropertyId);
                    }
                }
            }

            return ResultDto<bool>.Succeeded(true, "تم إلغاء إسناد المرفق بنجاح");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "فشل إلغاء إسناد المرفق من العقار {PropertyId} {AmenityId}", request.PropertyId, request.AmenityId);
            return ResultDto<bool>.Failed("حدث خطأ أثناء إلغاء الإسناد");
        }
    }
}

