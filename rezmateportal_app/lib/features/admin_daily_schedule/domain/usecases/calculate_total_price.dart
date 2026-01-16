import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/daily_schedule_repository.dart';

/// معاملات حساب السعر الإجمالي
class CalculateTotalPriceParams {
  final String unitId;
  final DateTime startDate;
  final DateTime endDate;

  const CalculateTotalPriceParams({
    required this.unitId,
    required this.startDate,
    required this.endDate,
  });
}

/// Use case لحساب السعر الإجمالي
class CalculateTotalPriceUseCase
    implements UseCase<double, CalculateTotalPriceParams> {
  final DailyScheduleRepository repository;

  CalculateTotalPriceUseCase(this.repository);

  @override
  Future<Either<Failure, double>> call(
    CalculateTotalPriceParams params,
  ) async {
    if (params.startDate.isAfter(params.endDate)) {
      return Left(
        ValidationFailure('تاريخ البداية يجب أن يكون قبل تاريخ النهاية'),
      );
    }

    return await repository.calculateTotalPrice(
      unitId: params.unitId,
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}
