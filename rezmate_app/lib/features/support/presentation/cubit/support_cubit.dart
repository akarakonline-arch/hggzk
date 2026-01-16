import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import '../../domain/entities/support_message.dart';
import '../../domain/repositories/support_repository.dart';
import 'support_state.dart';

class SupportCubit extends Cubit<SupportState> {
  final SupportRepository repository;

  SupportCubit({required this.repository}) : super(SupportInitial());

  Future<void> sendSupportMessage({
    required String userName,
    required String userEmail,
    required String subject,
    required String message,
  }) async {
    emit(SupportLoading());

    try {
      String? deviceType;
      String? operatingSystem;
      String? osVersion;
      String? appVersion;

      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceType = androidInfo.model;
        operatingSystem = 'Android';
        osVersion = androidInfo.version.release;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceType = iosInfo.model;
        operatingSystem = 'iOS';
        osVersion = iosInfo.systemVersion;
      }

      final supportMessage = SupportMessage(
        userName: userName,
        userEmail: userEmail,
        subject: subject,
        message: message,
        deviceType: deviceType,
        operatingSystem: operatingSystem,
        osVersion: osVersion,
        appVersion: appVersion,
      );

      final result = await repository.sendSupportMessage(supportMessage);

      result.fold(
        (failure) => emit(SupportError(message: failure.message)),
        (data) {
          final referenceNumber = data['referenceNumber'] ?? '';
          final responseMessage = data['message'] ?? 'تم إرسال رسالتك بنجاح';
          emit(SupportSuccess(
            message: responseMessage,
            referenceNumber: referenceNumber,
          ));
        },
      );
    } catch (e) {
      emit(SupportError(message: 'حدث خطأ: ${e.toString()}'));
    }
  }
}
