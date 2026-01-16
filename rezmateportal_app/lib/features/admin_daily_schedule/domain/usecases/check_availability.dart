import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/schedule_params.dart';
import '../repositories/daily_schedule_repository.dart';

/// Use case للتحقق من التوفر
class CheckAvailabilityUseCase
    implements UseCase<CheckAvailabilityResponse, CheckAvailabilityParams> {
  final DailyScheduleRepository repository;

  CheckAvailabilityUseCase(this.repository);

  @override
  Future<Either<Failure, CheckAvailabilityResponse>> call(
    CheckAvailabilityParams params,
  ) async {
    if (params.checkInDate.isAfter(params.checkOutDate)) {
      return Left(
        ValidationFailure('تاريخ الدخول يجب أن يكون قبل تاريخ الخروج'),
      );
    }

    if (params.checkInDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return Left(
        ValidationFailure('لا يمكن التحقق من تاريخ في الماضي'),
      );
    }

    return await repository.checkAvailability(
      unitId: params.unitId,
      params: params,
    );
  }
}
