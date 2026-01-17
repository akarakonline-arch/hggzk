import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/users_repository.dart';

class CreateUserUseCase implements UseCase<String, CreateUserParams> {
  final UsersRepository repository;

  CreateUserUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(CreateUserParams params) {
    return repository.createUser(
      name: params.name,
      email: params.email,
      password: params.password,
      phone: params.phone,
      profileImage: params.profileImage,
      roleName: params.roleName,
      emailConfirmed: params.emailConfirmed,
      phoneNumberConfirmed: params.phoneNumberConfirmed,
      walletAccounts: params.walletAccounts,
    );
  }
}

class CreateUserParams extends Equatable {
  final String name;
  final String email;
  final String password;
  final String phone;
  final String? profileImage;
  final String? roleName;
  final bool emailConfirmed;
  final bool phoneNumberConfirmed;
  final List<Map<String, dynamic>>? walletAccounts;

  const CreateUserParams({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    this.profileImage,
    this.roleName,
    this.emailConfirmed = false,
    this.phoneNumberConfirmed = false,
    this.walletAccounts,
  });

  @override
  List<Object?> get props => [
        name,
        email,
        password,
        phone,
        profileImage,
        roleName,
        emailConfirmed,
        phoneNumberConfirmed,
        walletAccounts,
      ];
}