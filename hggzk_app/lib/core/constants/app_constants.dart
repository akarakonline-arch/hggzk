class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'hggzk';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Durations
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration debounceTime = Duration(milliseconds: 500);
  static const Duration snackBarDuration = Duration(seconds: 3);

  // Limits
  static const int maxImageUploadSize = 10 * 1024 * 1024; // 10MB
  static const int maxImagesPerProperty = 20;
  static const int maxReviewImages = 5;
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int otpLength = 6;

  // Formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String currencyCode = 'YER';
  static const String currencySymbol = '﷼';

  // Map
  static const double defaultLatitude = 15.3694;
  static const double defaultLongitude = 44.1910;
  static const double defaultZoom = 12.0;

  // Cache
  static const Duration cacheValidDuration = Duration(hours: 24);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB

  // Regex Patterns
  static const String emailPattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phonePattern = r'^\+?967[0-9]{9}$';
  static const String namePattern = r'^[a-zA-Z\u0600-\u06FF\s]+$';

  // ═══════════════════════════════════════════════════════════════════
  // Google OAuth Client IDs
  // يجب أن تتطابق مع GoogleClientIds في Backend
  // ═══════════════════════════════════════════════════════════════════
  static const String googleWebClientId = '';
  // static const String googleAndroidClientId =
  //     '90807496145-is1cdvm5lmm2cpcd346ivh22rcf43orr.apps.googleusercontent.com';
  static const String googleAndroidClientId =
      '90807496145-7g24d05j7ear9sepjmjuq9r3pnhm11hl.apps.googleusercontent.com';
  static const String googleIosClientId = '';

  // ═══════════════════════════════════════════════════════════════════
  // Facebook OAuth
  // ═══════════════════════════════════════════════════════════════════
  static const String facebookAppId =
      '000000000000000'; // TODO: استبدل بـ App ID الحقيقي
}
