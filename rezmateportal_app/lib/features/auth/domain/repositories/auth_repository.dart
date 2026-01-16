import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/auth_response.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthResponse>> login({
    required String emailOrPhone,
    required String password,
    required bool rememberMe,
  });

  Future<Either<Failure, AuthResponse>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  });

  /// تسجيل مالك عقار جديد مع إنشاء عقار مرتبط
  Future<Either<Failure, AuthResponse>> registerOwnerWithProperty({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String propertyTypeId,
    required String propertyName,
    required String city,
    required String address,
    double? latitude,
    double? longitude,
    int starRating = 3,
    String? description,
    String? currency,
  });

  Future<Either<Failure, void>> logout();

  Future<Either<Failure, void>> resetPassword({
    required String emailOrPhone,
  });

  Future<Either<Failure, AuthResponse>> refreshToken({
    required String refreshToken,
  });

  Future<Either<Failure, User>> getCurrentUser();

  Future<Either<Failure, void>> updateProfile({
    required String name,
    String? email,
    String? phone,
    // Owner property fields
    String? propertyId,
    String? propertyName,
    String? propertyAddress,
    String? propertyCity,
    String? propertyShortDescription,
    String? propertyDescription,
    String? propertyCurrency,
    int? propertyStarRating,
    double? propertyLatitude,
    double? propertyLongitude,
  });

  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  });

  Future<Either<Failure, void>> deleteOwnerAccount({
    required String password,
    String? reason,
  });

  Future<Either<Failure, bool>> checkAuthStatus();

  Future<void> saveAuthData(AuthResponse authResponse);

  Future<void> clearAuthData();

  Future<String?> getAccessToken();

  Future<String?> getRefreshToken();

  Future<Either<Failure, User>> uploadProfileImage({
    required String imagePath,
  });

  // Email verification
  Future<Either<Failure, bool>> verifyEmail({
    required String userId,
    required String code,
  });
  Future<Either<Failure, int?>> resendEmailVerification({
    required String userId,
    required String email,
  });
}
