import '../../domain/entities/unit_availability.dart';

class UnitAvailabilityModel extends UnitAvailability {
  const UnitAvailabilityModel({
    required super.isAvailable,
    required super.totalDays,
    required super.availableDays,
    required super.unavailableDays,
    required super.unavailableDates,
    super.message,
    super.totalPrice,
    super.pricePerNight,
    super.currency,
  });

  factory UnitAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return UnitAvailabilityModel(
      isAvailable: json['isAvailable'] as bool? ?? false,
      totalDays: json['totalDays'] as int? ?? 0,
      availableDays: json['availableDays'] as int? ?? 0,
      unavailableDays: json['unavailableDays'] as int? ?? 0,
      unavailableDates: (json['unavailableDates'] as List?)
              ?.map((e) => DateTime.parse(e.toString()))
              .toList() ??
          const <DateTime>[],
      message: json['message'] as String?,
      totalPrice: (json['totalPrice'] as num?)?.toDouble(),
      pricePerNight: (json['pricePerNight'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
    );
  }
}
