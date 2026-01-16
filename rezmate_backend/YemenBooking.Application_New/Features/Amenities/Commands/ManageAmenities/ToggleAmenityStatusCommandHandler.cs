using System.Threading;
using System.Threading.Tasks;
using System.Linq;
using MediatR;
using YemenBooking.Application.Features.Amenities;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.Amenities.Commands.ManageAmenities
{
    public class ToggleAmenityStatusCommandHandler : IRequestHandler<ToggleAmenityStatusCommand, ResultDto<bool>>
    {
        private readonly IUnitOfWork _unitOfWork;
        private readonly ICurrentUserService _currentUserService;

        public ToggleAmenityStatusCommandHandler(IUnitOfWork unitOfWork, ICurrentUserService currentUserService)
        {
            _unitOfWork = unitOfWork;
            _currentUserService = currentUserService;
        }

        public async Task<ResultDto<bool>> Handle(ToggleAmenityStatusCommand request, CancellationToken cancellationToken)
        {
            var isAdmin = string.Equals(_currentUserService.Role, "Admin", System.StringComparison.OrdinalIgnoreCase)
                || string.Equals(_currentUserService.AccountRole, "Admin", System.StringComparison.OrdinalIgnoreCase)
                || (_currentUserService.UserRoles?.Any(r => string.Equals(r, "Admin", System.StringComparison.OrdinalIgnoreCase)) ?? false);
            if (!isAdmin)
                return ResultDto<bool>.Failed("غير مصرح لك بتغيير حالة المرفق");

            var repo = _unitOfWork.Repository<Amenity>();
            var amenity = await repo.GetByIdAsync(request.AmenityId, cancellationToken);
            if (amenity == null)
                return ResultDto<bool>.Failed("المرفق غير موجود");

            amenity.IsActive = !amenity.IsActive;
            await repo.UpdateAsync(amenity, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return ResultDto<bool>.Succeeded(true, amenity.IsActive ? "تم تفعيل المرفق" : "تم تعطيل المرفق");
        }
    }
}

