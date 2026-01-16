import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/daily_schedule.dart';
import '../../domain/entities/monthly_schedule.dart';
import '../../domain/repositories/daily_schedule_repository.dart';
import '../../domain/entities/schedule_params.dart';



import '../datasources/daily_schedule_remote_datasource.dart';
import '../models/daily_schedule_model.dart';
import '../models/monthly_schedule_model.dart';

/// تطبيق Repository للجدول اليومي
/// يربط بين Domain layer و Data layer
/// يتعامل مع الأخطاء ويحولها إلى Failures
class DailyScheduleRepositoryImpl implements DailyScheduleRepository {
  final DailyScheduleRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  DailyScheduleRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, MonthlySchedule>> getMonthlySchedule({
    required String unitId,
    required int year,
    required int month,
  }) async {
    // التحقق من وجود اتصال بالإنترنت
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      // الحصول على البيانات من Remote DataSource
      final result = await remoteDataSource.getMonthlySchedule(
        unitId: unitId,
        year: year,
        month: month,
      );

      // Debug: تتبع نتيجة الـ Repository
      // ignore: avoid_print
      print('[DailyScheduleRepository] getMonthlySchedule success: '
          'unit=$unitId, year=$year, month=$month, '
          'days=${result.schedules.length}');

      // إرجاع النتيجة كـ Entity
      return Right(result);
    } on ServerException catch (e) {
      // Debug: فشل من السيرفر
      // ignore: avoid_print
      print('[DailyScheduleRepository] getMonthlySchedule ServerException: '
          '${e.message}');
      // تحويل ServerException إلى ServerFailure
      return Left(ServerFailure(e.message));
    } catch (e) {
      // Debug: فشل غير متوقع
      // ignore: avoid_print
      print('[DailyScheduleRepository] getMonthlySchedule Unknown error: '
          '${e.toString()}');
      // تحويل أي Exception آخر إلى UnknownFailure
      return Left(UnknownFailure('حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<DailySchedule>>> getScheduleForPeriod({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // التحقق من وجود اتصال بالإنترنت
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      // الحصول على البيانات من Remote DataSource
      final result = await remoteDataSource.getScheduleForPeriod(
        unitId: unitId,
        startDate: startDate,
        endDate: endDate,
      );

      // إرجاع النتيجة كـ List<Entity>
      return Right(result);
    } on ServerException catch (e) {
      // تحويل ServerException إلى ServerFailure
      return Left(ServerFailure(e.message));
    } catch (e) {
      // تحويل أي Exception آخر إلى UnknownFailure
      return Left(UnknownFailure('حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, DailySchedule?>> getScheduleForDate({
    required String unitId,
    required DateTime date,
  }) async {
    // التحقق من وجود اتصال بالإنترنت
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      // الحصول على البيانات من Remote DataSource
      final result = await remoteDataSource.getScheduleForDate(
        unitId: unitId,
        date: date,
      );

      // إرجاع النتيجة كـ Entity أو null
      return Right(result);
    } on ServerException catch (e) {
      // تحويل ServerException إلى ServerFailure
      return Left(ServerFailure(e.message));
    } catch (e) {
      // تحويل أي Exception آخر إلى UnknownFailure
      return Left(UnknownFailure('حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> updateAvailability({
    required String unitId,
    required UpdateScheduleParams params,
  }) async {
    // التحقق من وجود اتصال بالإنترنت
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      // تنفيذ التحديث من خلال Remote DataSource
      final result = await remoteDataSource.updateAvailability(
        unitId: unitId,
        params: params,
      );

      // إرجاع عدد السجلات المتأثرة
      return Right(result);
    } on ServerException catch (e) {
      // تحويل ServerException إلى ServerFailure
      return Left(ServerFailure(e.message));
    } catch (e) {
      // تحويل أي Exception آخر إلى UnknownFailure
      return Left(UnknownFailure('حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> updatePricing({
    required String unitId,
    required UpdateScheduleParams params,
  }) async {
    // التحقق من وجود اتصال بالإنترنت
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      // تنفيذ التحديث من خلال Remote DataSource
      final result = await remoteDataSource.updatePricing(
        unitId: unitId,
        params: params,
      );

      // إرجاع عدد السجلات المتأثرة
      return Right(result);
    } on ServerException catch (e) {
      // تحويل ServerException إلى ServerFailure
      return Left(ServerFailure(e.message));
    } catch (e) {
      // تحويل أي Exception آخر إلى UnknownFailure
      return Left(UnknownFailure('حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> updateSchedule({
    required String unitId,
    required UpdateScheduleParams params,
  }) async {
    // التحقق من وجود اتصال بالإنترنت
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      // تنفيذ التحديث من خلال Remote DataSource
      final result = await remoteDataSource.updateSchedule(
        unitId: unitId,
        params: params,
      );

      // إرجاع عدد السجلات المتأثرة
      return Right(result);
    } on ServerException catch (e) {
      // تحويل ServerException إلى ServerFailure
      return Left(ServerFailure(e.message));
    } catch (e) {
      // تحويل أي Exception آخر إلى UnknownFailure
      return Left(UnknownFailure('حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> bulkUpdateSchedule({
    required String unitId,
    required BulkUpdateScheduleParams params,
  }) async {
    // التحقق من وجود اتصال بالإنترنت
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      // تنفيذ التحديث الجماعي من خلال Remote DataSource
      final result = await remoteDataSource.bulkUpdateSchedule(
        unitId: unitId,
        params: params,
      );

      // إرجاع عدد السجلات المتأثرة
      return Right(result);
    } on ServerException catch (e) {
      // تحويل ServerException إلى ServerFailure
      return Left(ServerFailure(e.message));
    } catch (e) {
      // تحويل أي Exception آخر إلى UnknownFailure
      return Left(UnknownFailure('حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, CheckAvailabilityResponse>> checkAvailability({
    required String unitId,
    required CheckAvailabilityParams params,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      final result = await remoteDataSource.checkAvailability(
        unitId: unitId,
        params: params,
      );

      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure('حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, double>> calculateTotalPrice({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
    String? currency,
  }) async {
    // التحقق من وجود اتصال بالإنترنت
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      // حساب السعر الإجمالي من خلال Remote DataSource
      final result = await remoteDataSource.calculateTotalPrice(
        unitId: unitId,
        startDate: startDate,
        endDate: endDate,
        currency: currency,
      );

      // إرجاع السعر الإجمالي
      return Right(result);
    } on ServerException catch (e) {
      // تحويل ServerException إلى ServerFailure
      return Left(ServerFailure(e.message));
    } catch (e) {
      // تحويل أي Exception آخر إلى UnknownFailure
      return Left(UnknownFailure('حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> cloneSchedule({
    required String unitId,
    required DateTime sourceStartDate,
    required DateTime sourceEndDate,
    required DateTime targetStartDate,
    bool overwrite = false,
  }) async {
    // التحقق من وجود اتصال بالإنترنت
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      // نسخ الجدول من خلال Remote DataSource
      final result = await remoteDataSource.cloneSchedule(
        unitId: unitId,
        sourceStartDate: sourceStartDate,
        sourceEndDate: sourceEndDate,
        targetStartDate: targetStartDate,
        overwrite: overwrite,
      );

      // إرجاع عدد السجلات المنسوخة
      return Right(result);
    } on ServerException catch (e) {
      // تحويل ServerException إلى ServerFailure
      return Left(ServerFailure(e.message));
    } catch (e) {
      // تحويل أي Exception آخر إلى UnknownFailure
      return Left(UnknownFailure('حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> deleteSchedule({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
    bool forceDelete = false,
  }) async {
    // التحقق من وجود اتصال بالإنترنت
    if (!await networkInfo.isConnected) {
      return Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }

    try {
      // حذف الجدول من خلال Remote DataSource
      final result = await remoteDataSource.deleteSchedule(
        unitId: unitId,
        startDate: startDate,
        endDate: endDate,
      );

      // إرجاع عدد السجلات المحذوفة
      return Right(result);
    } on ServerException catch (e) {
      // تحويل ServerException إلى ServerFailure
      return Left(ServerFailure(e.message));
    } catch (e) {
      // تحويل أي Exception آخر إلى UnknownFailure
      return Left(UnknownFailure('حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> exportSchedule({
    required String unitId,
    required int year,
    int? month,
  }) async {
    // TODO: Implement export functionality
    return Left(ServerFailure('وظيفة التصدير قيد التطوير'));
  }

  @override
  Future<Either<Failure, int>> importSchedule({
    required String filePath,
    required String unitId,
    bool overwriteExisting = false,
  }) async {
    // TODO: Implement import functionality
    return Left(ServerFailure('وظيفة الاستيراد قيد التطوير'));
  }
}
