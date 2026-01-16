import 'package:flutter/material.dart';

/// مساعد لتحويل الحقول الديناميكية إلى query parameters
/// Helper for serializing dynamic fields to query parameters compatible with ASP.NET Core
class DynamicFieldSerializer {
  DynamicFieldSerializer._();

  /// تحويل قيم الحقول الديناميكية إلى Map<String, String>
  /// يدعم جميع أنواع البيانات: RangeValues, List, bool, DateTime, etc.
  ///
  /// Example:
  /// ```dart
  /// final values = {
  ///   'numberOfBedrooms': 3,
  ///   'area': RangeValues(50, 150),
  ///   'hasBalcony': true,
  ///   'features': ['WiFi', 'Parking'],
  /// };
  ///
  /// final serialized = DynamicFieldSerializer.serialize(values);
  /// // Result:
  /// // {
  /// //   'numberOfBedrooms': '3',
  /// //   'area': '50..150',
  /// //   'hasBalcony': 'true',
  /// //   'features': 'WiFi,Parking'
  /// // }
  /// ```
  static Map<String, String> serialize(Map<String, dynamic> values) {
    final result = <String, String>{};

    values.forEach((key, value) {
      if (value == null) return;

      final serialized = _serializeValue(value);
      if (serialized != null && serialized.isNotEmpty) {
        result[key] = serialized;
      }
    });

    return result;
  }

  /// تحويل قيمة واحدة إلى String
  static String? _serializeValue(dynamic value) {
    if (value == null) return null;

    // 1️⃣ Range Values (للنطاقات الرقمية)
    if (value is RangeValues) {
      return '${value.start.toInt()}..${value.end.toInt()}';
    }

    // 2️⃣ Lists (للقوائم المتعددة)
    if (value is List) {
      if (value.isEmpty) return null;
      return value.map((v) => v.toString()).join(',');
    }

    // 3️⃣ Boolean values
    if (value is bool) {
      return value.toString(); // 'true' or 'false'
    }

    // 4️⃣ DateTime values
    if (value is DateTime) {
      return value.toIso8601String();
    }

    // 5️⃣ Numbers (int, double)
    if (value is num) {
      return value.toString();
    }

    // 6️⃣ Strings (including text search with ~)
    if (value is String) {
      return value.trim().isEmpty ? null : value;
    }

    // Default: toString()
    return value.toString();
  }

  /// إضافة بادئة ~ للبحث النصي الجزئي
  /// Adds ~ prefix for partial text search
  static String withTextSearch(String text) {
    if (text.isEmpty) return text;
    return '~$text';
  }

  /// إنشاء نطاق رقمي
  /// Creates a numeric range string
  static String createRange(num min, num max) {
    return '$min..$max';
  }

  /// تحويل قائمة إلى CSV
  /// Converts a list to comma-separated values
  static String listToCsv(List<String> items) {
    return items.join(',');
  }

  /// استخراج نطاق من String
  /// Extracts range from a string like "50..150"
  static RangeValues? parseRange(String? value) {
    if (value == null || !value.contains('..')) return null;

    final parts = value.split('..');
    if (parts.length != 2) return null;

    final min = double.tryParse(parts[0]);
    final max = double.tryParse(parts[1]);

    if (min == null || max == null) return null;

    return RangeValues(min, max);
  }

  /// استخراج قائمة من CSV
  /// Extracts list from comma-separated values
  static List<String>? parseCsv(String? value) {
    if (value == null || value.isEmpty) return null;

    return value
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// استخراج boolean من String
  /// Parses boolean from string
  static bool? parseBool(String? value) {
    if (value == null || value.isEmpty) return null;

    final lower = value.toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;

    return null;
  }

  /// التحقق من صحة نطاق رقمي
  /// Validates a numeric range
  static bool isValidRange(String value) {
    if (!value.contains('..')) return false;

    final parts = value.split('..');
    if (parts.length != 2) return false;

    final min = double.tryParse(parts[0]);
    final max = double.tryParse(parts[1]);

    return min != null && max != null && min <= max;
  }

  /// التحقق من صحة بحث نصي
  /// Validates text search format
  static bool isTextSearch(String value) {
    return value.startsWith('~') && value.length > 1;
  }

  /// إزالة بادئة ~ من البحث النصي
  /// Removes ~ prefix from text search
  static String unwrapTextSearch(String value) {
    return value.startsWith('~') ? value.substring(1) : value;
  }
}
