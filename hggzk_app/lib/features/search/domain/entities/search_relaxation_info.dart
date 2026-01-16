import 'package:equatable/equatable.dart';
import 'package:hggzk/core/enums/search_relaxation_level.dart';

/// معلومات تفصيلية عن تخفيف معايير البحث
/// Search Relaxation Information Entity
/// 
/// يحتوي على جميع المعلومات المتعلقة بالتخفيف الذي تم تطبيقه
/// على معايير البحث للحصول على نتائج
class SearchRelaxationInfo extends Equatable {
  /// مستوى التخفيف المطبق
  /// Applied relaxation level
  final SearchRelaxationLevel relaxationLevel;

  /// قائمة الفلاتر التي تم تخفيفها
  /// List of relaxed filters
  /// مثال: ["توسيع نطاق السعر 15%", "تقليل المرافق المطلوبة"]
  final List<String> relaxedFilters;

  /// استراتيجية البحث المطبقة
  /// Applied search strategy
  final String searchStrategy;

  /// المعايير الأصلية (قبل التخفيف)
  /// Original criteria (before relaxation)
  final Map<String, dynamic> originalCriteria;

  /// المعايير الفعلية (بعد التخفيف)
  /// Actual criteria (after relaxation)
  final Map<String, dynamic> actualCriteria;

  /// رسالة للمستخدم توضح التخفيف المطبق
  /// User message explaining applied relaxation
  final String? userMessage;

  /// اقتراحات لتحسين البحث
  /// Suggestions to improve search
  /// مثال: ["جرب تغيير تواريخ السفر", "عدّل نطاق السعر"]
  final List<String> suggestedActions;

  const SearchRelaxationInfo({
    required this.relaxationLevel,
    required this.relaxedFilters,
    required this.searchStrategy,
    required this.originalCriteria,
    required this.actualCriteria,
    this.userMessage,
    required this.suggestedActions,
  });

  /// هل تم تطبيق تخفيف؟
  /// Was relaxation applied?
  bool get wasRelaxed => relaxationLevel != SearchRelaxationLevel.exact;

  /// عدد الفلاتر المخففة
  /// Number of relaxed filters
  int get relaxedFiltersCount => relaxedFilters.length;

  /// هل هناك رسالة للمستخدم؟
  /// Is there a user message?
  bool get hasUserMessage => userMessage != null && userMessage!.isNotEmpty;

  /// هل هناك اقتراحات؟
  /// Are there suggestions?
  bool get hasSuggestions => suggestedActions.isNotEmpty;

  /// نسخة فارغة (بدون تخفيف)
  /// Empty instance (no relaxation)
  static const SearchRelaxationInfo empty = SearchRelaxationInfo(
    relaxationLevel: SearchRelaxationLevel.exact,
    relaxedFilters: [],
    searchStrategy: 'تطابق دقيق',
    originalCriteria: {},
    actualCriteria: {},
    userMessage: null,
    suggestedActions: [],
  );

  /// إنشاء من SearchPropertiesResponseModel
  /// Create from response model
  factory SearchRelaxationInfo.fromResponse({
    required SearchRelaxationLevel relaxationLevel,
    required List<String> relaxedFilters,
    required String searchStrategy,
    required Map<String, dynamic> originalCriteria,
    required Map<String, dynamic> actualCriteria,
    String? userMessage,
    required List<String> suggestedActions,
  }) {
    return SearchRelaxationInfo(
      relaxationLevel: relaxationLevel,
      relaxedFilters: relaxedFilters,
      searchStrategy: searchStrategy,
      originalCriteria: originalCriteria,
      actualCriteria: actualCriteria,
      userMessage: userMessage,
      suggestedActions: suggestedActions,
    );
  }

  /// نسخ مع تعديل بعض الحقول
  /// Copy with modified fields
  SearchRelaxationInfo copyWith({
    SearchRelaxationLevel? relaxationLevel,
    List<String>? relaxedFilters,
    String? searchStrategy,
    Map<String, dynamic>? originalCriteria,
    Map<String, dynamic>? actualCriteria,
    String? userMessage,
    List<String>? suggestedActions,
  }) {
    return SearchRelaxationInfo(
      relaxationLevel: relaxationLevel ?? this.relaxationLevel,
      relaxedFilters: relaxedFilters ?? this.relaxedFilters,
      searchStrategy: searchStrategy ?? this.searchStrategy,
      originalCriteria: originalCriteria ?? this.originalCriteria,
      actualCriteria: actualCriteria ?? this.actualCriteria,
      userMessage: userMessage ?? this.userMessage,
      suggestedActions: suggestedActions ?? this.suggestedActions,
    );
  }

  @override
  List<Object?> get props => [
        relaxationLevel,
        relaxedFilters,
        searchStrategy,
        originalCriteria,
        actualCriteria,
        userMessage,
        suggestedActions,
      ];

  @override
  String toString() {
    return 'SearchRelaxationInfo('
        'level: $relaxationLevel, '
        'filters: ${relaxedFilters.length}, '
        'strategy: $searchStrategy, '
        'hasMessage: $hasUserMessage, '
        'suggestions: ${suggestedActions.length}'
        ')';
  }
}
