import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/daily_schedule_repository.dart';

/// معاملات نسخ الجدول
class CloneScheduleParams {
  final String unitId;
  final DateTime sourceStartDate;
  final DateTime sourceEndDate;
  final DateTime targetStartDate;
  final bool overwrite;

  const CloneScheduleParams({
    required this.unitId,
    required this.sourceStartDate,
    required this.sourceEndDate,
    required this.targetStartDate,
    this.overwrite = false,
  });
}

/// Use case لنسخ الجدول
class CloneScheduleUseCase implements UseCase<int, CloneScheduleParams> {
  final DailyScheduleRepository repository;

  CloneScheduleUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(CloneScheduleParams params) async {
    if (params.sourceStartDate.isAfter(params.sourceEndDate)) {
      return Left(
        ValidationFailure('تاريخ بداية المصدر يجب أن يكون قبل تاريخ النهاية'),
      );
    }

    return await repository.cloneSchedule(
      unitId: params.unitId,
      sourceStartDate: params.sourceStartDate,
      sourceEndDate: params.sourceEndDate,
      targetStartDate: params.targetStartDate,
      overwrite: params.overwrite,
    );
  }
}
