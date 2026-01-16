class SupportMessage {
  final String userName;
  final String userEmail;
  final String subject;
  final String message;
  final String? deviceType;
  final String? operatingSystem;
  final String? osVersion;
  final String? appVersion;

  SupportMessage({
    required this.userName,
    required this.userEmail,
    required this.subject,
    required this.message,
    this.deviceType,
    this.operatingSystem,
    this.osVersion,
    this.appVersion,
  });
}
