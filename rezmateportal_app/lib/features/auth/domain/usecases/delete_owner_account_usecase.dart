import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class DeleteOwnerAccountUseCase
    implements UseCase<void, DeleteOwnerAccountParams> {
  final AuthRepository repository;

  DeleteOwnerAccountUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteOwnerAccountParams params) async {
    return await repository.deleteOwnerAccount(
      password: params.password,
      reason: params.reason,
    );
  }
}

class DeleteOwnerAccountParams extends Equatable {
  final String password;
  final String? reason;

  const DeleteOwnerAccountParams({
    required this.password,
    this.reason,
  });

  @override
  List<Object?> get props => [password, reason];
}
