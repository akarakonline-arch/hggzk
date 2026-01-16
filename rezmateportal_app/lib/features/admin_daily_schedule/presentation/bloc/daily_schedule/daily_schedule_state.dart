// lib/features/admin_daily_schedule/presentation/bloc/daily_schedule/daily_schedule_state.dart

part of 'daily_schedule_bloc.dart';

/// الصنف الأساسي لجميع حالات الجدول اليومي
/// جميع الحالات يجب أن ترث من هذا الصنف
sealed class DailyScheduleState extends Equatable {
  const DailyScheduleState();

  @override
  List<Object?> get props => [];
}

// ===== الحالة الأولية =====

/// الحالة الأولية قبل أي عملية
class DailyScheduleInitial extends DailyScheduleState {
  const DailyScheduleInitial();
}

// ===== حالة التحميل =====

/// حالة التحميل أثناء جلب البيانات
class DailyScheduleLoading extends DailyScheduleState {
  /// رسالة التحميل (اختياري)
  final String? loadingMessage;

  const DailyScheduleLoading({this.loadingMessage});

  @override
  List<Object?> get props => [loadingMessage];
}

// ===== حالة التحميل الناجح =====

/// حالة تحميل الجدول بنجاح
class DailyScheduleLoaded extends DailyScheduleState {
  /// الجدول الشهري المحمّل
  final MonthlySchedule monthlySchedule;

  /// معرّف الوحدة المختارة حاليًا
  final String? selectedUnitId;

  /// السنة الحالية
  final int currentYear;

  /// الشهر الحالي (1-12)
  final int currentMonth;

  /// نتيجة التحقق من التوفر (إن وجدت)
  final CheckAvailabilityResponse? availabilityCheckResult;

  /// السعر الإجمالي المحسوب (إن وجد)
  final double? calculatedPrice;

  /// حالة التصفية الحالية (null = بدون تصفية)
  final ScheduleStatus? currentFilter;

  const DailyScheduleLoaded({
    required this.monthlySchedule,
    this.selectedUnitId,
    required this.currentYear,
    required this.currentMonth,
    this.availabilityCheckResult,
    this.calculatedPrice,
    this.currentFilter,
  });

  /// نسخ الحالة مع تعديل بعض الخصائص
  DailyScheduleLoaded copyWith({
    MonthlySchedule? monthlySchedule,
    String? selectedUnitId,
    int? currentYear,
    int? currentMonth,
    CheckAvailabilityResponse? availabilityCheckResult,
    double? calculatedPrice,
    ScheduleStatus? currentFilter,
    bool clearAvailabilityCheck = false,
    bool clearCalculatedPrice = false,
    bool clearFilter = false,
  }) {
    return DailyScheduleLoaded(
      monthlySchedule: monthlySchedule ?? this.monthlySchedule,
      selectedUnitId: selectedUnitId ?? this.selectedUnitId,
      currentYear: currentYear ?? this.currentYear,
      currentMonth: currentMonth ?? this.currentMonth,
      availabilityCheckResult: clearAvailabilityCheck
          ? null
          : (availabilityCheckResult ?? this.availabilityCheckResult),
      calculatedPrice: clearCalculatedPrice
          ? null
          : (calculatedPrice ?? this.calculatedPrice),
      currentFilter:
          clearFilter ? null : (currentFilter ?? this.currentFilter),
    );
  }

  /// الحصول على الجداول المصفاة (إذا كانت التصفية مفعلة)
  List<DailySchedule> get filteredSchedules {
    if (currentFilter == null) {
      return monthlySchedule.schedules;
    }
    return monthlySchedule.schedules
        .where((schedule) => schedule.status == currentFilter)
        .toList();
  }

  @override
  List<Object?> get props => [
        monthlySchedule,
        selectedUnitId,
        currentYear,
        currentMonth,
        availabilityCheckResult,
        calculatedPrice,
        currentFilter,
      ];
}

// ===== حالة التحديث =====

/// حالة التحديث أثناء عملية تحديث البيانات
class DailyScheduleUpdating extends DailyScheduleState {
  /// الجدول الحالي قبل التحديث
  final MonthlySchedule currentSchedule;

  /// رسالة التحديث
  final String updatingMessage;

  const DailyScheduleUpdating({
    required this.currentSchedule,
    required this.updatingMessage,
  });

  @override
  List<Object> get props => [currentSchedule, updatingMessage];
}

// ===== حالة نجاح التحديث =====

/// حالة نجاح عملية التحديث
class DailyScheduleUpdateSuccess extends DailyScheduleState {
  /// الجدول المحدّث
  final MonthlySchedule updatedSchedule;

  /// رسالة النجاح
  final String successMessage;

  /// عدد الأيام المتأثرة بالتحديث
  final int affectedDays;

  const DailyScheduleUpdateSuccess({
    required this.updatedSchedule,
    required this.successMessage,
    required this.affectedDays,
  });

  @override
  List<Object> get props => [updatedSchedule, successMessage, affectedDays];
}

// ===== حالة الخطأ =====

/// حالة الخطأ عند فشل أي عملية
class DailyScheduleError extends DailyScheduleState {
  /// رسالة الخطأ
  final String errorMessage;

  /// آخر جدول محمّل (إن وجد)
  final MonthlySchedule? lastSchedule;

  const DailyScheduleError({
    required this.errorMessage,
    this.lastSchedule,
  });

  @override
  List<Object?> get props => [errorMessage, lastSchedule];
}
