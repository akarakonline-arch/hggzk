/// مستويات تخفيف معايير البحث
/// Search Relaxation Levels
///
/// يحدد مدى التخفيف الذي تم تطبيقه على معايير البحث الأصلية
/// للحصول على نتائج مطابقة
enum SearchRelaxationLevel {
  /// بحث دقيق - تطابق تام مع جميع المعايير
  /// Exact match - all criteria must match exactly
  exact,

  /// تخفيف بسيط - 15-20% توسع في المعايير
  /// Minor relaxation - 15-20% expansion in criteria
  /// مثال: توسيع السعر ±15%، تقليل المرافق المطلوبة
  minorRelaxation,

  /// تخفيف متوسط - 30-40% توسع في المعايير
  /// Moderate relaxation - 30-40% expansion in criteria
  /// مثال: توسيع السعر ±30%، إضافة المدن المجاورة
  moderateRelaxation,

  /// تخفيف كبير - 50%+ توسع في المعايير
  /// Major relaxation - 50%+ expansion in criteria
  /// مثال: توسيع السعر ±50%، مرونة في التواريخ
  majorRelaxation,

  /// اقتراحات بديلة - البحث بمعايير أساسية فقط
  /// Alternative suggestions - search with basic criteria only
  /// مثال: المدينة والتواريخ فقط
  alternativeSuggestions,
}

/// Extension methods لـ SearchRelaxationLevel
extension SearchRelaxationLevelExtension on SearchRelaxationLevel {
  /// تحويل من String أو Integer إلى Enum
  /// Convert from String or Integer to Enum
  static SearchRelaxationLevel fromString(dynamic value) {
    if (value == null) return SearchRelaxationLevel.exact;

    // إذا كان رقم (من Backend C# enum)
    // If it's a number (from Backend C# enum)
    if (value is int) {
      switch (value) {
        case 0:
          return SearchRelaxationLevel.exact;
        case 1:
          return SearchRelaxationLevel.minorRelaxation;
        case 2:
          return SearchRelaxationLevel.moderateRelaxation;
        case 3:
          return SearchRelaxationLevel.majorRelaxation;
        case 4:
          return SearchRelaxationLevel.alternativeSuggestions;
        default:
          return SearchRelaxationLevel.exact;
      }
    }

    // إذا كان نص
    // If it's a string
    final stringValue = value.toString().toLowerCase();
    switch (stringValue) {
      case 'exact':
      case '0':
        return SearchRelaxationLevel.exact;
      case 'minorrelaxation':
      case 'minor':
      case '1':
        return SearchRelaxationLevel.minorRelaxation;
      case 'moderaterelaxation':
      case 'moderate':
      case '2':
        return SearchRelaxationLevel.moderateRelaxation;
      case 'majorrelaxation':
      case 'major':
      case '3':
        return SearchRelaxationLevel.majorRelaxation;
      case 'alternativesuggestions':
      case 'alternative':
      case '4':
        return SearchRelaxationLevel.alternativeSuggestions;
      default:
        return SearchRelaxationLevel.exact;
    }
  }

  /// تحويل من Enum إلى String للإرسال للـ Backend
  /// Convert from Enum to String for Backend
  String toBackendString() {
    switch (this) {
      case SearchRelaxationLevel.exact:
        return 'Exact';
      case SearchRelaxationLevel.minorRelaxation:
        return 'MinorRelaxation';
      case SearchRelaxationLevel.moderateRelaxation:
        return 'ModerateRelaxation';
      case SearchRelaxationLevel.majorRelaxation:
        return 'MajorRelaxation';
      case SearchRelaxationLevel.alternativeSuggestions:
        return 'AlternativeSuggestions';
    }
  }

  /// الاسم بالعربية
  /// Arabic name
  String get displayNameAr {
    switch (this) {
      case SearchRelaxationLevel.exact:
        return 'تطابق دقيق';
      case SearchRelaxationLevel.minorRelaxation:
        return 'تخفيف بسيط';
      case SearchRelaxationLevel.moderateRelaxation:
        return 'تخفيف متوسط';
      case SearchRelaxationLevel.majorRelaxation:
        return 'تخفيف كبير';
      case SearchRelaxationLevel.alternativeSuggestions:
        return 'اقتراحات بديلة';
    }
  }

  /// الاسم بالإنجليزية
  /// English name
  String get displayNameEn {
    switch (this) {
      case SearchRelaxationLevel.exact:
        return 'Exact Match';
      case SearchRelaxationLevel.minorRelaxation:
        return 'Minor Relaxation';
      case SearchRelaxationLevel.moderateRelaxation:
        return 'Moderate Relaxation';
      case SearchRelaxationLevel.majorRelaxation:
        return 'Major Relaxation';
      case SearchRelaxationLevel.alternativeSuggestions:
        return 'Alternative Suggestions';
    }
  }

  /// الأيقونة المناسبة لكل مستوى
  /// Icon for each level
  String get icon {
    switch (this) {
      case SearchRelaxationLevel.exact:
        return '✓'; // تطابق
      case SearchRelaxationLevel.minorRelaxation:
        return '⚡'; // طفيف
      case SearchRelaxationLevel.moderateRelaxation:
        return '🔄'; // متوسط
      case SearchRelaxationLevel.majorRelaxation:
        return '🚀'; // كبير
      case SearchRelaxationLevel.alternativeSuggestions:
        return '💡'; // بديل
    }
  }

  /// اللون المناسب لكل مستوى (Hex)
  /// Color for each level
  int get colorValue {
    switch (this) {
      case SearchRelaxationLevel.exact:
        return 0xFF4CAF50; // أخضر
      case SearchRelaxationLevel.minorRelaxation:
        return 0xFF2196F3; // أزرق
      case SearchRelaxationLevel.moderateRelaxation:
        return 0xFFFF9800; // برتقالي
      case SearchRelaxationLevel.majorRelaxation:
        return 0xFFFF5722; // أحمر فاتح
      case SearchRelaxationLevel.alternativeSuggestions:
        return 0xFF9E9E9E; // رمادي
    }
  }

  /// هل تم تطبيق تخفيف؟
  /// Was relaxation applied?
  bool get wasRelaxed {
    return this != SearchRelaxationLevel.exact;
  }

  /// نسبة التخفيف المئوية التقريبية
  /// Approximate relaxation percentage
  int get relaxationPercentage {
    switch (this) {
      case SearchRelaxationLevel.exact:
        return 0;
      case SearchRelaxationLevel.minorRelaxation:
        return 15;
      case SearchRelaxationLevel.moderateRelaxation:
        return 30;
      case SearchRelaxationLevel.majorRelaxation:
        return 50;
      case SearchRelaxationLevel.alternativeSuggestions:
        return 100;
    }
  }
}
