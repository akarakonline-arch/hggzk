import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class ResendEmailVerificationUseCase
    implements UseCase<int?, ResendEmailVerificationParams> {
  final AuthRepository repository;

  ResendEmailVerificationUseCase(this.repository);

  @override
  Future<Either<Failure, int?>> call(ResendEmailVerificationParams params) {
    return repository.resendEmailVerification(
      userId: params.userId,
      email: params.email,
    );
  }
}

class ResendEmailVerificationParams {
  final String userId;
  final String email;

  ResendEmailVerificationParams({
    required this.userId,
    required this.email,
  });
}
