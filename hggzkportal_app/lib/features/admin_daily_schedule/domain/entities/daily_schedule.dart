import 'package:equatable/equatable.dart';

/// كيان الجدول اليومي الموحد للإتاحة والتسعير
/// يمثل بيانات الإتاحة والتسعير ليوم واحد محدد لوحدة معينة
class DailySchedule extends Equatable {
  /// معرّف الجدول اليومي
  final String id;

  /// معرّف الوحدة
  final String unitId;

  /// التاريخ (يوم واحد محدد)
  final DateTime date;

  // ===== خصائص الإتاحة =====

  /// حالة الإتاحة: Available, Booked, Blocked, Maintenance, OwnerUse
  final ScheduleStatus status;

  /// سبب عدم الإتاحة (في حالة Blocked, Maintenance, OwnerUse)
  final String? reason;

  /// ملاحظات إضافية
  final String? notes;

  /// معرّف الحجز المرتبط (في حالة Booked)
  final String? bookingId;

  // ===== خصائص التسعير =====

  /// مبلغ السعر لهذا اليوم
  final double? priceAmount;

  /// عملة السعر (مثل: YER, USD, SAR)
  final String? currency;

  /// نوع السعر: Base, Weekend, Seasonal, Holiday, SpecialEvent, Custom
  final PriceType? priceType;

  /// فئة التسعير: Normal, High, Peak, Discount, Custom
  final PricingTier? pricingTier;

  /// نسبة التغيير عن السعر الأساسي (مثال: 20 تعني زيادة 20%)
  final double? percentageChange;

  /// الحد الأدنى للسعر
  final double? minPrice;

  /// الحد الأقصى للسعر
  final double? maxPrice;

  // ===== خصائص إضافية =====

  /// وقت البداية (للوحدات التي تُحجز بالساعة)
  final String? startTime;

  /// وقت النهاية (للوحدات التي تُحجز بالساعة)
  final String? endTime;

  /// تاريخ الإنشاء
  final DateTime? createdAt;

  /// تاريخ آخر تحديث
  final DateTime? updatedAt;

  /// اسم المستخدم الذي أنشأ السجل
  final String? createdBy;

  /// اسم المستخدم الذي عدّل السجل
  final String? modifiedBy;

  const DailySchedule({
    required this.id,
    required this.unitId,
    required this.date,
    required this.status,
    this.reason,
    this.notes,
    this.bookingId,
    this.priceAmount,
    this.currency,
    this.priceType,
    this.pricingTier,
    this.percentageChange,
    this.minPrice,
    this.maxPrice,
    this.startTime,
    this.endTime,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.modifiedBy,
  });

  // ===== Helper Getters =====

  /// هل اليوم متاح للحجز؟
  bool get isAvailable => status == ScheduleStatus.available;

  /// هل اليوم محجوز؟
  bool get isBooked => status == ScheduleStatus.booked;

  /// هل اليوم محجوب؟
  bool get isBlocked => status == ScheduleStatus.blocked;

  /// هل اليوم في صيانة؟
  bool get isMaintenance => status == ScheduleStatus.maintenance;

  /// هل اليوم محجوز للمالك؟
  bool get isOwnerUse => status == ScheduleStatus.ownerUse;

  /// هل يوجد سعر مخصص لهذا اليوم؟
  bool get hasCustomPrice => priceAmount != null && priceAmount! > 0;

  /// هل السعر مخفض؟
  bool get isDiscounted => pricingTier == PricingTier.discount;

  /// هل السعر في فترة الذروة؟
  bool get isPeak => pricingTier == PricingTier.peak;

  /// الحصول على السعر الافتراضي أو 0
  double get displayPrice => priceAmount ?? 0.0;

  /// الحصول على العملة الافتراضية
  String get displayCurrency => currency ?? 'YER';

  // ===== Methods =====

  /// نسخ الكيان مع تعديل بعض الخصائص
  DailySchedule copyWith({
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
    return DailySchedule(
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

  @override
  List<Object?> get props => [
        id,
        unitId,
        date,
        status,
        reason,
        notes,
        bookingId,
        priceAmount,
        currency,
        priceType,
        pricingTier,
        percentageChange,
        minPrice,
        maxPrice,
        startTime,
        endTime,
        createdAt,
        updatedAt,
        createdBy,
        modifiedBy,
      ];
}

/// حالات الإتاحة
enum ScheduleStatus {
  /// متاح للحجز
  available,

  /// محجوز
  booked,

  /// محجوب (غير متاح)
  blocked,

  /// في صيانة
  maintenance,

  /// استخدام المالك
  ownerUse,
}

/// أنواع الأسعار
enum PriceType {
  /// السعر الأساسي
  base,

  /// سعر نهاية الأسبوع
  weekend,

  /// سعر موسمي
  seasonal,

  /// سعر العطلات والأعياد
  holiday,

  /// سعر حدث خاص
  specialEvent,

  /// سعر مخصص
  custom,
}

/// فئات التسعير
enum PricingTier {
  /// عادي
  normal,

  /// عالي
  high,

  /// ذروة
  peak,

  /// خصم
  discount,

  /// مخصص
  custom,
}

/// Extension لتحويل String إلى ScheduleStatus
extension ScheduleStatusExtension on String {
  ScheduleStatus toScheduleStatus() {
    switch (toLowerCase()) {
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
        return ScheduleStatus.available;
    }
  }
}

/// Extension لتحويل ScheduleStatus إلى String
extension ScheduleStatusStringExtension on ScheduleStatus {
  String toServerString() {
    switch (this) {
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

  String toArabicString() {
    switch (this) {
      case ScheduleStatus.available:
        return 'متاح';
      case ScheduleStatus.booked:
        return 'محجوز';
      case ScheduleStatus.blocked:
        return 'محجوب';
      case ScheduleStatus.maintenance:
        return 'صيانة';
      case ScheduleStatus.ownerUse:
        return 'استخدام المالك';
    }
  }
}

/// Extension لتحويل String إلى PriceType
extension PriceTypeExtension on String {
  PriceType? toPriceType() {
    switch (toLowerCase()) {
      case 'base':
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
        return null;
    }
  }
}

/// Extension لتحويل PriceType إلى String
extension PriceTypeStringExtension on PriceType {
  String toServerString() {
    switch (this) {
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

  String toArabicString() {
    switch (this) {
      case PriceType.base:
        return 'أساسي';
      case PriceType.weekend:
        return 'نهاية الأسبوع';
      case PriceType.seasonal:
        return 'موسمي';
      case PriceType.holiday:
        return 'عطلة';
      case PriceType.specialEvent:
        return 'حدث خاص';
      case PriceType.custom:
        return 'مخصص';
    }
  }
}

/// Extension لتحويل String إلى PricingTier
extension PricingTierExtension on String {
  PricingTier? toPricingTier() {
    switch (toLowerCase()) {
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
        return null;
    }
  }
}

/// Extension لتحويل PricingTier إلى String
extension PricingTierStringExtension on PricingTier {
  String toServerString() {
    switch (this) {
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

  String toArabicString() {
    switch (this) {
      case PricingTier.normal:
        return 'عادي';
      case PricingTier.high:
        return 'عالي';
      case PricingTier.peak:
        return 'ذروة';
      case PricingTier.discount:
        return 'خصم';
      case PricingTier.custom:
        return 'مخصص';
    }
  }
}
