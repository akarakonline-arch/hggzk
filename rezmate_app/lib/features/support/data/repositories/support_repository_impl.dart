import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../domain/entities/support_message.dart';
import '../../domain/repositories/support_repository.dart';
import '../models/support_message_model.dart';

class SupportRepositoryImpl implements SupportRepository {
  final ApiClient apiClient;

  SupportRepositoryImpl({required this.apiClient});

  @override
  Future<Either<Failure, Map<String, dynamic>>> sendSupportMessage(
    SupportMessage message,
  ) async {
    try {
      final model = SupportMessageModel(
        userName: message.userName,
        userEmail: message.userEmail,
        subject: message.subject,
        message: message.message,
        deviceType: message.deviceType,
        operatingSystem: message.operatingSystem,
        osVersion: message.osVersion,
        appVersion: message.appVersion,
      );

      final response = await apiClient.post(
        '/api/Client/Support/send',
        data: model.toJson(),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          if (data['data'] != null) {
            return Right(Map<String, dynamic>.from(data['data']));
          }
        }
        return const Right({});
      } else {
        return const Left(ServerFailure(
          'فشل إرسال رسالة الدعم',
        ));
      }
    } on ApiException catch (e) {
      return Left(ServerFailure.meta(
        message: e.message,
        code: e.statusCode?.toString(),
      ));
    } catch (e) {
      return Left(ServerFailure(
        'حدث خطأ غير متوقع: ${e.toString()}',
      ));
    }
  }
}
