import 'package:equatable/equatable.dart';
import 'daily_schedule.dart';

/// كيان الجدول الشهري
/// يمثل مجموعة من الأيام (DailySchedule) لشهر كامل مع إحصائياته
class MonthlySchedule extends Equatable {
  /// معرّف الوحدة
  final String unitId;

  /// السنة
  final int year;

  /// الشهر (1-12)
  final int month;

  /// قائمة الأيام في هذا الشهر
  final List<DailySchedule> schedules;

  /// إحصائيات الشهر (اختياري)
  /// يحتوي على معلومات إضافية مثل:
  /// - totalDays: إجمالي عدد الأيام
  /// - availableDays: عدد الأيام المتاحة
  /// - bookedDays: عدد الأيام المحجوزة
  /// - blockedDays: عدد الأيام المحظورة
  /// - maintenanceDays: عدد أيام الصيانة
  /// - totalRevenue: إجمالي الإيرادات المتوقعة
  /// - averagePrice: متوسط السعر
  /// - minPrice: أقل سعر
  /// - maxPrice: أعلى سعر
  /// - occupancyRate: نسبة الإشغال
  final Map<String, dynamic>? statistics;

  const MonthlySchedule({
    required this.unitId,
    required this.year,
    required this.month,
    required this.schedules,
    this.statistics,
  });

  // ===== Helper Getters =====

  /// إجمالي عدد الأيام في الجدول
  int get totalDays => schedules.length;

  /// عدد الأيام المتاحة
  int get availableDays =>
      schedules.where((s) => s.isAvailable).length;

  /// عدد الأيام المحجوزة
  int get bookedDays =>
      schedules.where((s) => s.isBooked).length;

  /// عدد الأيام المحظورة
  int get blockedDays =>
      schedules.where((s) => s.isBlocked).length;

  /// عدد أيام الصيانة
  int get maintenanceDays =>
      schedules.where((s) => s.isMaintenance).length;

  /// عدد الأيام في استخدام المالك
  int get ownerUseDays =>
      schedules.where((s) => s.isOwnerUse).length;

  /// نسبة الإشغال (%)
  double get occupancyRate {
    if (totalDays == 0) return 0.0;
    return (bookedDays / totalDays) * 100.0;
  }

  /// إجمالي الإيرادات المتوقعة
  double get totalRevenue {
    return schedules
        .where((s) => s.priceAmount != null)
        .fold<double>(0.0, (sum, s) => sum + (s.priceAmount ?? 0.0));
  }

  /// متوسط السعر
  double get averagePrice {
    final pricesSchedules = schedules.where((s) => s.priceAmount != null && s.priceAmount! > 0).toList();
    if (pricesSchedules.isEmpty) return 0.0;
    final total = pricesSchedules.fold<double>(0.0, (sum, s) => sum + (s.priceAmount ?? 0.0));
    return total / pricesSchedules.length;
  }

  /// الحصول على جدول يوم محدد
  DailySchedule? getScheduleForDate(DateTime date) {
    try {
      return schedules.firstWhere(
        (s) => s.date.year == date.year &&
               s.date.month == date.month &&
               s.date.day == date.day,
      );
    } catch (_) {
      return null;
    }
  }

  /// الحصول على الجداول حسب الحالة
  List<DailySchedule> getSchedulesByStatus(ScheduleStatus status) {
    return schedules.where((s) => s.status == status).toList();
  }

  /// الحصول على الجداول في فترة محددة
  List<DailySchedule> getSchedulesInRange(DateTime start, DateTime end) {
    return schedules.where((s) =>
      s.date.isAfter(start.subtract(const Duration(days: 1))) &&
      s.date.isBefore(end.add(const Duration(days: 1)))
    ).toList();
  }

  // ===== Methods =====

  /// نسخ الكيان مع تعديل بعض الخصائص
  MonthlySchedule copyWith({
    String? unitId,
    int? year,
    int? month,
    List<DailySchedule>? schedules,
    Map<String, dynamic>? statistics,
  }) {
    return MonthlySchedule(
      unitId: unitId ?? this.unitId,
      year: year ?? this.year,
      month: month ?? this.month,
      schedules: schedules ?? this.schedules,
      statistics: statistics ?? this.statistics,
    );
  }

  @override
  List<Object?> get props => [unitId, year, month, schedules, statistics];
}
