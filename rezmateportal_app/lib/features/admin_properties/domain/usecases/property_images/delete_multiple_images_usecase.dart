// lib/features/admin_properties/domain/usecases/property_images/delete_multiple_images_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:rezmateportal/core/error/failures.dart';
import 'package:rezmateportal/core/usecases/usecase.dart';
import '../../repositories/property_images_repository.dart';

class DeleteMultipleImagesUseCase implements UseCase<bool, List<String>> {
  final PropertyImagesRepository repository;

  DeleteMultipleImagesUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(List<String> imageIds) async {
    return await repository.deleteMultipleImages(imageIds);
  }
}
