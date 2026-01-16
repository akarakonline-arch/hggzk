import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_response.dart';
import '../repositories/auth_repository.dart';

class RegisterOwnerUseCase
    implements UseCase<AuthResponse, RegisterOwnerParams> {
  final AuthRepository repository;

  RegisterOwnerUseCase(this.repository);

  @override
  Future<Either<Failure, AuthResponse>> call(RegisterOwnerParams params) async {
    return await repository.registerOwnerWithProperty(
      name: params.name,
      email: params.email,
      phone: params.phone,
      password: params.password,
      propertyTypeId: params.propertyTypeId,
      propertyName: params.propertyName,
      city: params.city,
      address: params.address,
      latitude: params.latitude,
      longitude: params.longitude,
      starRating: params.starRating,
      description: params.description,
      currency: params.currency,
    );
  }
}

class RegisterOwnerParams extends Equatable {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String propertyTypeId;
  final String propertyName;
  final String city;
  final String address;
  final double? latitude;
  final double? longitude;
  final int starRating;
  final String? description;
  final String? currency;

  const RegisterOwnerParams({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.propertyTypeId,
    required this.propertyName,
    required this.city,
    required this.address,
    this.latitude,
    this.longitude,
    this.starRating = 3,
    this.description,
    this.currency,
  });

  @override
  List<Object?> get props => [
        name,
        email,
        phone,
        password,
        propertyTypeId,
        propertyName,
        city,
        address,
        latitude,
        longitude,
        starRating,
        description,
        currency,
      ];
}
