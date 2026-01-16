// lib/features/admin_units/domain/usecases/unit_images/delete_unit_image_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:hggzkportal/core/error/failures.dart';
import 'package:hggzkportal/core/usecases/usecase.dart';
import '../../repositories/unit_images_repository.dart';

class DeleteUnitImageUseCase implements UseCase<bool, String> {
  final UnitImagesRepository repository;

  DeleteUnitImageUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(String imageId) async {
    return await repository.deleteImage(imageId);
  }
}