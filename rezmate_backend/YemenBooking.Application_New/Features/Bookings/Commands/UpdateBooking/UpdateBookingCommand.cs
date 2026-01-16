using MediatR;
using YemenBooking.Application.Common.Models;
using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Features.Bookings.Commands.UpdateBooking;

/// <summary>
/// أمر لتحديث بيانات الحجز
/// Command to update booking information
/// </summary>
public class UpdateBookingCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف الحجز
    /// BookingDto ID
    /// </summary>
    public Guid BookingId { get; set; }

    /// <summary>
    /// تاريخ الدخول المحدث
    /// Updated check-in date
    /// </summary>
    public DateTime? CheckIn { get; set; }

    /// <summary>
    /// تاريخ الخروج المحدث
    /// Updated check-out date
    /// </summary>
    public DateTime? CheckOut { get; set; }

    /// <summary>
    /// عدد الضيوف المحدث
    /// Updated number of guests
    /// </summary>
    public int? GuestsCount { get; set; }

    /// <summary>
    /// الخدمات المطلوبة بعد التعديل (قائمة كاملة بالحالة المطلوبة)
    /// Desired services after edit (full target state)
    /// </summary>
    public List<ServiceUpdateItem>? Services { get; set; }
}

/// <summary>
/// عنصر خدمة للتعديل
/// </summary>
public class ServiceUpdateItem
{
    /// <summary>
    /// معرف الخدمة
    /// </summary>
    public Guid ServiceId { get; set; }

    /// <summary>
    /// الكمية المطلوبة
    /// </summary>
    public int Quantity { get; set; }
}