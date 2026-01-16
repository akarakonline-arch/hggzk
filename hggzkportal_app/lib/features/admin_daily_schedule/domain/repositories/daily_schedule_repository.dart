import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/daily_schedule.dart';
import '../entities/monthly_schedule.dart';
import '../entities/schedule_params.dart';

/// واجهة مستودع الجدول اليومي
/// تحدد العمليات المتاحة للتعامل مع بيانات الجدول اليومي
abstract class DailyScheduleRepository {
  /// الحصول على الجدول الشهري لوحدة معينة
  ///
  /// [unitId] معرّف الوحدة
  /// [year] السنة
  /// [month] الشهر (1-12)
  ///
  /// Returns: Either<Failure, MonthlySchedule>
  Future<Either<Failure, MonthlySchedule>> getMonthlySchedule({
    required String unitId,
    required int year,
    required int month,
  });

  /// الحصول على الجدول لفترة محددة
  ///
  /// [unitId] معرّف الوحدة
  /// [startDate] تاريخ البداية
  /// [endDate] تاريخ النهاية
  ///
  /// Returns: Either<Failure, List<DailySchedule>>
  Future<Either<Failure, List<DailySchedule>>> getScheduleForPeriod({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// الحصول على جدول يوم واحد محدد
  ///
  /// [unitId] معرّف الوحدة
  /// [date] التاريخ
  ///
  /// Returns: Either<Failure, DailySchedule?>
  Future<Either<Failure, DailySchedule?>> getScheduleForDate({
    required String unitId,
    required DateTime date,
  });

  /// تحديث الإتاحة لفترة محددة
  ///
  /// [unitId] معرّف الوحدة
  /// [params] معاملات التحديث (يجب أن تحتوي على status)
  ///
  /// Returns: Either<Failure, int> عدد الأيام المحدثة
  Future<Either<Failure, int>> updateAvailability({
    required String unitId,
    required UpdateScheduleParams params,
  });

  /// تحديث التسعير لفترة محددة
  ///
  /// [unitId] معرّف الوحدة
  /// [params] معاملات التحديث (يجب أن تحتوي على priceAmount)
  ///
  /// Returns: Either<Failure, int> عدد الأيام المحدثة
  Future<Either<Failure, int>> updatePricing({
    required String unitId,
    required UpdateScheduleParams params,
  });

  /// تحديث الإتاحة والتسعير معاً لفترة محددة
  ///
  /// [unitId] معرّف الوحدة
  /// [params] معاملات التحديث
  ///
  /// Returns: Either<Failure, int> عدد الأيام المحدثة
  Future<Either<Failure, int>> updateSchedule({
    required String unitId,
    required UpdateScheduleParams params,
  });

  /// تحديث جماعي بناءً على أيام الأسبوع
  ///
  /// [unitId] معرّف الوحدة
  /// [params] معاملات التحديث الجماعي
  ///
  /// Returns: Either<Failure, int> عدد الأيام المحدثة
  Future<Either<Failure, int>> bulkUpdateSchedule({
    required String unitId,
    required BulkUpdateScheduleParams params,
  });

  /// التحقق من توفر الوحدة لفترة محددة
  ///
  /// [unitId] معرّف الوحدة
  /// [params] معاملات التحقق من التوفر
  ///
  /// Returns: Either<Failure, CheckAvailabilityResponse>
  Future<Either<Failure, CheckAvailabilityResponse>> checkAvailability({
    required String unitId,
    required CheckAvailabilityParams params,
  });

  /// حساب السعر الإجمالي لفترة محددة
  ///
  /// [unitId] معرّف الوحدة
  /// [startDate] تاريخ البداية
  /// [endDate] تاريخ النهاية
  ///
  /// Returns: Either<Failure, double> السعر الإجمالي
  Future<Either<Failure, double>> calculateTotalPrice({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// نسخ الجدول من فترة إلى فترة أخرى
  ///
  /// [unitId] معرّف الوحدة
  /// [sourceStartDate] تاريخ بداية الفترة المصدر
  /// [sourceEndDate] تاريخ نهاية الفترة المصدر
  /// [targetStartDate] تاريخ بداية الفترة الهدف
  ///
  /// Returns: Either<Failure, int> عدد الأيام المنسوخة
  Future<Either<Failure, int>> cloneSchedule({
    required String unitId,
    required DateTime sourceStartDate,
    required DateTime sourceEndDate,
    required DateTime targetStartDate,
    bool overwrite = false,
  });

  /// حذف الجدول لفترة محددة
  ///
  /// [unitId] معرّف الوحدة
  /// [startDate] تاريخ البداية
  /// [endDate] تاريخ النهاية
  /// [forceDelete] حذف حتى لو كانت الأيام محجوزة
  ///
  /// Returns: Either<Failure, int> عدد الأيام المحذوفة
  Future<Either<Failure, int>> deleteSchedule({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
    bool forceDelete = false,
  });

  /// تصدير بيانات الجدول
  ///
  /// [unitId] معرّف الوحدة
  /// [year] السنة
  /// [month] الشهر (اختياري - null يعني السنة كاملة)
  ///
  /// Returns: Either<Failure, String> مسار الملف المُصدَّر
  Future<Either<Failure, String>> exportSchedule({
    required String unitId,
    required int year,
    int? month,
  });

  /// استيراد بيانات الجدول
  ///
  /// [filePath] مسار الملف
  /// [unitId] معرّف الوحدة
  /// [overwriteExisting] الكتابة فوق البيانات الموجودة
  ///
  /// Returns: Either<Failure, int> عدد السجلات المستوردة
  Future<Either<Failure, int>> importSchedule({
    required String filePath,
    required String unitId,
    bool overwriteExisting = false,
  });
}
