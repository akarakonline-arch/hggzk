/// شدة الفرق بين المعيار المطلوب والقيمة الفعلية
/// Severity of the mismatch between requested and actual values
enum MismatchSeverity {
  /// فرق بسيط (مثل: طلب 5 ضيوف، يوفر 4)
  /// Minor difference (e.g., requested 5 guests, provides 4)
  minor,
  
  /// فرق متوسط (مثل: طلب مسبح، لا يوفر)
  /// Moderate difference (e.g., requested pool, doesn't provide)
  moderate,
  
  /// فرق كبير (مثل: طلب نطاق سعر 5000-8000، يوفر 12000)
  /// Major difference (e.g., requested price range 5000-8000, provides 12000)
  major;
  
  /// تحويل من String إلى MismatchSeverity
  /// Convert from String to MismatchSeverity
  static MismatchSeverity fromString(String? value) {
    if (value == null) return MismatchSeverity.minor;
    
    switch (value.toLowerCase()) {
      case 'minor':
        return MismatchSeverity.minor;
      case 'moderate':
        return MismatchSeverity.moderate;
      case 'major':
        return MismatchSeverity.major;
      default:
        return MismatchSeverity.minor;
    }
  }
  
  /// تحويل إلى String
  /// Convert to String
  String toJsonString() {
    return name;
  }
}

/// يمثل فرقاً بين معيار مطلوب وقيمة فعلية في العقار
/// Represents a mismatch between a requested criterion and actual property value
class PropertyFilterMismatchModel {
  /// نوع الفلتر (GuestsCount, DynamicField, Price)
  /// Filter type
  final String filterType;
  
  /// اسم الفلتر (عربي للعرض)
  /// Display name in Arabic
  final String filterDisplayName;
  
  /// القيمة المطلوبة من المستخدم
  /// Requested value from user
  final String requestedValue;
  
  /// القيمة الفعلية في العقار (أو الوحدة)
  /// Actual value in the property (or unit)
  final String actualValue;
  
  /// رسالة مختصرة للعرض في UI
  /// Brief message for UI display
  final String displayMessage;
  
  /// شدة الفرق
  /// Severity of the mismatch
  final MismatchSeverity severity;
  
  const PropertyFilterMismatchModel({
    required this.filterType,
    required this.filterDisplayName,
    required this.requestedValue,
    required this.actualValue,
    required this.displayMessage,
    required this.severity,
  });
  
  /// إنشاء من JSON
  /// Create from JSON
  factory PropertyFilterMismatchModel.fromJson(Map<String, dynamic> json) {
    return PropertyFilterMismatchModel(
      filterType: json['filterType'] as String? ?? '',
      filterDisplayName: json['filterDisplayName'] as String? ?? '',
      requestedValue: json['requestedValue'] as String? ?? '',
      actualValue: json['actualValue'] as String? ?? '',
      displayMessage: json['displayMessage'] as String? ?? '',
      severity: MismatchSeverity.fromString(json['severity'] as String?),
    );
  }
  
  /// تحويل إلى JSON
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'filterType': filterType,
      'filterDisplayName': filterDisplayName,
      'requestedValue': requestedValue,
      'actualValue': actualValue,
      'displayMessage': displayMessage,
      'severity': severity.toJsonString(),
    };
  }
  
  @override
  String toString() {
    return 'PropertyFilterMismatchModel(filterType: $filterType, displayName: $filterDisplayName, message: $displayMessage, severity: $severity)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is PropertyFilterMismatchModel &&
      other.filterType == filterType &&
      other.filterDisplayName == filterDisplayName &&
      other.requestedValue == requestedValue &&
      other.actualValue == actualValue &&
      other.displayMessage == displayMessage &&
      other.severity == severity;
  }
  
  @override
  int get hashCode {
    return Object.hash(
      filterType,
      filterDisplayName,
      requestedValue,
      actualValue,
      displayMessage,
      severity,
    );
  }
}
