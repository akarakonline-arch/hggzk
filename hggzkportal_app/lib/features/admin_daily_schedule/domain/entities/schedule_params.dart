import 'package:equatable/equatable.dart';
import 'daily_schedule.dart';

/// معاملات تحديث الإتاحة والتسعير لفترة محددة
class UpdateScheduleParams extends Equatable {
  /// معرّف الوحدة
  final String unitId;

  /// تاريخ البداية
  final DateTime startDate;

  /// تاريخ النهاية
  final DateTime endDate;

  /// حالة الإتاحة (اختياري - في حالة تحديث الإتاحة فقط)
  final ScheduleStatus? status;

  /// السبب (اختياري - في حالة Blocked, Maintenance, OwnerUse)
  final String? reason;

  /// الملاحظات (اختياري)
  final String? notes;

  /// مبلغ السعر (اختياري - في حالة تحديث التسعير فقط)
  final double? priceAmount;

  /// العملة (اختياري)
  final String? currency;

  /// نوع السعر (اختياري)
  final PriceType? priceType;

  /// فئة التسعير (اختياري)
  final PricingTier? pricingTier;

  /// نسبة التغيير (اختياري)
  final double? percentageChange;

  /// الحد الأدنى للسعر (اختياري)
  final double? minPrice;

  /// الحد الأقصى للسعر (اختياري)
  final double? maxPrice;

  /// الكتابة فوق البيانات الموجودة
  final bool overwriteExisting;

  const UpdateScheduleParams({
    required this.unitId,
    required this.startDate,
    required this.endDate,
    this.status,
    this.reason,
    this.notes,
    this.priceAmount,
    this.currency,
    this.priceType,
    this.pricingTier,
    this.percentageChange,
    this.minPrice,
    this.maxPrice,
    this.overwriteExisting = false,
  });

  /// إنشاء معاملات لتحديث الإتاحة فقط
  factory UpdateScheduleParams.availability({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
    required ScheduleStatus status,
    String? reason,
    String? notes,
    bool overwriteExisting = false,
  }) {
    return UpdateScheduleParams(
      unitId: unitId,
      startDate: startDate,
      endDate: endDate,
      status: status,
      reason: reason,
      notes: notes,
      overwriteExisting: overwriteExisting,
    );
  }

  /// إنشاء معاملات لتحديث التسعير فقط
  factory UpdateScheduleParams.pricing({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
    required double priceAmount,
    String? currency,
    PriceType? priceType,
    PricingTier? pricingTier,
    double? percentageChange,
    double? minPrice,
    double? maxPrice,
    bool overwriteExisting = false,
  }) {
    return UpdateScheduleParams(
      unitId: unitId,
      startDate: startDate,
      endDate: endDate,
      priceAmount: priceAmount,
      currency: currency,
      priceType: priceType,
      pricingTier: pricingTier,
      percentageChange: percentageChange,
      minPrice: minPrice,
      maxPrice: maxPrice,
      overwriteExisting: overwriteExisting,
    );
  }

  /// هل التحديث خاص بالإتاحة؟
  bool get isAvailabilityUpdate => status != null;

  /// هل التحديث خاص بالتسعير؟
  bool get isPricingUpdate => priceAmount != null;

  @override
  List<Object?> get props => [
        unitId,
        startDate,
        endDate,
        status,
        reason,
        notes,
        priceAmount,
        currency,
        priceType,
        pricingTier,
        percentageChange,
        minPrice,
        maxPrice,
        overwriteExisting,
      ];
}

/// معاملات التحديث الجماعي بناءً على أيام الأسبوع
class BulkUpdateScheduleParams extends Equatable {
  /// معرّف الوحدة
  final String unitId;

  /// تاريخ البداية
  final DateTime startDate;

  /// تاريخ النهاية
  final DateTime endDate;

  /// أيام الأسبوع المستهدفة (1=الاثنين، 7=الأحد) - null تعني جميع الأيام
  final List<int>? weekdays;

  /// حالة الإتاحة (اختياري)
  final ScheduleStatus? status;

  /// السبب (اختياري)
  final String? reason;

  /// الملاحظات (اختياري)
  final String? notes;

  /// مبلغ السعر (اختياري)
  final double? priceAmount;

  /// العملة (اختياري)
  final String? currency;

  /// نوع السعر (اختياري)
  final PriceType? priceType;

  /// فئة التسعير (اختياري)
  final PricingTier? pricingTier;

  /// الكتابة فوق البيانات الموجودة
  final bool overwriteExisting;

  const BulkUpdateScheduleParams({
    required this.unitId,
    required this.startDate,
    required this.endDate,
    this.weekdays,
    this.status,
    this.reason,
    this.notes,
    this.priceAmount,
    this.currency,
    this.priceType,
    this.pricingTier,
    this.overwriteExisting = false,
  });

  @override
  List<Object?> get props => [
        unitId,
        startDate,
        endDate,
        weekdays,
        status,
        reason,
        notes,
        priceAmount,
        currency,
        priceType,
        pricingTier,
        overwriteExisting,
      ];
}

/// معاملات التحقق من التوفر
class CheckAvailabilityParams extends Equatable {
  /// معرّف الوحدة
  final String unitId;

  /// تاريخ تسجيل الدخول
  final DateTime checkInDate;

  /// تاريخ تسجيل الخروج
  final DateTime checkOutDate;

  /// عدد البالغين (اختياري)
  final int? adults;

  /// عدد الأطفال (اختياري)
  final int? children;

  /// تضمين معلومات التسعير
  final bool includePricing;

  const CheckAvailabilityParams({
    required this.unitId,
    required this.checkInDate,
    required this.checkOutDate,
    this.adults,
    this.children,
    this.includePricing = true,
  });

  @override
  List<Object?> get props => [
        unitId,
        checkInDate,
        checkOutDate,
        adults,
        children,
        includePricing,
      ];
}

/// نتيجة التحقق من التوفر
class CheckAvailabilityResponse extends Equatable {
  /// هل الوحدة متاحة للفترة المطلوبة؟
  final bool isAvailable;

  /// عدد الليالي
  final int nights;

  /// السعر الإجمالي (إذا كان includePricing = true)
  final double? totalPrice;

  /// العملة
  final String? currency;

  /// تفاصيل الأسعار اليومية
  final List<DailyPrice>? dailyPrices;

  /// الأيام غير المتاحة (في حالة عدم التوفر)
  final List<DateTime>? unavailableDates;

  /// رسالة (في حالة عدم التوفر أو ملاحظات إضافية)
  final String? message;

  const CheckAvailabilityResponse({
    required this.isAvailable,
    required this.nights,
    this.totalPrice,
    this.currency,
    this.dailyPrices,
    this.unavailableDates,
    this.message,
  });

  @override
  List<Object?> get props => [
        isAvailable,
        nights,
        totalPrice,
        currency,
        dailyPrices,
        unavailableDates,
        message,
      ];
}

/// سعر يوم واحد
class DailyPrice extends Equatable {
  /// التاريخ
  final DateTime date;

  /// السعر
  final double price;

  /// العملة
  final String currency;

  /// نوع السعر
  final PriceType? priceType;

  const DailyPrice({
    required this.date,
    required this.price,
    required this.currency,
    this.priceType,
  });

  @override
  List<Object?> get props => [date, price, currency, priceType];
}
