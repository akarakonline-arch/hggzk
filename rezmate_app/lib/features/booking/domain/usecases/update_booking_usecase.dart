import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/booking_repository.dart';

class UpdateBookingUseCase implements UseCase<bool, UpdateBookingParams> {
  final BookingRepository repository;

  UpdateBookingUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(UpdateBookingParams params) async {
    return await repository.updateBooking(
      bookingId: params.bookingId,
      checkIn: params.checkIn,
      checkOut: params.checkOut,
      guestsCount: params.guestsCount,
      services: params.services,
    );
  }
}

class UpdateBookingParams {
  final String bookingId;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? guestsCount;
  final List<Map<String, dynamic>>? services;

  UpdateBookingParams({
    required this.bookingId,
    this.checkIn,
    this.checkOut,
    this.guestsCount,
    this.services,
  });
}
