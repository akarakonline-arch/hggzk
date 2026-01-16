class UnitAvailability {
  final bool isAvailable;
  final int totalDays;
  final int availableDays;
  final int unavailableDays;
  final List<DateTime> unavailableDates;
  final String? message;
  final double? totalPrice;
  final double? pricePerNight;
  final String? currency;

  const UnitAvailability({
    required this.isAvailable,
    required this.totalDays,
    required this.availableDays,
    required this.unavailableDays,
    required this.unavailableDates,
    this.message,
    this.totalPrice,
    this.pricePerNight,
    this.currency,
  });
}
