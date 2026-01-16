// lib/core/enums/section_type_enum.dart

enum SectionType {
  grid,
  bigCards,
  list,
}

extension SectionTypeExtension on SectionType {
  String get value {
    switch (this) {
      case SectionType.grid:
        return 'grid';
      case SectionType.bigCards:
        return 'bigCards';
      case SectionType.list:
        return 'list';
    }
  }

  static SectionType? tryFromString(String value) {
    for (final type in SectionType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}