import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/booking.dart';
import '../entities/booking_request.dart';
import '../entities/unit_availability.dart';

abstract class BookingRepository {
  Future<Either<Failure, Booking>> createBooking(BookingRequest request);
  
  Future<Either<Failure, Booking>> getBookingDetails({
    required String bookingId,
    required String userId,
  });
  
  Future<Either<Failure, bool>> cancelBooking({
    required String bookingId,
    required String userId,
    required String reason,
  });
  
  Future<Either<Failure, PaginatedResult<Booking>>> getUserBookings({
    required String userId,
    String? status,
    int pageNumber = 1,
    int pageSize = 10,
  });
  
  Future<Either<Failure, Map<String, dynamic>>> getUserBookingSummary({
    required String userId,
    int? year,
  });
  
  Future<Either<Failure, Booking>> addServicesToBooking({
    required String bookingId,
    required String serviceId,
    required int quantity,
  });
  
  Future<Either<Failure, UnitAvailability>> checkAvailability({
    required String unitId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int adultsCount,
    required int childrenCount,
    required int guestsCount,
    String? excludeBookingId,
  });

  Future<Either<Failure, bool>> updateBooking({
    required String bookingId,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guestsCount,
    List<Map<String, dynamic>>? services,
  });
}