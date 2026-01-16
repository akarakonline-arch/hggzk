import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/schedule_params.dart';
import '../repositories/daily_schedule_repository.dart';

/// Use case لتحديث الإتاحة والتسعير
class UpdateScheduleUseCase implements UseCase<int, UpdateScheduleParams> {
  final DailyScheduleRepository repository;

  UpdateScheduleUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(UpdateScheduleParams params) async {
    if (params.isAvailabilityUpdate && params.isPricingUpdate) {
      // لا يوجد endpoint موحد في الباك-إند لتحديث الإتاحة والتسعير معاً
      // لذلك ننفذ نداءين متتاليين: أولاً الإتاحة ثم التسعير
      final availabilityResult = await repository.updateAvailability(
        unitId: params.unitId,
        params: params,
      );

      if (availabilityResult.isLeft()) {
        return availabilityResult;
      }

      final pricingResult = await repository.updatePricing(
        unitId: params.unitId,
        params: params,
      );

      if (pricingResult.isLeft()) {
        return pricingResult;
      }

      final totalAffected = availabilityResult.fold((_) => 0, (v) => v) +
          pricingResult.fold((_) => 0, (v) => v);

      return Right(totalAffected.toInt());
    } else if (params.isAvailabilityUpdate) {
      return await repository.updateAvailability(
        unitId: params.unitId,
        params: params,
      );
    } else if (params.isPricingUpdate) {
      return await repository.updatePricing(
        unitId: params.unitId,
        params: params,
      );
    } else {
      return Left(ValidationFailure('يجب تحديد بيانات للتحديث'));
    }
  }
}
