// lib/core/enums/section_ui_type.dart

/// UI Types for sections - defines which widget to use in client app
enum SectionTypeEnum {
  grid,
  bigCards,
  list,
}

extension SectionUITypeExtension on SectionTypeEnum {
  /// القيمة النصية للعرض والاستلام من API
  String get value {
    switch (this) {
      case SectionTypeEnum.grid:
        return 'grid';
      case SectionTypeEnum.bigCards:
        return 'bigCards';
      case SectionTypeEnum.list:
        return 'list';
    }
  }

  /// ✅ القيمة الرقمية للإرسال إلى الـ Backend (C# enum)
  /// Grid = 0, BigCards = 1, List = 2
  int get apiValue {
    switch (this) {
      case SectionTypeEnum.grid:
        return 0;
      case SectionTypeEnum.bigCards:
        return 1;
      case SectionTypeEnum.list:
        return 2;
    }
  }

  String get displayName {
    switch (this) {
      case SectionTypeEnum.grid:
        return 'شبكة (Grid)';
      case SectionTypeEnum.bigCards:
        return 'كروت كبيرة (Big Cards)';
      case SectionTypeEnum.list:
        return 'قائمة (List)';
    }
  }

  static SectionTypeEnum? tryFromString(String? value) {
    if (value == null) return null;
    for (final type in SectionTypeEnum.values) {
      if (type.value == value) return type;
    }
    // ✅ محاولة التحويل من رقم أو اسم Enum
    switch (value.toLowerCase()) {
      case '0':
      case 'grid':
        return SectionTypeEnum.grid;
      case '1':
      case 'bigcards':
        return SectionTypeEnum.bigCards;
      case '2':
      case 'list':
        return SectionTypeEnum.list;
    }
    return null;
  }
}
