import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class VerifyEmailUseCase implements UseCase<bool, VerifyEmailParams> {
  final AuthRepository repository;

  VerifyEmailUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(VerifyEmailParams params) {
    return repository.verifyEmail(
      userId: params.userId,
      code: params.code,
    );
  }
}

class VerifyEmailParams {
  final String userId;
  final String code;

  VerifyEmailParams({
    required this.userId,
    required this.code,
  });
}
