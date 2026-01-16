import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class DeleteAccountUseCase implements UseCase<void, DeleteAccountParams> {
  final AuthRepository repository;

  DeleteAccountUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteAccountParams params) async {
    return await repository.deleteAccount(
      password: params.password,
      reason: params.reason,
    );
  }
}

class DeleteAccountParams extends Equatable {
  final String password;
  final String? reason;

  const DeleteAccountParams({
    required this.password,
    this.reason,
  });

  @override
  List<Object?> get props => [password, reason];
}
