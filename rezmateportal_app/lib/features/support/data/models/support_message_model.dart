import '../../domain/entities/support_message.dart';

class SupportMessageModel extends SupportMessage {
  SupportMessageModel({
    required super.userName,
    required super.userEmail,
    required super.subject,
    required super.message,
    super.deviceType,
    super.operatingSystem,
    super.osVersion,
    super.appVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'userName': userName,
      'userEmail': userEmail,
      'subject': subject,
      'message': message,
      if (deviceType != null) 'deviceType': deviceType,
      if (operatingSystem != null) 'operatingSystem': operatingSystem,
      if (osVersion != null) 'osVersion': osVersion,
      if (appVersion != null) 'appVersion': appVersion,
    };
  }
}
