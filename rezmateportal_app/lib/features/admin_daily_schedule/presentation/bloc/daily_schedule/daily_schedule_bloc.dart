// lib/features/admin_daily_schedule/presentation/bloc/daily_schedule/daily_schedule_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/entities/daily_schedule.dart';
import '../../../domain/entities/monthly_schedule.dart';
import '../../../domain/entities/schedule_params.dart';
import '../../../domain/usecases/get_monthly_schedule.dart';
import '../../../domain/usecases/update_schedule.dart';
import '../../../domain/usecases/bulk_update_schedule.dart';
import '../../../domain/usecases/check_availability.dart';
import '../../../domain/usecases/calculate_total_price.dart';
import '../../../domain/usecases/clone_schedule.dart';
import '../../../domain/usecases/delete_schedule.dart';
import '../../../../../core/error/failures.dart';

part 'daily_schedule_event.dart';
part 'daily_schedule_state.dart';

/// BLoC لإدارة الجدول اليومي الموحد (الإتاحة والتسعير)
/// 
/// يتعامل مع جميع العمليات المتعلقة بالجدول اليومي:
/// - تحميل الجدول الشهري
/// - تحديث يوم واحد أو فترة
/// - التحديث الجماعي بناءً على أيام الأسبوع
/// - التحقق من التوفر
/// - حساب السعر الإجمالي
/// - نسخ وحذف الجداول
/// - التصفية والتنقل بين الأشهر
class DailyScheduleBloc extends Bloc<DailyScheduleEvent, DailyScheduleState> {
  // ===== Dependencies =====
  final GetMonthlyScheduleUseCase getMonthlyScheduleUseCase;
  final UpdateScheduleUseCase updateScheduleUseCase;
  final BulkUpdateScheduleUseCase bulkUpdateScheduleUseCase;
  final CheckAvailabilityUseCase checkAvailabilityUseCase;
  final CalculateTotalPriceUseCase calculateTotalPriceUseCase;
  final CloneScheduleUseCase cloneScheduleUseCase;
  final DeleteScheduleUseCase deleteScheduleUseCase;

  DailyScheduleBloc({
    required this.getMonthlyScheduleUseCase,
    required this.updateScheduleUseCase,
    required this.bulkUpdateScheduleUseCase,
    required this.checkAvailabilityUseCase,
    required this.calculateTotalPriceUseCase,
    required this.cloneScheduleUseCase,
    required this.deleteScheduleUseCase,
  }) : super(const DailyScheduleInitial()) {
    // تسجيل معالجات الأحداث
    on<LoadMonthlyScheduleEvent>(_onLoadMonthlySchedule);
    on<ChangeMonthEvent>(_onChangeMonth);
    on<SelectUnitEvent>(_onSelectUnit);
    on<UpdateSingleDayEvent>(_onUpdateSingleDay);
    on<UpdateDateRangeEvent>(_onUpdateDateRange);
    on<BulkUpdateScheduleEvent>(_onBulkUpdateSchedule);
    on<CheckAvailabilityEvent>(_onCheckAvailability);
    on<CalculateTotalPriceEvent>(_onCalculateTotalPrice);
    on<CloneScheduleEvent>(_onCloneSchedule);
    on<DeleteScheduleEvent>(_onDeleteSchedule);
    on<ResetErrorEvent>(_onResetError);
    on<FilterScheduleEvent>(_onFilterSchedule);
  }

  // ===== Event Handlers =====

  /// معالج حدث تحميل الجدول الشهري
  /// 
  /// يقوم بتحميل جدول شهر كامل من الخادم
  Future<void> _onLoadMonthlySchedule(
    LoadMonthlyScheduleEvent event,
    Emitter<DailyScheduleState> emit,
  ) async {
    // Debug: تتبع حدث تحميل الجدول الشهري
    // (يمكن إزالة هذه الطباعات بعد التأكد من عمل الشاشة)
    // ignore: avoid_print
    print('[DailyScheduleBloc] Loading monthly schedule for unit '
        '${event.unitId}, year=${event.year}, month=${event.month}');
    emit(const DailyScheduleLoading(loadingMessage: 'جاري تحميل الجدول...'));

    final params = GetMonthlyScheduleParams(
      unitId: event.unitId,
      year: event.year,
      month: event.month,
    );

    final result = await getMonthlyScheduleUseCase(params);

    result.fold(
      (failure) {
        final message = _mapFailureToMessage(failure);
        // ignore: avoid_print
        print('[DailyScheduleBloc] Failed to load monthly schedule: '
            '$message');
        emit(DailyScheduleError(
          errorMessage: message,
        ));
      },
      (monthlySchedule) {
        // ignore: avoid_print
        print('[DailyScheduleBloc] Monthly schedule loaded: '
            '${monthlySchedule.schedules.length} days');
        emit(DailyScheduleLoaded(
          monthlySchedule: monthlySchedule,
          selectedUnitId: event.unitId,
          currentYear: event.year,
          currentMonth: event.month,
        ));
      },
    );
  }

  /// معالج حدث تغيير الشهر
  /// 
  /// يقوم بتحميل جدول شهر جديد للوحدة الحالية
  Future<void> _onChangeMonth(
    ChangeMonthEvent event,
    Emitter<DailyScheduleState> emit,
  ) async {
    if (state is DailyScheduleLoaded) {
      final currentState = state as DailyScheduleLoaded;
      final unitId = currentState.selectedUnitId;

      if (unitId == null) {
        emit(const DailyScheduleError(
          errorMessage: 'لم يتم اختيار وحدة',
        ));
        return;
      }

      add(LoadMonthlyScheduleEvent(
        unitId: unitId,
        year: event.year,
        month: event.month,
      ));
    }
  }

  /// معالج حدث اختيار وحدة
  /// 
  /// يقوم بتحميل جدول الشهر الحالي للوحدة الجديدة
  Future<void> _onSelectUnit(
    SelectUnitEvent event,
    Emitter<DailyScheduleState> emit,
  ) async {
    final now = DateTime.now();
    int year = now.year;
    int month = now.month;

    // إذا كانت هناك حالة محملة، نستخدم الشهر والسنة الحالية منها
    if (state is DailyScheduleLoaded) {
      final currentState = state as DailyScheduleLoaded;
      year = currentState.currentYear;
      month = currentState.currentMonth;
    }

    add(LoadMonthlyScheduleEvent(
      unitId: event.unitId,
      year: year,
      month: month,
    ));
  }

  /// معالج حدث تحديث يوم واحد
  /// 
  /// يقوم بتحديث إتاحة و/أو تسعير يوم واحد فقط
  Future<void> _onUpdateSingleDay(
    UpdateSingleDayEvent event,
    Emitter<DailyScheduleState> emit,
  ) async {
    if (state is! DailyScheduleLoaded) return;

    final currentState = state as DailyScheduleLoaded;

    emit(DailyScheduleUpdating(
      currentSchedule: currentState.monthlySchedule,
      updatingMessage: 'جاري تحديث اليوم...',
    ));

    // بناء معاملات التحديث
    final params = UpdateScheduleParams(
      unitId: event.unitId,
      startDate: event.date,
      endDate: event.date,
      status: event.status,
      reason: event.reason,
      notes: event.notes,
      priceAmount: event.priceAmount,
      currency: event.currency,
      priceType: event.priceType,
      pricingTier: event.pricingTier,
      overwriteExisting: event.overwriteExisting,
    );

    final result = await updateScheduleUseCase(params);

    result.fold(
      (failure) {
        emit(DailyScheduleError(
          errorMessage: _mapFailureToMessage(failure),
          lastSchedule: currentState.monthlySchedule,
        ));
      },
      (affectedDays) {
        // إعادة تحميل الجدول بعد التحديث الناجح
        _reloadCurrentSchedule(currentState);
      },
    );
  }

  /// معالج حدث تحديث فترة
  /// 
  /// يقوم بتحديث إتاحة و/أو تسعير فترة زمنية محددة
  Future<void> _onUpdateDateRange(
    UpdateDateRangeEvent event,
    Emitter<DailyScheduleState> emit,
  ) async {
    if (state is! DailyScheduleLoaded) return;

    final currentState = state as DailyScheduleLoaded;

    emit(DailyScheduleUpdating(
      currentSchedule: currentState.monthlySchedule,
      updatingMessage: 'جاري تحديث الفترة...',
    ));

    final result = await updateScheduleUseCase(event.params);

    result.fold(
      (failure) => emit(DailyScheduleError(
        errorMessage: _mapFailureToMessage(failure),
        lastSchedule: currentState.monthlySchedule,
      )),
      (affectedDays) {
        // إعادة تحميل الجدول بعد التحديث الناجح
        _reloadCurrentSchedule(currentState);
      },
    );
  }

  /// معالج حدث التحديث الجماعي
  /// 
  /// يقوم بالتحديث الجماعي بناءً على أيام الأسبوع المحددة
  Future<void> _onBulkUpdateSchedule(
    BulkUpdateScheduleEvent event,
    Emitter<DailyScheduleState> emit,
  ) async {
    if (state is! DailyScheduleLoaded) return;

    final currentState = state as DailyScheduleLoaded;

    emit(DailyScheduleUpdating(
      currentSchedule: currentState.monthlySchedule,
      updatingMessage: 'جاري التحديث الجماعي...',
    ));

    final result = await bulkUpdateScheduleUseCase(event.params);

    result.fold(
      (failure) {
        emit(DailyScheduleError(
          errorMessage: _mapFailureToMessage(failure),
          lastSchedule: currentState.monthlySchedule,
        ));
      },
      (affectedDays) {
        // إعادة تحميل الجدول بعد التحديث الناجح
        _reloadCurrentSchedule(currentState);
      },
    );
  }

  /// معالج حدث التحقق من التوفر
  /// 
  /// يقوم بالتحقق من توفر الوحدة لفترة محددة
  Future<void> _onCheckAvailability(
    CheckAvailabilityEvent event,
    Emitter<DailyScheduleState> emit,
  ) async {
    if (state is! DailyScheduleLoaded) return;

    final currentState = state as DailyScheduleLoaded;

    emit(const DailyScheduleLoading(
      loadingMessage: 'جاري التحقق من التوفر...',
    ));

    final result = await checkAvailabilityUseCase(event.params);

    result.fold(
      (failure) {
        emit(DailyScheduleError(
          errorMessage: _mapFailureToMessage(failure),
          lastSchedule: currentState.monthlySchedule,
        ));
      },
      (availabilityResponse) {
        emit(currentState.copyWith(
          availabilityCheckResult: availabilityResponse,
        ));
      },
    );
  }

  /// معالج حدث حساب السعر الإجمالي
  /// 
  /// يقوم بحساب السعر الإجمالي لفترة محددة
  Future<void> _onCalculateTotalPrice(
    CalculateTotalPriceEvent event,
    Emitter<DailyScheduleState> emit,
  ) async {
    if (state is! DailyScheduleLoaded) return;

    final currentState = state as DailyScheduleLoaded;

    emit(const DailyScheduleLoading(
      loadingMessage: 'جاري حساب السعر الإجمالي...',
    ));

    final params = CalculateTotalPriceParams(
      unitId: event.unitId,
      startDate: event.startDate,
      endDate: event.endDate,
    );

    final result = await calculateTotalPriceUseCase(params);

    result.fold(
      (failure) {
        emit(DailyScheduleError(
          errorMessage: _mapFailureToMessage(failure),
          lastSchedule: currentState.monthlySchedule,
        ));
      },
      (totalPrice) {
        emit(currentState.copyWith(
          calculatedPrice: totalPrice,
        ));
      },
    );
  }

  /// معالج حدث نسخ الجدول
  /// 
  /// يقوم بنسخ جدول من فترة إلى فترة أخرى
  Future<void> _onCloneSchedule(
    CloneScheduleEvent event,
    Emitter<DailyScheduleState> emit,
  ) async {
    if (state is! DailyScheduleLoaded) return;

    final currentState = state as DailyScheduleLoaded;

    emit(DailyScheduleUpdating(
      currentSchedule: currentState.monthlySchedule,
      updatingMessage: 'جاري نسخ الجدول...',
    ));

    final result = await cloneScheduleUseCase(event.params);

    result.fold(
      (failure) {
        emit(DailyScheduleError(
          errorMessage: _mapFailureToMessage(failure),
          lastSchedule: currentState.monthlySchedule,
        ));
      },
      (affectedDays) {
        // إعادة تحميل الجدول بعد النسخ الناجح
        _reloadCurrentSchedule(currentState);
      },
    );
  }

  /// معالج حدث حذف الجدول
  /// 
  /// يقوم بحذف جدول لفترة محددة
  Future<void> _onDeleteSchedule(
    DeleteScheduleEvent event,
    Emitter<DailyScheduleState> emit,
  ) async {
    if (state is! DailyScheduleLoaded) return;

    final currentState = state as DailyScheduleLoaded;

    emit(DailyScheduleUpdating(
      currentSchedule: currentState.monthlySchedule,
      updatingMessage: 'جاري حذف الجدول...',
    ));

    final result = await deleteScheduleUseCase(event.params);

    result.fold(
      (failure) {
        emit(DailyScheduleError(
          errorMessage: _mapFailureToMessage(failure),
          lastSchedule: currentState.monthlySchedule,
        ));
      },
      (affectedDays) {
        // إعادة تحميل الجدول بعد الحذف الناجح
        _reloadCurrentSchedule(currentState);
      },
    );
  }

  /// معالج حدث إعادة تعيين حالة الأخطاء
  /// 
  /// يعيد BLoC إلى الحالة الأولية
  Future<void> _onResetError(
    ResetErrorEvent event,
    Emitter<DailyScheduleState> emit,
  ) async {
    emit(const DailyScheduleInitial());
  }

  /// معالج حدث تصفية الجدول
  /// 
  /// يقوم بتصفية الجدول حسب حالة الإتاحة
  Future<void> _onFilterSchedule(
    FilterScheduleEvent event,
    Emitter<DailyScheduleState> emit,
  ) async {
    if (state is! DailyScheduleLoaded) return;

    final currentState = state as DailyScheduleLoaded;

    emit(currentState.copyWith(
      currentFilter: event.filterStatus,
      clearFilter: event.filterStatus == null,
    ));
  }

  // ===== Helper Methods =====

  /// تحويل Failure إلى رسالة خطأ باللغة العربية
  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message.isNotEmpty
          ? failure.message
          : 'حدث خطأ في الاتصال بالخادم';
    } else if (failure is NetworkFailure) {
      return 'لا يوجد اتصال بالإنترنت';
    } else if (failure is ValidationFailure) {
      return failure.message.isNotEmpty
          ? failure.message
          : 'بيانات غير صالحة';
    } else if (failure is CacheFailure) {
      return 'حدث خطأ في التخزين المؤقت';
    } else if (failure is UnauthorizedFailure) {
      return 'غير مصرح لك بهذا الإجراء';
    } else {
      return 'حدث خطأ غير متوقع';
    }
  }

  /// إعادة تحميل الجدول الحالي بعد عملية ناجحة
  void _reloadCurrentSchedule(DailyScheduleLoaded currentState) {
    add(LoadMonthlyScheduleEvent(
      unitId: currentState.selectedUnitId!,
      year: currentState.currentYear,
      month: currentState.currentMonth,
    ));
  }
}
