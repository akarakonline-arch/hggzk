import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/daily_schedule_repository.dart';

/// معاملات حذف الجدول
class DeleteScheduleParams {
  final String unitId;
  final DateTime startDate;
  final DateTime endDate;
  final bool forceDelete;

  const DeleteScheduleParams({
    required this.unitId,
    required this.startDate,
    required this.endDate,
    this.forceDelete = false,
  });
}

/// Use case لحذف الجدول
class DeleteScheduleUseCase implements UseCase<int, DeleteScheduleParams> {
  final DailyScheduleRepository repository;

  DeleteScheduleUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(DeleteScheduleParams params) async {
    if (params.startDate.isAfter(params.endDate)) {
      return Left(
        ValidationFailure('تاريخ البداية يجب أن يكون قبل تاريخ النهاية'),
      );
    }

    return await repository.deleteSchedule(
      unitId: params.unitId,
      startDate: params.startDate,
      endDate: params.endDate,
      forceDelete: params.forceDelete,
    );
  }
}
