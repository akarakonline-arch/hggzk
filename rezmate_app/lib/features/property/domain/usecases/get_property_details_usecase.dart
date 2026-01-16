import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/property_detail.dart';
import '../repositories/property_repository.dart';

class GetPropertyDetailsUseCase implements UseCase<PropertyDetail, GetPropertyDetailsParams> {
  final PropertyRepository repository;

  GetPropertyDetailsUseCase({required this.repository});

  @override
  Future<Either<Failure, PropertyDetail>> call(GetPropertyDetailsParams params) async {
    return await repository.getPropertyDetails(
      propertyId: params.propertyId,
      userId: params.userId,
      userRole: params.userRole,
    );
  }
}

class GetPropertyDetailsParams extends Equatable {
  final String propertyId;
  final String? userId;
  final String? userRole;

  const GetPropertyDetailsParams({
    required this.propertyId,
    this.userId,
    this.userRole,
  });

  @override
  List<Object?> get props => [propertyId, userId, userRole];
}