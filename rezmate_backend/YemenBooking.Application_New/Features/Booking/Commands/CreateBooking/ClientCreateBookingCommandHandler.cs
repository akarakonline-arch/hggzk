using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Bookings;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Enums;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Application.Features.Bookings.Commands.CreateBooking;

namespace YemenBooking.Application.Features.Bookings.Commands.CreateBooking;

/// <summary>
/// معالج أمر إنشاء حجز جديد للعميل
/// Handler for client create booking command
/// </summary>
public class ClientCreateBookingCommandHandler : IRequestHandler<CreateBookingCommand, ResultDto<CreateBookingResponse>>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<CreateBookingCommandHandler> _logger;
    private readonly IBookingRepository _bookingRepository;
    private readonly IUnitRepository _unitRepository;
    private readonly IDailyUnitScheduleRepository _scheduleRepository;
    private readonly IDailyUnitScheduleService _scheduleService;
    private readonly IMediator _mediator;
    private readonly IUnitIndexingService _indexingService;
    private readonly ICurrentUserService _currentUserService;

    public ClientCreateBookingCommandHandler(
        IUnitOfWork unitOfWork,
        ILogger<CreateBookingCommandHandler> logger,
        IBookingRepository bookingRepository,
        IUnitRepository unitRepository,
        IDailyUnitScheduleRepository scheduleRepository,
        IDailyUnitScheduleService scheduleService,
        IMediator mediator,
    IUnitIndexingService indexingService,
        ICurrentUserService currentUserService)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
        _bookingRepository = bookingRepository;
        _unitRepository = unitRepository;
        _scheduleRepository = scheduleRepository;
        _scheduleService = scheduleService;
        _mediator = mediator;
        _indexingService = indexingService;
        _currentUserService = currentUserService;
    }

    /// <summary>
    /// معالجة أمر إنشاء حجز جديد
    /// Handle create booking command
    /// </summary>
    /// <param name="request">الطلب</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة العملية</returns>
    public async Task<ResultDto<CreateBookingResponse>> Handle(CreateBookingCommand request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء إنشاء حجز جديد للمستخدم {UserId} في الوحدة {UnitId}", request.UserId, request.UnitId);

            // Normalize incoming dates from user-local to UTC
            request.CheckIn = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.CheckIn);
            request.CheckOut = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.CheckOut);

            // التحقق من صحة البيانات الأساسية
            var validationError = await ValidateRequestAsync(request);
            if (validationError != null)
            {
                return ResultDto<CreateBookingResponse>.Failure(validationError.Message);
            }

            // التحقق من وجود المستخدم
            var userRepo = _unitOfWork.Repository<Core.Entities.User>();
            var user = await userRepo.GetByIdAsync(request.UserId);
            if (user == null)
            {
                _logger.LogWarning("المستخدم غير موجود {UserId}", request.UserId);
                return new ResultDto<CreateBookingResponse>
                {
                    Success = false,
                    Message = "المستخدم غير موجود"
                };
            }

            // التحقق من وجود الوحدة
            var unitRepo = _unitOfWork.Repository<Core.Entities.Unit>();
            var unit = await unitRepo.GetByIdAsync(request.UnitId);
            if (unit == null)
            {
                _logger.LogWarning("الوحدة غير موجودة {UnitId}", request.UnitId);
                    return new ResultDto<CreateBookingResponse>
                    {
                        Success = false,
                        Message = "الوحدة غير موجودة"
                    };
            }

            // التحقق من توفر الوحدة في التواريخ المطلوبة
            var availabilityError = await CheckAvailability(request.UnitId, request.CheckIn, request.CheckOut);
            if (availabilityError != null)
            {
                return new ResultDto<CreateBookingResponse>
                {
                    Success = false,
                    Message = availabilityError.Message
                };
            }

            // حساب السعر الإجمالي
            var totalPrice = await CalculateTotalPrice(unit, request);

            // إنشاء الحجز
            var booking = new Core.Entities.Booking
            {
                Id = Guid.NewGuid(),
                UserId = request.UserId,
                UnitId = request.UnitId,
                CheckIn = request.CheckIn,
                CheckOut = request.CheckOut,
                GuestsCount = request.GuestsCount,
                Status = BookingStatus.Pending,
                BookingSource = request.BookingSource,
                TotalPrice = totalPrice,
                BookedAt = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            // إضافة الحجز إلى قاعدة البيانات
            var bookingRepo = _unitOfWork.Repository<Core.Entities.Booking>();
            await bookingRepo.AddAsync(booking);
            
            // حفظ الخدمات الإضافية المطلوبة (إن وجدت)
            if (request.Services != null && request.Services.Any())
            {
                var propertyServiceRepo = _unitOfWork.Repository<Core.Entities.PropertyService>();
                var allPropertyServices = await propertyServiceRepo.GetAllAsync();
                var bookingServiceRepo = _unitOfWork.Repository<Core.Entities.BookingService>();
                
                foreach (var serviceRequest in request.Services)
                {
                    var propertyService = allPropertyServices.FirstOrDefault(ps => ps.Id == serviceRequest.ServiceId);
                    if (propertyService != null)
                    {
                        var bookingService = new Core.Entities.BookingService
                        {
                            Id = Guid.NewGuid(),
                            BookingId = booking.Id,
                            ServiceId = propertyService.Id,
                            Quantity = serviceRequest.Quantity,
                            TotalPrice = new Money(propertyService.Price.Amount * serviceRequest.Quantity, propertyService.Price.Currency ?? "YER"),
                            CreatedAt = DateTime.UtcNow,
                            UpdatedAt = DateTime.UtcNow,
                            IsActive = true
                        };
                        
                        await bookingServiceRepo.AddAsync(bookingService);
                    }
                }
            }

            // تحديث جدول الإتاحة اليومي
            await _scheduleService.SetAvailabilityForPeriodAsync(
                booking.UnitId,
                booking.CheckIn,
                booking.CheckOut,
                "Booked",
                "Customer Booking",
                $"Block for booking {booking.Id}",
                booking.Id,
                overwriteExisting: true,
                createdBy: _currentUserService.Username
            );

            // حفظ كل التغييرات في معاملة واحدة
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            // إنشاء رقم الحجز
            var bookingNumber = GenerateBookingNumber(booking.Id);


            var response = new CreateBookingResponse
            {
                BookingId = booking.Id,
                BookingNumber = bookingNumber,
                TotalPrice = booking.TotalPrice,
                Status = booking.Status,
                Message = "تم إنشاء الحجز بنجاح"
            };

            // تحديث مباشر لفهرس الإتاحة
            try
            {
                if (booking != null)
                {
                    var from = DateTime.UtcNow.Date;
                    var to = from.AddMonths(6);
                    var periods = await _scheduleRepository.GetAvailableDaysAsync(booking.UnitId, from, to);
                    var availableRanges = periods
                        .Select(p => (p.Date, p.Date.AddDays(1)))
                        .ToList();

                    await _indexingService.OnAvailabilityChangedAsync(booking.UnitId, cancellationToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "تعذرت الفهرسة المباشرة للإتاحة بعد إنشاء الحجز {BookingId}", booking.Id);
            }

            _logger.LogInformation("تم إنشاء الحجز بنجاح {BookingId} للمستخدم {UserId}", booking.Id, request.UserId);

            return new ResultDto<CreateBookingResponse>
            {
                Success = true,
                Data = response
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء إنشاء الحجز للمستخدم {UserId}", request.UserId);
            return new ResultDto<CreateBookingResponse>
            {
                Success = false,
                Message = $"حدث خطأ أثناء إنشاء الحجز: {ex.Message}"
            };
        }
    }

    /// <summary>
    /// التحقق من صحة طلب الحجز
    /// Validate booking request
    /// </summary>
    private async Task<CreateBookingResponse?> ValidateRequestAsync(CreateBookingCommand request)
    {
        if (request.UserId == Guid.Empty)
        {
            return new CreateBookingResponse
            {
                BookingId = Guid.Empty,
                Message = "معرف المستخدم مطلوب"
            };
        }

        if (request.UnitId == Guid.Empty)
        {
            return new CreateBookingResponse
            {
                BookingId = Guid.Empty,
                Message = "معرف الوحدة مطلوب"
            };
        }

        if (request.CheckIn >= request.CheckOut)
        {
            return new CreateBookingResponse
            {
                BookingId = Guid.Empty,
                Message = "تاريخ الوصول يجب أن يكون قبل تاريخ المغادرة"
            };
        }

        var userToday = (await _currentUserService.ConvertFromUtcToUserLocalAsync(DateTime.UtcNow)).Date;
        var checkInLocal = (await _currentUserService.ConvertFromUtcToUserLocalAsync(request.CheckIn)).Date;
        if (checkInLocal < userToday)
        {
            return new CreateBookingResponse
            {
                BookingId = Guid.Empty,
                Message = "تاريخ الوصول لا يمكن أن يكون في الماضي"
            };
        }

        if (request.GuestsCount <= 0)
        {
            return new CreateBookingResponse
            {
                BookingId = Guid.Empty,
                Message = "عدد الضيوف يجب أن يكون أكبر من صفر"
            };
        }

        return null;
    }

    /// <summary>
    /// التحقق من توفر الوحدة
    /// Check unit availability
    /// </summary>
    private async Task<CreateBookingResponse?> CheckAvailability(Guid unitId, DateTime checkIn, DateTime checkOut)
    {
        var bookingRepo = _unitOfWork.Repository<Core.Entities.Booking>();
        var existingBookings = await bookingRepo.GetAllAsync();

        var conflictingBookings = existingBookings.Where(b =>
            b.UnitId == unitId &&
            b.Status != BookingStatus.Cancelled &&
            !(checkOut <= b.CheckIn || checkIn >= b.CheckOut)
        ).ToList();

        if (conflictingBookings.Any())
        {
            return new CreateBookingResponse
            {
                BookingId = Guid.Empty,
                Message = "الوحدة غير متاحة في التواريخ المطلوبة"
            };
        }

        return null;
    }

    /// <summary>
    /// حساب السعر الإجمالي من جداول الإتاحة اليومية
    /// Calculate total price from daily schedules
    /// </summary>
    private async Task<Money> CalculateTotalPrice(Core.Entities.Unit unit, CreateBookingCommand request)
    {
        try
        {
            // حساب السعر الإجمالي من جداول الأيام (DailyUnitSchedule)
            var schedules = await _scheduleRepository.GetByUnitAndDateRangeAsync(
                request.UnitId,
                request.CheckIn.Date,
                request.CheckOut.Date.AddDays(-1));
            
            var priceAmount = schedules
                .Where(s => s.PriceAmount.HasValue)
                .Sum(s => s.PriceAmount.Value);
            
            // إذا لم تكن هناك أسعار محددة في الجداول، نحتاج للعودة إلى سعر افتراضي أو رفع خطأ
            if (priceAmount == 0)
            {
                var nights = (request.CheckOut - request.CheckIn).Days;
                _logger.LogWarning("لم يتم العثور على أسعار في جداول الإتاحة للوحدة {UnitId}. قد يكون هناك خلل في إعداد الأسعار", unit.Id);
                // يمكن رفع exception هنا أو استخدام قيمة افتراضية مؤقتة
                priceAmount = 100m * nights; // قيمة احتياطية
            }
            
            // التأكد من عدم تجاوز المنازل العشرية للسعر عن رقمين
            var roundedPrice = decimal.Round(priceAmount, 2);

            // إضافة تكلفة الخدمات الإضافية (إذا وجدت)
            decimal servicesTotal = 0m;
            if (request.Services != null && request.Services.Any())
            {
                var propertyServiceRepo = _unitOfWork.Repository<Core.Entities.PropertyService>();
                var allPropertyServices = await propertyServiceRepo.GetAllAsync();
                
                foreach (var serviceRequest in request.Services)
                {
                    var propertyService = allPropertyServices.FirstOrDefault(ps => ps.Id == serviceRequest.ServiceId);
                    if (propertyService != null)
                    {
                        var serviceTotalAmount = propertyService.Price.Amount * serviceRequest.Quantity;
                        servicesTotal += serviceTotalAmount;
                    }
                }
            }

            var finalTotalAmount = roundedPrice + servicesTotal;
            
            // الحصول على العملة من العقار
            var propertyRepo = _unitOfWork.Repository<Core.Entities.Property>();
            var property = await propertyRepo.GetByIdAsync(unit.PropertyId);
            var currency = property?.Currency ?? "YER";
            
            _logger.LogInformation("تم حساب السعر الإجمالي للحجز: {TotalAmount} {Currency} (إقامة: {BaseAmount}, خدمات: {ServicesTotal})",
                finalTotalAmount, currency, roundedPrice, servicesTotal);

            return new Money(finalTotalAmount, currency);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في حساب السعر للوحدة {UnitId}. استخدام سعر افتراضي احتياطي", unit.Id);
            
            // في حالة الخطأ، استخدم سعر افتراضي احتياطي
            var nights = (request.CheckOut - request.CheckIn).Days;
            var fallbackPrice = 100m * nights;
            
            _logger.LogError("استخدام سعر افتراضي احتياطي: {FallbackPrice} YER للوحدة {UnitId}", fallbackPrice, unit.Id);
            return new Money(fallbackPrice, "YER");
        }
    }

    /// <summary>
    /// إنشاء رقم الحجز
    /// Generate booking number
    /// </summary>
    private string GenerateBookingNumber(Guid bookingId)
    {
        // إنشاء رقم حجز فريد باستخدام التاريخ وجزء من معرف الحجز
        var datePrefix = DateTime.UtcNow.ToString("yyyyMMdd");
        var idSuffix = bookingId.ToString("N")[..8].ToUpper();
        return $"BK{datePrefix}{idSuffix}";
    }
}