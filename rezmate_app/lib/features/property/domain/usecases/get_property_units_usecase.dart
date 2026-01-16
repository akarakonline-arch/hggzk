import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/unit.dart' as entity;
import '../repositories/property_repository.dart';

class GetPropertyUnitsUseCase implements UseCase<List<entity.Unit>, GetPropertyUnitsParams> {
  final PropertyRepository repository;

  GetPropertyUnitsUseCase({required this.repository});

  @override
  Future<Either<Failure, List<entity.Unit>>> call(GetPropertyUnitsParams params) async {
    return await repository.getPropertyUnits(
      propertyId: params.propertyId,
      checkInDate: params.checkInDate,
      checkOutDate: params.checkOutDate,
      guestsCount: params.guestsCount,
      adults: params.adults,
      children: params.children,
      unitTypeId: params.unitTypeId,
      currency: params.currency,
    );
  }
}

class GetPropertyUnitsParams extends Equatable {
  final String propertyId;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final int guestsCount;
  final int? adults;
  final int? children;
  final String? unitTypeId;
  final String? currency;

  const GetPropertyUnitsParams({
    required this.propertyId,
    this.checkInDate,
    this.checkOutDate,
    required this.guestsCount,
    this.adults,
    this.children,
    this.unitTypeId,
    this.currency,
  });

  @override
  List<Object?> get props => [propertyId, checkInDate, checkOutDate, guestsCount, adults, children, unitTypeId, currency];
}