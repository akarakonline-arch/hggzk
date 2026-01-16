import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/monthly_schedule.dart';
import '../repositories/daily_schedule_repository.dart';

/// معاملات الحصول على الجدول الشهري
class GetMonthlyScheduleParams {
  final String unitId;
  final int year;
  final int month;

  const GetMonthlyScheduleParams({
    required this.unitId,
    required this.year,
    required this.month,
  });
}

/// Use case للحصول على الجدول الشهري
class GetMonthlyScheduleUseCase
    implements UseCase<MonthlySchedule, GetMonthlyScheduleParams> {
  final DailyScheduleRepository repository;

  GetMonthlyScheduleUseCase(this.repository);

  @override
  Future<Either<Failure, MonthlySchedule>> call(
    GetMonthlyScheduleParams params,
  ) async {
    return await repository.getMonthlySchedule(
      unitId: params.unitId,
      year: params.year,
      month: params.month,
    );
  }
}
