import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../models/monthly_schedule_model.dart';
import '../models/daily_schedule_model.dart';
import '../models/schedule_params_model.dart';
import '../../domain/entities/schedule_params.dart';
import 'daily_schedule_remote_datasource.dart';

/// تطبيق مصدر البيانات البعيد للجدول اليومي
/// يستخدم Dio للتواصل مع Backend API
class DailyScheduleRemoteDataSourceImpl
    implements DailyScheduleRemoteDataSource {
  final Dio dio;
  static const String baseUrl = '/api/admin/units';

  DailyScheduleRemoteDataSourceImpl({required this.dio});

  @override
  Future<MonthlyScheduleModel> getMonthlySchedule({
    required String unitId,
    required int year,
    required int month,
  }) async {
    try {
      // إنشاء URL: GET /api/admin/units/{unitId}/schedule/month/{year}/{month}
      final url = '$baseUrl/$unitId/schedule/month/$year/$month';

      // إرسال الطلب
      final response = await dio.get(url);

      // Debug: تتبع استجابة الجدول الشهري من الباك-إند
      // ignore: avoid_print
      print('[DailyScheduleRemoteDataSource] GET '+url+
          ' -> status=${response.statusCode}, type=${response.data.runtimeType}');

      // التحقق من نجاح الطلب
      if (response.statusCode == 200) {
        final raw = response.data;

        // ✅ الشكل الحالي من الباك-إند: ResultDto { success, data, errors, message }
        if (raw is Map<String, dynamic> && raw.containsKey('data')) {
          final List<dynamic> dataList = (raw['data'] as List<dynamic>? ) ?? [];
          // ignore: avoid_print
          print('[DailyScheduleRemoteDataSource] dataList length = '
              '${dataList.length}');

          final schedules = dataList.map((e) {
            final map = Map<String, dynamic>.from(e as Map);

            // ✅ تطبيع المفاتيح من camelCase إلى PascalCase بما يتوافق مع DailyScheduleModel.fromJson
            final normalized = <String, dynamic>{
              'Id': map['id'],
              'UnitId': map['unitId'],
              'Date': map['date'],
              'Status': map['status'],
              'Reason': map['reason'],
              'Notes': map['notes'],
              'BookingId': map['bookingId'],
              'PriceAmount': map['priceAmount'],
              'Currency': map['currency'],
              'PriceType': map['priceType'],
              'PricingTier': map['pricingTier'],
              'PercentageChange': map['percentageChange'],
              'MinPrice': map['minPrice'],
              'MaxPrice': map['maxPrice'],
              'StartTime': map['startTime'],
              'EndTime': map['endTime'],
              'CreatedAt': map['createdAt'],
              'UpdatedAt': map['updatedAt'],
              'CreatedBy': map['createdBy'],
              'ModifiedBy': map['modifiedBy'],
            };

            return DailyScheduleModel.fromJson(normalized);
          }).toList();

          // ignore: avoid_print
          print('[DailyScheduleRemoteDataSource] schedules length = '
              '${schedules.length}');

          final derivedUnitId = schedules.isNotEmpty
              ? schedules.first.unitId
              : unitId;

          return MonthlyScheduleModel(
            unitId: derivedUnitId,
            year: year,
            month: month,
            schedules: schedules,
            // يمكن لاحقًا احتساب الإحصائيات هنا إذا لزم الأمر
            statistics: null,
          );
        }

        // ✅ دعم شكل قديم/مستقبلي: JSON مباشر لـ MonthlyScheduleModel
        if (raw is Map<String, dynamic>) {
          return MonthlyScheduleModel.fromJson(raw);
        }

        throw ServerException(
          'صيغة استجابة غير متوقعة للجدول الشهري',
        );
      } else {
        throw ServerException(
          'فشل في الحصول على الجدول الشهري',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'فشل في الحصول على الجدول الشهري');
    } catch (e) {
      throw ServerException(
        'خطأ غير متوقع: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<DailyScheduleModel>> getScheduleForPeriod({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // إنشاء URL: GET /api/admin/units/{unitId}/schedule?startDate=...&endDate=...
      final url = '$baseUrl/$unitId/schedule';
      final queryParams = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };

      // إرسال الطلب
      final response = await dio.get(url, queryParameters: queryParams);

      // التحقق من نجاح الطلب
      if (response.statusCode == 200) {
        final raw = response.data;

        // ✅ الشكل الحالي: ResultDto { success, data, errors, message }
        if (raw is Map<String, dynamic> && raw.containsKey('data')) {
          final List<dynamic> dataList = (raw['data'] as List<dynamic>? ) ?? [];
          return dataList.map((e) {
            final map = Map<String, dynamic>.from(e as Map);
            final normalized = <String, dynamic>{
              'Id': map['id'],
              'UnitId': map['unitId'],
              'Date': map['date'],
              'Status': map['status'],
              'Reason': map['reason'],
              'Notes': map['notes'],
              'BookingId': map['bookingId'],
              'PriceAmount': map['priceAmount'],
              'Currency': map['currency'],
              'PriceType': map['priceType'],
              'PricingTier': map['pricingTier'],
              'PercentageChange': map['percentageChange'],
              'MinPrice': map['minPrice'],
              'MaxPrice': map['maxPrice'],
              'StartTime': map['startTime'],
              'EndTime': map['endTime'],
              'CreatedAt': map['createdAt'],
              'UpdatedAt': map['updatedAt'],
              'CreatedBy': map['createdBy'],
              'ModifiedBy': map['modifiedBy'],
            };

            return DailyScheduleModel.fromJson(normalized);
          }).toList();
        }

        // ✅ دعم شكل قديم: قائمة مباشرة من السجلات
        if (raw is List) {
          return raw.map((e) {
            final map = Map<String, dynamic>.from(e as Map);
            final normalized = <String, dynamic>{
              'Id': map['id'],
              'UnitId': map['unitId'],
              'Date': map['date'],
              'Status': map['status'],
              'Reason': map['reason'],
              'Notes': map['notes'],
              'BookingId': map['bookingId'],
              'PriceAmount': map['priceAmount'],
              'Currency': map['currency'],
              'PriceType': map['priceType'],
              'PricingTier': map['pricingTier'],
              'PercentageChange': map['percentageChange'],
              'MinPrice': map['minPrice'],
              'MaxPrice': map['maxPrice'],
              'StartTime': map['startTime'],
              'EndTime': map['endTime'],
              'CreatedAt': map['createdAt'],
              'UpdatedAt': map['updatedAt'],
              'CreatedBy': map['createdBy'],
              'ModifiedBy': map['modifiedBy'],
            };

            return DailyScheduleModel.fromJson(normalized);
          }).toList();
        }

        throw ServerException(
          'فشل في الحصول على جدول الفترة: صيغة استجابة غير متوقعة',
        );
      } else {
        throw ServerException(
          'فشل في الحصول على جدول الفترة',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'فشل في الحصول على جدول الفترة');
    } catch (e) {
      throw ServerException(
        'خطأ غير متوقع: ${e.toString()}',
      );
    }
  }

  @override
  Future<DailyScheduleModel?> getScheduleForDate({
    required String unitId,
    required DateTime date,
  }) async {
    try {
      // استخدام getScheduleForPeriod للحصول على يوم واحد
      final schedules = await getScheduleForPeriod(
        unitId: unitId,
        startDate: date,
        endDate: date,
      );

      // إرجاع أول عنصر أو null
      return schedules.isNotEmpty ? schedules.first : null;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<int> updateAvailability({
    required String unitId,
    required UpdateScheduleParams params,
  }) async {
    try {
      // إنشاء URL: POST /api/admin/units/{unitId}/schedule/availability
      final url = '$baseUrl/$unitId/schedule/availability';

      // تحويل البارامترات إلى JSON
      final requestModel = UpdateScheduleRequestModel.fromParams(params);
      final data = requestModel.toJson();

      // إرسال الطلب
      final response = await dio.post(url, data: data);

      // التحقق من نجاح الطلب
      if (response.statusCode == 200 || response.statusCode == 204) {
        // إرجاع عدد السجلات المتأثرة (افتراضياً 1)
        return response.data is int ? response.data as int : 1;
      } else {
        throw ServerException(
          'فشل في تحديث التوافر',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'فشل في تحديث التوافر');
    } catch (e) {
      throw ServerException(
        'خطأ غير متوقع: ${e.toString()}',
      );
    }
  }

  @override
  Future<int> updatePricing({
    required String unitId,
    required UpdateScheduleParams params,
  }) async {
    try {
      // إنشاء URL: POST /api/admin/units/{unitId}/schedule/pricing
      final url = '$baseUrl/$unitId/schedule/pricing';

      // تحويل البارامترات إلى JSON
      final requestModel = UpdateScheduleRequestModel.fromParams(params);
      final data = requestModel.toJson();

      // إرسال الطلب
      final response = await dio.post(url, data: data);

      // التحقق من نجاح الطلب
      if (response.statusCode == 200 || response.statusCode == 204) {
        // إرجاع عدد السجلات المتأثرة (افتراضياً 1)
        return response.data is int ? response.data as int : 1;
      } else {
        throw ServerException(
          'فشل في تحديث التسعير',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'فشل في تحديث التسعير');
    } catch (e) {
      throw ServerException(
        'خطأ غير متوقع: ${e.toString()}',
      );
    }
  }

  @override
  Future<int> updateSchedule({
    required String unitId,
    required UpdateScheduleParams params,
  }) async {
    try {
      // إنشاء URL: POST /api/admin/units/{unitId}/schedule
      final url = '$baseUrl/$unitId/schedule';

      // تحويل البارامترات إلى JSON
      final requestModel = UpdateScheduleRequestModel.fromParams(params);
      final data = requestModel.toJson();

      // إرسال الطلب
      final response = await dio.post(url, data: data);

      // التحقق من نجاح الطلب
      if (response.statusCode == 200 || response.statusCode == 204) {
        // إرجاع عدد السجلات المتأثرة (افتراضياً 1)
        return response.data is int ? response.data as int : 1;
      } else {
        throw ServerException(
          'فشل في تحديث الجدول',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'فشل في تحديث الجدول');
    } catch (e) {
      throw ServerException(
        'خطأ غير متوقع: ${e.toString()}',
      );
    }
  }

  @override
  Future<int> bulkUpdateSchedule({
    required String unitId,
    required BulkUpdateScheduleParams params,
  }) async {
    try {
      // إنشاء URL: POST /api/admin/units/{unitId}/schedule/bulk
      final url = '$baseUrl/$unitId/schedule/bulk';

      // تحويل البارامترات إلى JSON
      final requestModel = BulkUpdateScheduleRequestModel.fromParams(params);
      final data = requestModel.toJson();

      // إرسال الطلب
      final response = await dio.post(url, data: data);

      // التحقق من نجاح الطلب
      if (response.statusCode == 200 || response.statusCode == 204) {
        // إرجاع عدد السجلات المتأثرة
        return response.data is int ? response.data as int : 0;
      } else {
        throw ServerException(
          'فشل في التحديث الجماعي للجدول',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'فشل في التحديث الجماعي للجدول');
    } catch (e) {
      throw ServerException(
        'خطأ غير متوقع: ${e.toString()}',
      );
    }
  }

  @override
  Future<CheckAvailabilityResponseModel> checkAvailability({
    required String unitId,
    required CheckAvailabilityParams params,
  }) async {
    try {
      // إنشاء URL: GET /api/admin/units/{unitId}/schedule/availability/check
      final url = '$baseUrl/$unitId/schedule/availability/check';

      // تحويل البارامترات إلى Query Parameters
      final requestModel = CheckAvailabilityRequestModel.fromParams(params);
      final queryParams = requestModel.toQueryParams();

      // إرسال الطلب
      final response = await dio.get(url, queryParameters: queryParams);

      // التحقق من نجاح الطلب
      if (response.statusCode == 200) {
        // تحويل الاستجابة إلى Model
        return CheckAvailabilityResponseModel.fromJson(
            response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          'فشل في التحقق من التوافر',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'فشل في التحقق من التوافر');
    } catch (e) {
      throw ServerException(
        'خطأ غير متوقع: ${e.toString()}',
      );
    }
  }

  @override
  Future<double> calculateTotalPrice({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
    String? currency,
  }) async {
    try {
      // إنشاء URL: POST /api/admin/units/{unitId}/schedule/pricing/calculate
      final url = '$baseUrl/$unitId/schedule/pricing/calculate';

      // تحويل البارامترات إلى JSON
      final requestModel = CalculateTotalPriceRequestModel(
        startDate: startDate,
        endDate: endDate,
        currency: currency,
      );
      final data = requestModel.toJson();

      // إرسال الطلب
      final response = await dio.post(url, data: data);

      // التحقق من نجاح الطلب
      if (response.statusCode == 200) {
        // تحويل الاستجابة إلى Model
        final responseModel = CalculateTotalPriceResponseModel.fromJson(
            response.data as Map<String, dynamic>);
        return responseModel.totalPrice;
      } else {
        throw ServerException(
          'فشل في حساب السعر الإجمالي',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'فشل في حساب السعر الإجمالي');
    } catch (e) {
      throw ServerException(
        'خطأ غير متوقع: ${e.toString()}',
      );
    }
  }

  @override
  Future<int> cloneSchedule({
    required String unitId,
    required DateTime sourceStartDate,
    required DateTime sourceEndDate,
    required DateTime targetStartDate,
    bool overwrite = false,
  }) async {
    try {
      // إنشاء URL: POST /api/admin/units/{unitId}/schedule/clone
      final url = '$baseUrl/$unitId/schedule/clone';

      // تحضير البيانات
      final data = {
        'SourceStartDate': sourceStartDate.toIso8601String(),
        'SourceEndDate': sourceEndDate.toIso8601String(),
        'TargetStartDate': targetStartDate.toIso8601String(),
        'Overwrite': overwrite,
      };

      // إرسال الطلب
      final response = await dio.post(url, data: data);

      // التحقق من نجاح الطلب
      if (response.statusCode == 200) {
        final raw = response.data;

        // الشكل الحالي: ResultDto { success, data, message, errors }
        if (raw is Map<String, dynamic>) {
          final success = raw['success'] ?? raw['succeeded'] ?? false;
          if (success == true) {
            final dataValue = raw['data'];
            if (dataValue is int) return dataValue;
            if (dataValue is num) return dataValue.toInt();
            return 0;
          } else {
            final message = raw['message']?.toString() ?? 'فشل في نسخ الجدول';
            throw ServerException(message);
          }
        }

        // دعم شكل قديم: int مباشر
        if (raw is int) {
          return raw;
        }

        throw ServerException('فشل في نسخ الجدول: صيغة استجابة غير متوقعة');
      } else {
        throw ServerException(
          'فشل في نسخ الجدول',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'فشل في نسخ الجدول');
    } catch (e) {
      throw ServerException(
        'خطأ غير متوقع: ${e.toString()}',
      );
    }
  }

  @override
  Future<int> deleteSchedule({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // إنشاء URL: DELETE /api/admin/units/{unitId}/schedule
      final url = '$baseUrl/$unitId/schedule';

      // تحضير Query Parameters
      final queryParams = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };

      // إرسال الطلب
      final response = await dio.delete(url, queryParameters: queryParams);

      // التحقق من نجاح الطلب
      if (response.statusCode == 200 || response.statusCode == 204) {
        // إرجاع عدد السجلات المحذوفة
        return response.data is int ? response.data as int : 0;
      } else {
        throw ServerException(
          'فشل في حذف الجدول',
        );
      }
    } on DioException catch (e) {
      throw _handleDioException(e, 'فشل في حذف الجدول');
    } catch (e) {
      throw ServerException(
        'خطأ غير متوقع: ${e.toString()}',
      );
    }
  }

  /// معالجة أخطاء Dio وتحويلها إلى ServerException
  ServerException _handleDioException(DioException e, String defaultMessage) {
    if (e.response != null) {
      // الخطأ من Server
      final statusCode = e.response!.statusCode;
      String message = defaultMessage;

      // محاولة استخراج رسالة الخطأ من الاستجابة
      try {
        if (e.response!.data is Map) {
          final data = e.response!.data as Map<String, dynamic>;
          message = data['message'] ?? data['error'] ?? data['title'] ?? defaultMessage;
        } else if (e.response!.data is String) {
          message = e.response!.data as String;
        }
      } catch (_) {
        // تجاهل أخطاء استخراج الرسالة
      }

      return ServerException(
        message,
      );
    } else {
      // خطأ في الاتصال
      String message;
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'انتهت مهلة الاتصال بالسيرفر';
          break;
        case DioExceptionType.connectionError:
          message = 'فشل الاتصال بالسيرفر';
          break;
        case DioExceptionType.cancel:
          message = 'تم إلغاء الطلب';
          break;
        default:
          message = defaultMessage;
      }

      return ServerException(message);
    }
  }
}
