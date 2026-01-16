import 'package:equatable/equatable.dart';

class Amenity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final String category;
  final String icon;
  final bool isActive;
  final double? extraCost;
  final int displayOrder;
  final DateTime createdAt;

  const Amenity({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.category,
    required this.icon,
    required this.isActive,
    this.extraCost,
    required this.displayOrder,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        iconUrl,
        category,
        icon,
        isActive,
        extraCost,
        displayOrder,
        createdAt,
      ];
}