import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/schedule_params.dart';
import '../repositories/daily_schedule_repository.dart';

/// Use case للتحديث الجماعي
///
/// ملاحظة مهمة:
/// لا يوجد حالياً endpoint حقيقي باسم /schedule/bulk في الباك-إند،
/// لذلك يتم تنفيذ "التحديث الجماعي" هنا عن طريق تفكيك الفترة إلى أيام
/// واستدعاء تحديث الإتاحة/التسعير لكل يوم على حدة، مع احترام أيام الأسبوع المحددة.
class BulkUpdateScheduleUseCase
    implements UseCase<int, BulkUpdateScheduleParams> {
  final DailyScheduleRepository repository;

  BulkUpdateScheduleUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(BulkUpdateScheduleParams params) async {
    final bool isAvailabilityUpdate = params.status != null;
    final bool isPricingUpdate = params.priceAmount != null;

    if (!isAvailabilityUpdate && !isPricingUpdate) {
      return Left(ValidationFailure(
          'يجب تحديد بيانات للتحديث (إتاحة أو تسعير على الأقل)'));
    }

    // توليد جميع الأيام بين البداية والنهاية (شاملة)
    final List<DateTime> days = [];
    DateTime current = DateTime(
        params.startDate.year, params.startDate.month, params.startDate.day);
    final DateTime end =
        DateTime(params.endDate.year, params.endDate.month, params.endDate.day);

    while (!current.isAfter(end)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }

    final List<int>? weekdays = params.weekdays;
    final bool filterByWeekdays = weekdays != null && weekdays.isNotEmpty;

    int totalAffected = 0;

    for (final day in days) {
      // إذا تم تحديد أيام أسبوع معينة، نتجاهل الأيام غير المطابقة
      if (filterByWeekdays && !weekdays!.contains(day.weekday)) {
        continue;
      }

      final dayParams = UpdateScheduleParams(
        unitId: params.unitId,
        startDate: day,
        endDate: day,
        status: params.status,
        reason: params.reason,
        notes: params.notes,
        priceAmount: params.priceAmount,
        currency: params.currency,
        priceType: params.priceType,
        pricingTier: params.pricingTier,
        overwriteExisting: params.overwriteExisting,
      );

      late final Either<Failure, int> dayResult;

      if (isAvailabilityUpdate && isPricingUpdate) {
        // لا يوجد endpoint موحد في الباك-إند لتحديث الإتاحة والتسعير معاً
        // لذلك ننفذ نداءين متتاليين لكل يوم: الإتاحة ثم التسعير
        final availabilityResult = await repository.updateAvailability(
          unitId: params.unitId,
          params: dayParams,
        );

        if (availabilityResult.isLeft()) {
          return availabilityResult;
        }

        final pricingResult = await repository.updatePricing(
          unitId: params.unitId,
          params: dayParams,
        );

        if (pricingResult.isLeft()) {
          return pricingResult;
        }

        final combinedAffected = availabilityResult.fold((_) => 0, (v) => v) +
            pricingResult.fold((_) => 0, (v) => v);

        dayResult = Right(combinedAffected.toInt());
      } else if (isAvailabilityUpdate) {
        dayResult = await repository.updateAvailability(
          unitId: params.unitId,
          params: dayParams,
        );
      } else {
        // isPricingUpdate فقط
        dayResult = await repository.updatePricing(
          unitId: params.unitId,
          params: dayParams,
        );
      }

      // في حال فشل أي يوم، نعيد الفشل مباشرةً
      if (dayResult.isLeft()) {
        return dayResult;
      }

      dayResult.fold((_) {}, (affected) {
        totalAffected += affected;
      });
    }

    return Right(totalAffected);
  }
}
