import '../../domain/entities/schedule_params.dart';
import '../../domain/entities/daily_schedule.dart';
import '../../domain/usecases/update_schedule.dart';
import '../../domain/usecases/bulk_update_schedule.dart';
import '../../domain/usecases/check_availability.dart';

/// نموذج طلب تحديث الجدول - للإرسال إلى API
class UpdateScheduleRequestModel {
  /// تاريخ البداية
  final DateTime startDate;

  /// تاريخ النهاية
  final DateTime endDate;
  final ScheduleStatus? status;
  final String? reason;
  final String? notes;
  final double? priceAmount;
  final String? currency;
  final PriceType? priceType;
  final PricingTier? pricingTier;
  final double? percentageChange;
  final double? minPrice;
  final double? maxPrice;
  final String? startTime;
  final String? endTime;

  /// هل يتم الكتابة فوق السجلات الحالية في نفس الفترة
  final bool overwriteExisting;

  const UpdateScheduleRequestModel({
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
    this.startTime,
    this.endTime,
    this.overwriteExisting = false,
  });

  /// تحويل من UpdateScheduleParams إلى Model
  /// ملاحظة: يستخدم startDate فقط لأن UpdateScheduleParams يحتوي على فترة
  factory UpdateScheduleRequestModel.fromParams(UpdateScheduleParams params) {
    return UpdateScheduleRequestModel(
      startDate: params.startDate,
      endDate: params.endDate,
      status: params.status,
      reason: params.reason,
      notes: params.notes,
      priceAmount: params.priceAmount,
      currency: params.currency,
      priceType: params.priceType,
      pricingTier: params.pricingTier,
      percentageChange: params.percentageChange,
      minPrice: params.minPrice,
      maxPrice: params.maxPrice,
      startTime: null, // UpdateScheduleParams لا يحتوي على startTime
      endTime: null, // UpdateScheduleParams لا يحتوي على endTime
      overwriteExisting: params.overwriteExisting,
    );
  }

  /// تحويل إلى JSON للإرسال إلى API
  Map<String, dynamic> toJson() {
    return {
      'StartDate': startDate.toIso8601String(),
      'EndDate': endDate.toIso8601String(),
      if (status != null) 'Status': _scheduleStatusToString(status!),
      if (reason != null) 'Reason': reason,
      if (notes != null) 'Notes': notes,
      if (priceAmount != null) 'PriceAmount': priceAmount,
      if (currency != null) 'Currency': currency,
      if (priceType != null) 'PriceType': _priceTypeToString(priceType!),
      if (pricingTier != null) 'PricingTier': _pricingTierToString(pricingTier!),
      if (percentageChange != null) 'PercentageChange': percentageChange,
      if (minPrice != null) 'MinPrice': minPrice,
      if (maxPrice != null) 'MaxPrice': maxPrice,
      if (startTime != null) 'StartTime': startTime,
      if (endTime != null) 'EndTime': endTime,
      'OverwriteExisting': overwriteExisting,
    };
  }

  /// تحويل ScheduleStatus enum إلى String
  static String _scheduleStatusToString(ScheduleStatus status) {
    switch (status) {
      case ScheduleStatus.available:
        return 'Available';
      case ScheduleStatus.booked:
        return 'Booked';
      case ScheduleStatus.blocked:
        return 'Blocked';
      case ScheduleStatus.maintenance:
        return 'Maintenance';
      case ScheduleStatus.ownerUse:
        return 'OwnerUse';
    }
  }

  /// تحويل PriceType enum إلى String
  static String _priceTypeToString(PriceType type) {
    switch (type) {
      case PriceType.base:
        return 'Base';
      case PriceType.weekend:
        return 'Weekend';
      case PriceType.seasonal:
        return 'Seasonal';
      case PriceType.holiday:
        return 'Holiday';
      case PriceType.specialEvent:
        return 'SpecialEvent';
      case PriceType.custom:
        return 'Custom';
    }
  }

  /// تحويل PricingTier enum إلى String
  static String _pricingTierToString(PricingTier tier) {
    switch (tier) {
      case PricingTier.normal:
        return 'Normal';
      case PricingTier.high:
        return 'High';
      case PricingTier.peak:
        return 'Peak';
      case PricingTier.discount:
        return 'Discount';
      case PricingTier.custom:
        return 'Custom';
    }
  }
}

/// نموذج طلب التحديث المجمع للجدول - للإرسال إلى API
class BulkUpdateScheduleRequestModel {
  final DateTime startDate;
  final DateTime endDate;
  final ScheduleStatus? status;
  final String? reason;
  final String? notes;
  final double? priceAmount;
  final String? currency;
  final PriceType? priceType;
  final PricingTier? pricingTier;
  final double? percentageChange;
  final double? minPrice;
  final double? maxPrice;
  final List<int>? daysOfWeek;
  final bool? skipBooked;

  const BulkUpdateScheduleRequestModel({
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
    this.daysOfWeek,
    this.skipBooked,
  });

  /// تحويل من BulkUpdateScheduleParams إلى Model
  factory BulkUpdateScheduleRequestModel.fromParams(
      BulkUpdateScheduleParams params) {
    return BulkUpdateScheduleRequestModel(
      startDate: params.startDate,
      endDate: params.endDate,
      status: params.status,
      reason: params.reason,
      notes: params.notes,
      priceAmount: params.priceAmount,
      currency: params.currency,
      priceType: params.priceType,
      pricingTier: params.pricingTier,
      percentageChange: null, // BulkUpdateScheduleParams لا يحتوي على percentageChange
      minPrice: null, // BulkUpdateScheduleParams لا يحتوي على minPrice
      maxPrice: null, // BulkUpdateScheduleParams لا يحتوي على maxPrice
      daysOfWeek: params.weekdays, // weekdays في params يقابل daysOfWeek في API
      skipBooked: null, // BulkUpdateScheduleParams لا يحتوي على skipBooked
    );
  }

  /// تحويل إلى JSON للإرسال إلى API
  Map<String, dynamic> toJson() {
    return {
      'StartDate': startDate.toIso8601String(),
      'EndDate': endDate.toIso8601String(),
      if (status != null)
        'Status': UpdateScheduleRequestModel._scheduleStatusToString(status!),
      if (reason != null) 'Reason': reason,
      if (notes != null) 'Notes': notes,
      if (priceAmount != null) 'PriceAmount': priceAmount,
      if (currency != null) 'Currency': currency,
      if (priceType != null)
        'PriceType': UpdateScheduleRequestModel._priceTypeToString(priceType!),
      if (pricingTier != null)
        'PricingTier': UpdateScheduleRequestModel._pricingTierToString(pricingTier!),
      if (percentageChange != null) 'PercentageChange': percentageChange,
      if (minPrice != null) 'MinPrice': minPrice,
      if (maxPrice != null) 'MaxPrice': maxPrice,
      if (daysOfWeek != null) 'DaysOfWeek': daysOfWeek,
      if (skipBooked != null) 'SkipBooked': skipBooked,
    };
  }
}

/// نموذج طلب التحقق من التوافر - للإرسال إلى API
class CheckAvailabilityRequestModel {
  final DateTime startDate;
  final DateTime endDate;

  const CheckAvailabilityRequestModel({
    required this.startDate,
    required this.endDate,
  });

  /// تحويل من CheckAvailabilityParams إلى Model
  factory CheckAvailabilityRequestModel.fromParams(
      CheckAvailabilityParams params) {
    return CheckAvailabilityRequestModel(
      startDate: params.checkInDate,
      endDate: params.checkOutDate,
    );
  }

  /// تحويل إلى Query Parameters للإرسال إلى API
  Map<String, String> toQueryParams() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
  }
}

/// نموذج استجابة التحقق من التوافر - من API (يمتد من Entity)
class CheckAvailabilityResponseModel extends CheckAvailabilityResponse {
  const CheckAvailabilityResponseModel({
    required super.isAvailable,
    required super.nights,
    super.totalPrice,
    super.currency,
    super.dailyPrices,
    required List<DateTime> unavailableDates,
    super.message,
  }) : super(unavailableDates: unavailableDates);

  /// تحويل من JSON إلى Model
  factory CheckAvailabilityResponseModel.fromJson(Map<String, dynamic> json) {
    final unavailableDatesJson = json['UnavailableDates'] as List<dynamic>?;
    final unavailableDates = unavailableDatesJson != null
        ? unavailableDatesJson
            .map((e) => DateTime.parse(e as String))
            .toList()
        : <DateTime>[];

    return CheckAvailabilityResponseModel(
      isAvailable: json['IsAvailable'] as bool? ?? true,
      nights: json['Nights'] as int? ?? 0,
      totalPrice: json['TotalPrice'] != null
          ? (json['TotalPrice'] as num).toDouble()
          : null,
      currency: json['Currency'] as String?,
      unavailableDates: unavailableDates,
      message: json['Message'] as String?,
      dailyPrices: null,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'IsAvailable': isAvailable,
      'Nights': nights,
      if (totalPrice != null) 'TotalPrice': totalPrice,
      if (currency != null) 'Currency': currency,
      'UnavailableDates':
          unavailableDates?.map((e) => e.toIso8601String()).toList() ?? [],
      if (message != null) 'Message': message,
    };
  }
}

/// نموذج طلب حساب السعر الإجمالي - للإرسال إلى API
class CalculateTotalPriceRequestModel {
  final DateTime startDate;
  final DateTime endDate;
  final String? currency;

  const CalculateTotalPriceRequestModel({
    required this.startDate,
    required this.endDate,
    this.currency,
  });

  /// تحويل إلى JSON للإرسال إلى API
  Map<String, dynamic> toJson() {
    return {
      'StartDate': startDate.toIso8601String(),
      'EndDate': endDate.toIso8601String(),
      if (currency != null) 'Currency': currency,
    };
  }
}

/// نموذج استجابة حساب السعر الإجمالي - من API
class CalculateTotalPriceResponseModel {
  final double totalPrice;
  final String currency;
  final int numberOfDays;
  final List<DailyPriceBreakdown>? breakdown;

  const CalculateTotalPriceResponseModel({
    required this.totalPrice,
    required this.currency,
    required this.numberOfDays,
    this.breakdown,
  });

  /// تحويل من JSON إلى Model
  factory CalculateTotalPriceResponseModel.fromJson(
      Map<String, dynamic> json) {
    final breakdownJson = json['Breakdown'] as List<dynamic>?;
    final breakdown = breakdownJson != null
        ? breakdownJson
            .map((e) =>
                DailyPriceBreakdown.fromJson(e as Map<String, dynamic>))
            .toList()
        : null;

    return CalculateTotalPriceResponseModel(
      totalPrice: (json['TotalPrice'] as num).toDouble(),
      currency: json['Currency'] as String,
      numberOfDays: json['NumberOfDays'] as int,
      breakdown: breakdown,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'TotalPrice': totalPrice,
      'Currency': currency,
      'NumberOfDays': numberOfDays,
      if (breakdown != null) 'Breakdown': breakdown!.map((e) => e.toJson()).toList(),
    };
  }
}

/// تفاصيل سعر اليوم الواحد
class DailyPriceBreakdown {
  final DateTime date;
  final double price;
  final String? priceType;

  const DailyPriceBreakdown({
    required this.date,
    required this.price,
    this.priceType,
  });

  /// تحويل من JSON إلى Model
  factory DailyPriceBreakdown.fromJson(Map<String, dynamic> json) {
    return DailyPriceBreakdown(
      date: DateTime.parse(json['Date'] as String),
      price: (json['Price'] as num).toDouble(),
      priceType: json['PriceType'] as String?,
    );
  }

  /// تحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'Date': date.toIso8601String(),
      'Price': price,
      if (priceType != null) 'PriceType': priceType,
    };
  }
}
