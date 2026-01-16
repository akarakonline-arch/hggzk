using System;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Services.Commands.RemoveServices
{
    /// <summary>
    /// أمر لإزالة خدمة من الحجز
    /// Command to remove a service from a booking
    /// </summary>
    public class RemoveServiceFromBookingCommand : IRequest<ResultDto<bool>>
    {
        /// <summary>
        /// معرف الحجز
        /// </summary>
        public Guid BookingId { get; set; }

        /// <summary>
        /// معرف الخدمة
        /// </summary>
        public Guid ServiceId { get; set; }
    }
}
