class Validators {
  Validators._();

  static bool isValidEmail(String email) {
    // Simple email regex pattern
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  static bool isValidPassword(String password, {int minLength = 8}) {
    if (password.length < minLength) {
      return false;
    }
    // Add more password complexity rules if needed (e.g., uppercase, number, special char)
    // final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$');
    // return passwordRegex.hasMatch(password);
    return true;
  }

  static bool isValidPhoneNumber(String phoneNumber) {
    // Example: YEMEN phone number format (967XXXXXXXXX)
    final phoneRegex = RegExp(r'^\+?967[0-9]{9}$');
    return phoneRegex.hasMatch(phoneNumber);
  }

  static bool isValidName(String name) {
    // Allows letters, spaces, and Arabic characters
    final nameRegex = RegExp(r'^[a-zA-Z\u0600-\u06FF\s]+$');
    return nameRegex.hasMatch(name);
  }

  static bool isNotEmpty(String? value) {
    return value != null && value.isNotEmpty;
  }

  static bool isAmountValid(String amount) {
    final amountRegex = RegExp(r'^\d+(\.\d{1,2})?$'); // Allows integers or decimals with 1 or 2 places
    return amountRegex.hasMatch(amount);
  }
  
  /// ✅ التحقق من أن النص هو GUID صحيح
  /// Validates that a string is a valid GUID/UUID
  /// 
  /// Supports:
  /// - Standard format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  /// - With braces: {xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx}
  /// - With parentheses: (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
  ///
  /// Example:
  /// ```dart
  /// Validators.isValidGuid('550e8400-e29b-41d4-a716-446655440000'); // true
  /// Validators.isValidGuid('invalid-guid'); // false
  /// ```
  static bool isValidGuid(String? value) {
    if (value == null || value.isEmpty) {
      return false;
    }

    // GUID/UUID regex pattern
    final guidRegex = RegExp(
      r'^[{(]?[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}[)}]?$',
      caseSensitive: false,
    );

    return guidRegex.hasMatch(value);
  }

  /// ✅ التحقق من قائمة من GUIDs
  /// Validates a list of GUIDs
  static bool areValidGuids(List<String>? values) {
    if (values == null || values.isEmpty) {
      return true; // Empty list is valid
    }

    return values.every((value) => isValidGuid(value));
  }

  /// ✅ تنظيف GUID (إزالة الأقواس وتوحيد الحالة)
  /// Normalizes a GUID by removing braces/parentheses
  static String? normalizeGuid(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    // Remove braces and parentheses, convert to lowercase
    return value.replaceAll(RegExp(r'[{}()]'), '').toLowerCase();
  }

  /// ✅ التحقق من أن القيمة رقمية
  /// Validates that a string is numeric
  static bool isNumeric(String? value) {
    if (value == null || value.isEmpty) {
      return false;
    }

    return double.tryParse(value) != null;
  }

  /// ✅ التحقق من نطاق رقمي
  /// Validates that a value is within a numeric range
  static bool isInRange(double? value, double min, double max) {
    if (value == null) {
      return false;
    }

    return value >= min && value <= max;
  }
  
  // Add other validation methods as needed
}