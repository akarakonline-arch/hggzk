import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class ApiConstants {
  ApiConstants._();

  // Base URLs
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    // defaultValue: 'http://api.hggzk.com/',
    defaultValue: 'http://192.168.0.209:5000/',
  );

  // Derived base URLs for different API areas
  static String get commonBaseUrl =>
      baseUrl.endsWith('/') ? '${baseUrl}api/common' : '$baseUrl/api/common';

  static String get adminBaseUrl =>
      baseUrl.endsWith('/') ? '${baseUrl}api/admin' : '$baseUrl/api/admin';

  static const String imageBaseUrl = String.fromEnvironment(
    'IMAGE_BASE_URL',
    // defaultValue: 'http://api.hggzk.com',
    defaultValue: 'http://192.168.0.209:5000',
  );

  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    // defaultValue: 'wss://ws.api.hggzk.com',
    defaultValue: 'ws://192.168.0.209:5000',
  );

  // Google Places API
  static String get googlePlacesApiKey {
    const String fromEnv = String.fromEnvironment(
      'GOOGLE_PLACES_API_KEY',
      defaultValue: '',
    );
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'AIzaSyBUpSeBzpMhnKCDSJYmbrNwgsSY7PDlm-M';
    return defaultTargetPlatform == TargetPlatform.iOS
        ? 'AIzaSyD9O2NbSnvuV3L8Fknz1SqQehBxWLKkZKE'
        : 'AIzaSyBUpSeBzpMhnKCDSJYmbrNwgsSY7PDlm-M';
  }
  static const String googlePlacesBaseUrl =
      'https://maps.googleapis.com/maps/api/place';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout =
      Duration(seconds: 600); // 10 minutes for large file uploads

  // Headers
  static const String contentType = 'Content-Type';
  static const String applicationJson = 'application/json';
  static const String authorization = 'Authorization';
  static const String bearer = 'Bearer';
  static const String acceptLanguage = 'Accept-Language';
  static const String xAccountRole = 'X-Account-Role';
  static const String xPropertyId = 'X-Property-Id';
  static const String xPropertyCurrency = 'X-Property-Currency';

  // API Versions
  static const String apiVersion = 'v1';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Resource paths
  static String get units => baseUrl.endsWith('/')
      ? '${baseUrl}api/admin/Units'
      : '$baseUrl/api/admin/Units';
}
