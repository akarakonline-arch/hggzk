class PropertyAvailability {
  final bool hasAvailableUnits;
  final int availableUnitsCount;
  final double? minAvailablePrice;
  final String? currency;
  final String message;
  final List<String> availableUnitTypes;

  const PropertyAvailability({
    required this.hasAvailableUnits,
    required this.availableUnitsCount,
    required this.minAvailablePrice,
    required this.currency,
    required this.message,
    required this.availableUnitTypes,
  });
}
