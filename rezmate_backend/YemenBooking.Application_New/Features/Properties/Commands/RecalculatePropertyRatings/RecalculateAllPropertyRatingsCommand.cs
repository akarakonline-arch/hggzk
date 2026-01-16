using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Properties.Commands.RecalculatePropertyRatings
{
    /// <summary>
    /// أمر لإعادة احتساب متوسط تقييم جميع العقارات من التقييمات الحالية
    /// </summary>
    public class RecalculateAllPropertyRatingsCommand : IRequest<ResultDto<int>>
    {
    }
}
