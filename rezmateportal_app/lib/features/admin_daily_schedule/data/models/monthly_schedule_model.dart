import '../../domain/entities/monthly_schedule.dart';
import '../../domain/entities/daily_schedule.dart';
import 'daily_schedule_model.dart';

/// نموذج MonthlyScheduleModel يمتد من Entity
/// يحتوي على قائمة من DailyScheduleModel وإحصائيات الشهر
class MonthlyScheduleModel extends MonthlySchedule {
  const MonthlyScheduleModel({
    required super.unitId,
    required super.year,
    required super.month,
    required super.schedules,
    super.statistics,
  });

  /// تحويل من JSON إلى Model
  /// يتعامل مع قائمة الـ schedules والإحصائيات
  factory MonthlyScheduleModel.fromJson(Map<String, dynamic> json) {
    // تحويل قائمة الـ schedules من JSON إلى List<DailyScheduleModel>
    final schedulesJson = json['Schedules'] as List<dynamic>?;
    final schedules = schedulesJson != null
        ? schedulesJson
            .map((e) => DailyScheduleModel.fromJson(e as Map<String, dynamic>))
            .toList()
        : <DailyScheduleModel>[];

    // تحويل الإحصائيات إذا كانت موجودة
    Map<String, dynamic>? statistics;
    if (json['Statistics'] != null) {
      statistics = _parseStatistics(json['Statistics'] as Map<String, dynamic>);
    }

    return MonthlyScheduleModel(
      unitId: json['UnitId'] as String,
      year: json['Year'] as int,
      month: json['Month'] as int,
      schedules: schedules,
      statistics: statistics,
    );
  }

  /// تحويل من Model إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'UnitId': unitId,
      'Year': year,
      'Month': month,
      'Schedules': schedules.map((e) {
        if (e is DailyScheduleModel) {
          return e.toJson();
        } else {
          return DailyScheduleModel.fromEntity(e).toJson();
        }
      }).toList(),
      if (statistics != null) 'Statistics': statistics,
    };
  }

  /// تحويل من Entity إلى Model
  factory MonthlyScheduleModel.fromEntity(MonthlySchedule entity) {
    return MonthlyScheduleModel(
      unitId: entity.unitId,
      year: entity.year,
      month: entity.month,
      schedules: entity.schedules
          .map((e) => e is DailyScheduleModel
              ? e
              : DailyScheduleModel.fromEntity(e))
          .toList(),
      statistics: entity.statistics,
    );
  }

  /// معالجة الإحصائيات من JSON
  /// يحتوي على معلومات مثل عدد الأيام المتاحة، المحجوزة، المحظورة، إلخ.
  static Map<String, dynamic> _parseStatistics(Map<String, dynamic> json) {
    return {
      'totalDays': json['TotalDays'] as int? ?? 0,
      'availableDays': json['AvailableDays'] as int? ?? 0,
      'bookedDays': json['BookedDays'] as int? ?? 0,
      'blockedDays': json['BlockedDays'] as int? ?? 0,
      'maintenanceDays': json['MaintenanceDays'] as int? ?? 0,
      'unavailableDays': json['UnavailableDays'] as int? ?? 0,
      'totalRevenue': json['TotalRevenue'] != null
          ? (json['TotalRevenue'] as num).toDouble()
          : 0.0,
      'averagePrice': json['AveragePrice'] != null
          ? (json['AveragePrice'] as num).toDouble()
          : 0.0,
      'minPrice': json['MinPrice'] != null
          ? (json['MinPrice'] as num).toDouble()
          : null,
      'maxPrice': json['MaxPrice'] != null
          ? (json['MaxPrice'] as num).toDouble()
          : null,
      'occupancyRate': json['OccupancyRate'] != null
          ? (json['OccupancyRate'] as num).toDouble()
          : 0.0,
    };
  }

  /// نسخ Model مع تحديث بعض الحقول
  @override
  MonthlySchedule copyWith({
    String? unitId,
    int? year,
    int? month,
    List<DailySchedule>? schedules,
    Map<String, dynamic>? statistics,
  }) {
    return MonthlyScheduleModel(
      unitId: unitId ?? this.unitId,
      year: year ?? this.year,
      month: month ?? this.month,
      schedules: schedules?.cast<DailyScheduleModel>() ?? this.schedules,
      statistics: statistics ?? this.statistics,
    );
  }

  /// الحصول على إحصائية معينة
  T? getStatistic<T>(String key) {
    if (statistics == null) return null;
    return statistics![key] as T?;
  }

  /// الحصول على عدد الأيام المتاحة
  int get availableDays => getStatistic<int>('availableDays') ?? 0;

  /// الحصول على عدد الأيام المحجوزة
  int get bookedDays => getStatistic<int>('bookedDays') ?? 0;

  /// الحصول على عدد الأيام المحظورة
  int get blockedDays => getStatistic<int>('blockedDays') ?? 0;

  /// الحصول على عدد الأيام في الصيانة
  int get maintenanceDays => getStatistic<int>('maintenanceDays') ?? 0;

  /// الحصول على عدد الأيام غير المتاحة
  int get unavailableDays => getStatistic<int>('unavailableDays') ?? 0;

  /// الحصول على إجمالي الإيرادات
  double get totalRevenue => getStatistic<double>('totalRevenue') ?? 0.0;

  /// الحصول على متوسط السعر
  double get averagePrice => getStatistic<double>('averagePrice') ?? 0.0;

  /// الحصول على نسبة الإشغال
  double get occupancyRate => getStatistic<double>('occupancyRate') ?? 0.0;
}
