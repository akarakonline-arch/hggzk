// lib/features/admin_reviews/domain/usecases/get_review_responses_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:hggzkportal/core/error/failures.dart';
import 'package:hggzkportal/core/usecases/usecase.dart';
import '../entities/review_response.dart';
import '../repositories/reviews_repository.dart';

class GetReviewResponsesUseCase implements UseCase<List<ReviewResponse>, String> {
  final ReviewsRepository repository;
  
  GetReviewResponsesUseCase(this.repository);
  
  @override
  Future<Either<Failure, List<ReviewResponse>>> call(String reviewId) {
    return repository.getReviewResponses(reviewId);
  }
}