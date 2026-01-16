// lib/features/admin_properties/domain/repositories/property_types_repository.dart

import 'package:dartz/dartz.dart';
import 'package:hggzkportal/core/error/failures.dart';
import 'package:hggzkportal/core/models/paginated_result.dart';
import '../entities/property_type.dart';

abstract class PropertyTypesRepository {
  Future<Either<Failure, PaginatedResult<PropertyType>>> getAllPropertyTypes({
    int? pageNumber,
    int? pageSize,
  });
  Future<Either<Failure, PropertyType>> getPropertyTypeById(String propertyTypeId);
  Future<Either<Failure, String>> createPropertyType(Map<String, dynamic> data);
  Future<Either<Failure, bool>> updatePropertyType(String propertyTypeId, Map<String, dynamic> data);
  Future<Either<Failure, bool>> deletePropertyType(String propertyTypeId);
}