using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Reviews.Commands.Review;

/// <summary>
/// أمر لتعطيل التقييم
/// Command to disable a review
/// </summary>
public class DisableReviewCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف التقييم
    /// Review ID
    /// </summary>
    public Guid ReviewId { get; set; }
}
