import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/unit_availability.dart';
import '../repositories/booking_repository.dart';

class CheckAvailabilityUseCase
    implements UseCase<UnitAvailability, CheckAvailabilityParams> {
  final BookingRepository repository;

  CheckAvailabilityUseCase(this.repository);

  @override
  Future<Either<Failure, UnitAvailability>> call(
    CheckAvailabilityParams params,
  ) async {
    return await repository.checkAvailability(
      unitId: params.unitId,
      checkIn: params.checkIn,
      checkOut: params.checkOut,
      adultsCount: params.adultsCount,
      childrenCount: params.childrenCount,
      guestsCount: params.guestsCount,
      excludeBookingId: params.excludeBookingId,
    );
  }
}

class CheckAvailabilityParams extends Equatable {
  final String unitId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adultsCount;
  final int childrenCount;
  final int guestsCount;
  final String? excludeBookingId;

  const CheckAvailabilityParams({
    required this.unitId,
    required this.checkIn,
    required this.checkOut,
    required this.adultsCount,
    required this.childrenCount,
    this.excludeBookingId,
  }) : guestsCount = adultsCount + childrenCount;

  @override
  List<Object?> get props => [unitId, checkIn, checkOut, adultsCount, childrenCount, guestsCount, excludeBookingId];
}