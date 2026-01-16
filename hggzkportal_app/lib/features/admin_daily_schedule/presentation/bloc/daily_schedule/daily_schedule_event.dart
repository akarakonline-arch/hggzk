// lib/features/admin_daily_schedule/presentation/bloc/daily_schedule/daily_schedule_event.dart

part of 'daily_schedule_bloc.dart';

/// الصنف الأساسي لجميع أحداث الجدول اليومي
/// جميع الأحداث يجب أن ترث من هذا الصنف
sealed class DailyScheduleEvent extends Equatable {
  const DailyScheduleEvent();

  @override
  List<Object?> get props => [];
}

// ===== أحداث التحميل =====

/// حدث تحميل الجدول الشهري
/// يُستخدم لتحميل جدول شهر كامل لوحدة معينة
class LoadMonthlyScheduleEvent extends DailyScheduleEvent {
  /// معرّف الوحدة
  final String unitId;

  /// السنة
  final int year;

  /// الشهر (1-12)
  final int month;

  const LoadMonthlyScheduleEvent({
    required this.unitId,
    required this.year,
    required this.month,
  });

  @override
  List<Object> get props => [unitId, year, month];
}

// ===== أحداث التنقل =====

/// حدث تغيير الشهر
/// يُستخدم للتنقل بين الأشهر (التالي/السابق)
class ChangeMonthEvent extends DailyScheduleEvent {
  /// السنة الجديدة
  final int year;

  /// الشهر الجديد (1-12)
  final int month;

  const ChangeMonthEvent({
    required this.year,
    required this.month,
  });

  @override
  List<Object> get props => [year, month];
}

/// حدث اختيار وحدة
/// يُستخدم لتغيير الوحدة المعروضة
class SelectUnitEvent extends DailyScheduleEvent {
  /// معرّف الوحدة الجديدة
  final String unitId;

  const SelectUnitEvent({required this.unitId});

  @override
  List<Object> get props => [unitId];
}

// ===== أحداث التحديث =====

/// حدث تحديث يوم واحد
/// يُستخدم لتحديث إتاحة و/أو تسعير يوم واحد فقط
class UpdateSingleDayEvent extends DailyScheduleEvent {
  /// معرّف الوحدة
  final String unitId;

  /// التاريخ المستهدف
  final DateTime date;

  /// حالة الإتاحة (اختياري)
  final ScheduleStatus? status;

  /// مبلغ السعر (اختياري)
  final double? priceAmount;

  /// العملة (اختياري)
  final String? currency;

  /// نوع السعر (اختياري)
  final PriceType? priceType;

  /// فئة التسعير (اختياري)
  final PricingTier? pricingTier;

  /// السبب (اختياري - في حالة Blocked, Maintenance, OwnerUse)
  final String? reason;

  /// الملاحظات (اختياري)
  final String? notes;

  /// الكتابة فوق البيانات الموجودة
  final bool overwriteExisting;

  const UpdateSingleDayEvent({
    required this.unitId,
    required this.date,
    this.status,
    this.priceAmount,
    this.currency,
    this.priceType,
    this.pricingTier,
    this.reason,
    this.notes,
    this.overwriteExisting = false,
  });

  @override
  List<Object?> get props => [
        unitId,
        date,
        status,
        priceAmount,
        currency,
        priceType,
        pricingTier,
        reason,
        notes,
        overwriteExisting,
      ];
}

/// حدث تحديث فترة
/// يُستخدم لتحديث إتاحة و/أو تسعير فترة زمنية محددة
class UpdateDateRangeEvent extends DailyScheduleEvent {
  /// معاملات التحديث
  final UpdateScheduleParams params;

  const UpdateDateRangeEvent({required this.params});

  @override
  List<Object> get props => [params];
}

/// حدث التحديث الجماعي
/// يُستخدم للتحديث بناءً على أيام الأسبوع المحددة
class BulkUpdateScheduleEvent extends DailyScheduleEvent {
  /// معاملات التحديث الجماعي
  final BulkUpdateScheduleParams params;

  const BulkUpdateScheduleEvent({required this.params});

  @override
  List<Object> get props => [params];
}

// ===== أحداث التحقق والحسابات =====

/// حدث التحقق من التوفر
/// يُستخدم للتحقق من توفر الوحدة لفترة محددة
class CheckAvailabilityEvent extends DailyScheduleEvent {
  /// معاملات التحقق من التوفر
  final CheckAvailabilityParams params;

  const CheckAvailabilityEvent({required this.params});

  @override
  List<Object> get props => [params];
}

/// حدث حساب السعر الإجمالي
/// يُستخدم لحساب السعر الإجمالي لفترة محددة
class CalculateTotalPriceEvent extends DailyScheduleEvent {
  /// معرّف الوحدة
  final String unitId;

  /// تاريخ البداية
  final DateTime startDate;

  /// تاريخ النهاية
  final DateTime endDate;

  const CalculateTotalPriceEvent({
    required this.unitId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [unitId, startDate, endDate];
}

// ===== أحداث العمليات المتقدمة =====

/// حدث نسخ الجدول
/// يُستخدم لنسخ جدول من فترة إلى فترة أخرى
class CloneScheduleEvent extends DailyScheduleEvent {
  /// معاملات النسخ
  final CloneScheduleParams params;

  const CloneScheduleEvent({required this.params});

  @override
  List<Object> get props => [params];
}

/// حدث حذف الجدول
/// يُستخدم لحذف جدول لفترة محددة
class DeleteScheduleEvent extends DailyScheduleEvent {
  /// معاملات الحذف
  final DeleteScheduleParams params;

  const DeleteScheduleEvent({required this.params});

  @override
  List<Object> get props => [params];
}

// ===== أحداث أخرى =====

/// حدث إعادة تعيين حالة الأخطاء
/// يُستخدم لإعادة BLoC إلى الحالة الأولية
class ResetErrorEvent extends DailyScheduleEvent {
  const ResetErrorEvent();
}

/// حدث تصفية الجدول
/// يُستخدم لتصفية الجدول حسب حالة الإتاحة
class FilterScheduleEvent extends DailyScheduleEvent {
  /// حالة الإتاحة المستخدمة للتصفية (null = بدون تصفية)
  final ScheduleStatus? filterStatus;

  const FilterScheduleEvent({this.filterStatus});

  @override
  List<Object?> get props => [filterStatus];
}
