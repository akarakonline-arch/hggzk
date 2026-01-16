import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/property_availability.dart';
import '../repositories/property_repository.dart';

class CheckPropertyAvailabilityUseCase
    implements UseCase<PropertyAvailability, CheckPropertyAvailabilityParams> {
  final PropertyRepository repository;

  CheckPropertyAvailabilityUseCase({required this.repository});

  @override
  Future<Either<Failure, PropertyAvailability>> call(
    CheckPropertyAvailabilityParams params,
  ) async {
    return repository.checkPropertyAvailability(
      propertyId: params.propertyId,
      checkInDate: params.checkInDate,
      checkOutDate: params.checkOutDate,
      guestsCount: params.guestsCount,
    );
  }
}

class CheckPropertyAvailabilityParams extends Equatable {
  final String propertyId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guestsCount;

  const CheckPropertyAvailabilityParams({
    required this.propertyId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guestsCount,
  });

  @override
  List<Object?> get props => [propertyId, checkInDate, checkOutDate, guestsCount];
}
