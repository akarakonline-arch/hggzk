import '../../domain/entities/daily_schedule.dart';

/// نموذج DailyScheduleModel يمتد من Entity
/// يستخدم للتحويل من/إلى JSON من/إلى Backend
class DailyScheduleModel extends DailySchedule {
  const DailyScheduleModel({
    required super.id,
    required super.unitId,
    required super.date,
    required super.status,
    super.reason,
    super.notes,
    super.bookingId,
    super.priceAmount,
    super.currency,
    super.priceType,
    super.pricingTier,
    super.percentageChange,
    super.minPrice,
    super.maxPrice,
    super.startTime,
    super.endTime,
    super.createdAt,
    super.updatedAt,
    super.createdBy,
    super.modifiedBy,
  });

  /// تحويل من JSON إلى Model
  /// يتعامل مع جميع الحقول بما في ذلك null values
  factory DailyScheduleModel.fromJson(Map<String, dynamic> json) {
    return DailyScheduleModel(
      id: json['Id'] as String,
      unitId: json['UnitId'] as String,
      date: DateTime.parse(json['Date'] as String),
      status: _parseScheduleStatus(json['Status'] as String),
      reason: json['Reason'] as String?,
      notes: json['Notes'] as String?,
      bookingId: json['BookingId'] as String?,
      priceAmount: json['PriceAmount'] != null
          ? (json['PriceAmount'] as num).toDouble()
          : null,
      currency: json['Currency'] as String?,
      priceType: json['PriceType'] != null
          ? _parsePriceType(json['PriceType'] as String)
          : null,
      pricingTier: json['PricingTier'] != null
          ? _parsePricingTier(json['PricingTier'] as String)
          : null,
      percentageChange: json['PercentageChange'] != null
          ? (json['PercentageChange'] as num).toDouble()
          : null,
      minPrice: json['MinPrice'] != null
          ? (json['MinPrice'] as num).toDouble()
          : null,
      maxPrice: json['MaxPrice'] != null
          ? (json['MaxPrice'] as num).toDouble()
          : null,
      startTime: json['StartTime'] as String?,
      endTime: json['EndTime'] as String?,
      createdAt: json['CreatedAt'] != null
          ? DateTime.parse(json['CreatedAt'] as String)
          : null,
      updatedAt: json['UpdatedAt'] != null
          ? DateTime.parse(json['UpdatedAt'] as String)
          : null,
      createdBy: json['CreatedBy'] as String?,
      modifiedBy: json['ModifiedBy'] as String?,
    );
  }

  /// تحويل من Model إلى JSON
  /// يحول DateTime إلى String بصيغة ISO8601
  /// يحول enums إلى Strings
  Map<String, dynamic> toJson() {
    return {
      'Id': id,
      'UnitId': unitId,
      'Date': date.toIso8601String(),
      'Status': _scheduleStatusToString(status),
      if (reason != null) 'Reason': reason,
      if (notes != null) 'Notes': notes,
      if (bookingId != null) 'BookingId': bookingId,
      if (priceAmount != null) 'PriceAmount': priceAmount,
      if (currency != null) 'Currency': currency,
      if (priceType != null) 'PriceType': _priceTypeToString(priceType!),
      if (pricingTier != null) 'PricingTier': _pricingTierToString(pricingTier!),
      if (percentageChange != null) 'PercentageChange': percentageChange,
      if (minPrice != null) 'MinPrice': minPrice,
      if (maxPrice != null) 'MaxPrice': maxPrice,
      if (startTime != null) 'StartTime': startTime,
      if (endTime != null) 'EndTime': endTime,
      if (createdAt != null) 'CreatedAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'UpdatedAt': updatedAt!.toIso8601String(),
      if (createdBy != null) 'CreatedBy': createdBy,
      if (modifiedBy != null) 'ModifiedBy': modifiedBy,
    };
  }

  /// تحويل من Entity إلى Model
  factory DailyScheduleModel.fromEntity(DailySchedule entity) {
    return DailyScheduleModel(
      id: entity.id,
      unitId: entity.unitId,
      date: entity.date,
      status: entity.status,
      reason: entity.reason,
      notes: entity.notes,
      bookingId: entity.bookingId,
      priceAmount: entity.priceAmount,
      currency: entity.currency,
      priceType: entity.priceType,
      pricingTier: entity.pricingTier,
      percentageChange: entity.percentageChange,
      minPrice: entity.minPrice,
      maxPrice: entity.maxPrice,
      startTime: entity.startTime,
      endTime: entity.endTime,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      createdBy: entity.createdBy,
      modifiedBy: entity.modifiedBy,
    );
  }

  /// تحويل String إلى ScheduleStatus enum
  static ScheduleStatus _parseScheduleStatus(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return ScheduleStatus.available;
      case 'booked':
        return ScheduleStatus.booked;
      case 'blocked':
        return ScheduleStatus.blocked;
      case 'maintenance':
        return ScheduleStatus.maintenance;
      case 'owneruse':
        return ScheduleStatus.ownerUse;
      default:
        throw ArgumentError('Invalid schedule status: $status');
    }
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

  /// تحويل String إلى PriceType enum
  static PriceType _parsePriceType(String type) {
    switch (type.toLowerCase()) {
      case 'base':
      case 'baseprice':
        return PriceType.base;
      case 'weekend':
        return PriceType.weekend;
      case 'seasonal':
        return PriceType.seasonal;
      case 'holiday':
        return PriceType.holiday;
      case 'specialevent':
        return PriceType.specialEvent;
      case 'custom':
        return PriceType.custom;
      default:
        throw ArgumentError('Invalid price type: $type');
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

  /// تحويل String إلى PricingTier enum
  static PricingTier _parsePricingTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'normal':
        return PricingTier.normal;
      case 'high':
        return PricingTier.high;
      case 'peak':
        return PricingTier.peak;
      case 'discount':
        return PricingTier.discount;
      case 'custom':
        return PricingTier.custom;
      default:
        throw ArgumentError('Invalid pricing tier: $tier');
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

  /// نسخ Model مع تحديث بعض الحقول
  DailyScheduleModel copyWith({
    String? id,
    String? unitId,
    DateTime? date,
    ScheduleStatus? status,
    String? reason,
    String? notes,
    String? bookingId,
    double? priceAmount,
    String? currency,
    PriceType? priceType,
    PricingTier? pricingTier,
    double? percentageChange,
    double? minPrice,
    double? maxPrice,
    String? startTime,
    String? endTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? modifiedBy,
  }) {
    return DailyScheduleModel(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      date: date ?? this.date,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      notes: notes ?? this.notes,
      bookingId: bookingId ?? this.bookingId,
      priceAmount: priceAmount ?? this.priceAmount,
      currency: currency ?? this.currency,
      priceType: priceType ?? this.priceType,
      pricingTier: pricingTier ?? this.pricingTier,
      percentageChange: percentageChange ?? this.percentageChange,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      modifiedBy: modifiedBy ?? this.modifiedBy,
    );
  }
}
