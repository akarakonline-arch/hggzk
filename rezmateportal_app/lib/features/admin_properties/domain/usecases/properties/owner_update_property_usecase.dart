// lib/features/admin_properties/domain/usecases/properties/owner_update_property_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:rezmateportal/core/error/failures.dart';
import 'package:rezmateportal/core/usecases/usecase.dart';
import '../../repositories/properties_repository.dart';

class OwnerUpdatePropertyParams {
  final String propertyId;
  final Map<String, dynamic> data;

  OwnerUpdatePropertyParams({
    required this.propertyId,
    required this.data,
  });
}

class OwnerUpdatePropertyUseCase
    implements UseCase<bool, OwnerUpdatePropertyParams> {
  final PropertiesRepository repository;

  OwnerUpdatePropertyUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(OwnerUpdatePropertyParams params) async {
    return await repository.updatePropertyAsOwner(
        params.propertyId, params.data);
  }
}
