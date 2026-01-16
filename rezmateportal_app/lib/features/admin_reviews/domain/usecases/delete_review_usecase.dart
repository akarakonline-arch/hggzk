// lib/features/admin_reviews/domain/usecases/delete_review_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:rezmateportal/core/error/failures.dart';
import 'package:rezmateportal/core/usecases/usecase.dart';
import '../repositories/reviews_repository.dart';

class DeleteReviewUseCase implements UseCase<bool, String> {
  final ReviewsRepository repository;

  DeleteReviewUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(String reviewId) {
    return repository.deleteReview(reviewId);
  }
}
