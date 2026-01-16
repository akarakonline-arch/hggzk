import '../../domain/entities/property_availability.dart';

class PropertyAvailabilityModel extends PropertyAvailability {
  const PropertyAvailabilityModel({
    required super.hasAvailableUnits,
    required super.availableUnitsCount,
    required super.minAvailablePrice,
    required super.currency,
    required super.message,
    required super.availableUnitTypes,
  });

  factory PropertyAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return PropertyAvailabilityModel(
      hasAvailableUnits: json['hasAvailableUnits'] as bool? ?? false,
      availableUnitsCount: json['availableUnitsCount'] as int? ?? 0,
      minAvailablePrice: (json['minAvailablePrice'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? '',
      message: (json['message'] ?? '') as String,
      availableUnitTypes: (json['availableUnitTypes'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
    );
  }
}
