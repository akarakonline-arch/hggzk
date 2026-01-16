import '../models/monthly_schedule_model.dart';
import '../models/daily_schedule_model.dart';
import '../models/schedule_params_model.dart';
import '../../domain/entities/schedule_params.dart';

/// مصدر البيانات البعيد للجدول اليومي - Abstract class
/// يحدد العمليات المطلوبة من API
abstract class DailyScheduleRemoteDataSource {
  /// الحصول على جدول شهري لوحدة معينة
  /// 
  /// Parameters:
  /// - [unitId]: معرف الوحدة
  /// - [year]: السنة
  /// - [month]: الشهر (1-12)
  /// 
  /// Returns: [MonthlyScheduleModel] يحتوي على جميع الأيام في الشهر
  /// 
  /// Throws: [ServerException] في حالة فشل الطلب
  Future<MonthlyScheduleModel> getMonthlySchedule({
    required String unitId,
    required int year,
    required int month,
  });

  /// الحصول على جدول فترة محددة
  /// 
  /// Parameters:
  /// - [unitId]: معرف الوحدة
  /// - [startDate]: تاريخ البداية
  /// - [endDate]: تاريخ النهاية
  /// 
  /// Returns: قائمة [DailyScheduleModel] للفترة المحددة
  /// 
  /// Throws: [ServerException] في حالة فشل الطلب
  Future<List<DailyScheduleModel>> getScheduleForPeriod({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// الحصول على جدول يوم محدد
  /// 
  /// Parameters:
  /// - [unitId]: معرف الوحدة
  /// - [date]: التاريخ المطلوب
  /// 
  /// Returns: [DailyScheduleModel] أو null إذا لم يكن موجوداً
  /// 
  /// Throws: [ServerException] في حالة فشل الطلب
  Future<DailyScheduleModel?> getScheduleForDate({
    required String unitId,
    required DateTime date,
  });

  /// تحديث التوافر ليوم محدد
  /// 
  /// Parameters:
  /// - [unitId]: معرف الوحدة
  /// - [params]: بارامترات التحديث
  /// 
  /// Returns: عدد السجلات المتأثرة (عادة 1)
  /// 
  /// Throws: [ServerException] في حالة فشل الطلب
  Future<int> updateAvailability({
    required String unitId,
    required UpdateScheduleParams params,
  });

  /// تحديث التسعير ليوم محدد
  /// 
  /// Parameters:
  /// - [unitId]: معرف الوحدة
  /// - [params]: بارامترات التحديث
  /// 
  /// Returns: عدد السجلات المتأثرة (عادة 1)
  /// 
  /// Throws: [ServerException] في حالة فشل الطلب
  Future<int> updatePricing({
    required String unitId,
    required UpdateScheduleParams params,
  });

  /// تحديث الجدول الكامل ليوم محدد (التوافر والتسعير معاً)
  /// 
  /// Parameters:
  /// - [unitId]: معرف الوحدة
  /// - [params]: بارامترات التحديث
  /// 
  /// Returns: عدد السجلات المتأثرة (عادة 1)
  /// 
  /// Throws: [ServerException] في حالة فشل الطلب
  Future<int> updateSchedule({
    required String unitId,
    required UpdateScheduleParams params,
  });

  /// تحديث جماعي للجدول لفترة محددة
  /// 
  /// Parameters:
  /// - [unitId]: معرف الوحدة
  /// - [params]: بارامترات التحديث الجماعي
  /// 
  /// Returns: عدد السجلات المتأثرة
  /// 
  /// Throws: [ServerException] في حالة فشل الطلب
  Future<int> bulkUpdateSchedule({
    required String unitId,
    required BulkUpdateScheduleParams params,
  });

  /// التحقق من التوافر لفترة محددة
  /// 
  /// Parameters:
  /// - [unitId]: معرف الوحدة
  /// - [params]: بارامترات التحقق
  /// 
  /// Returns: [CheckAvailabilityResponseModel] يحتوي على معلومات التوافر
  /// 
  /// Throws: [ServerException] في حالة فشل الطلب
  Future<CheckAvailabilityResponseModel> checkAvailability({
    required String unitId,
    required CheckAvailabilityParams params,
  });

  /// حساب السعر الإجمالي لفترة محددة
  /// 
  /// Parameters:
  /// - [unitId]: معرف الوحدة
  /// - [startDate]: تاريخ البداية
  /// - [endDate]: تاريخ النهاية
  /// - [currency]: العملة (اختياري)
  /// 
  /// Returns: السعر الإجمالي كـ double
  /// 
  /// Throws: [ServerException] في حالة فشل الطلب
  Future<double> calculateTotalPrice({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
    String? currency,
  });

  /// نسخ الجدول من فترة إلى فترة أخرى
  /// 
  /// Parameters:
  /// - [unitId]: معرف الوحدة
  /// - [sourceStartDate]: تاريخ بداية المصدر
  /// - [sourceEndDate]: تاريخ نهاية المصدر
  /// - [targetStartDate]: تاريخ بداية الهدف
  /// - [overwrite]: هل يتم الكتابة فوق البيانات الموجودة
  /// 
  /// Returns: عدد السجلات المنسوخة
  /// 
  /// Throws: [ServerException] في حالة فشل الطلب
  Future<int> cloneSchedule({
    required String unitId,
    required DateTime sourceStartDate,
    required DateTime sourceEndDate,
    required DateTime targetStartDate,
    bool overwrite = false,
  });

  /// حذف الجدول لفترة محددة
  /// 
  /// Parameters:
  /// - [unitId]: معرف الوحدة
  /// - [startDate]: تاريخ البداية
  /// - [endDate]: تاريخ النهاية
  /// 
  /// Returns: عدد السجلات المحذوفة
  /// 
  /// Throws: [ServerException] في حالة فشل الطلب
  Future<int> deleteSchedule({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
