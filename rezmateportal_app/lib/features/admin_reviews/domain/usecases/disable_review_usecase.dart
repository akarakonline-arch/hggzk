// lib/features/admin_reviews/domain/usecases/disable_review_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:rezmateportal/core/error/failures.dart';
import 'package:rezmateportal/core/usecases/usecase.dart';
import '../repositories/reviews_repository.dart';

class DisableReviewUseCase implements UseCase<bool, String> {
  final ReviewsRepository repository;

  DisableReviewUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(String reviewId) {
    return repository.disableReview(reviewId);
  }
}
