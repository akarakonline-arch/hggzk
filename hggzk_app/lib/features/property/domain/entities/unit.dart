import 'package:equatable/equatable.dart';

enum PricingMethod { hourly, daily, weekly, monthly }

class Unit extends Equatable {
  final String id;
  final String propertyId;
  final String unitTypeId;
  final String name;
  final String customFeatures;
  final String propertyName;
  final String unitTypeName;
  final PricingMethod pricingMethod;
  final List<UnitFieldValue> fieldValues;
  final List<FieldGroupWithValues> dynamicFields;
  final double? distanceKm;
  final List<UnitImage> images;
  final int? adultCapacity;
  final int? childrenCapacity;
  final double? totalPrice;
  final double? pricePerNight;
  final String? currency;

  const Unit({
    required this.id,
    required this.propertyId,
    required this.unitTypeId,
    required this.name,
    required this.customFeatures,
    required this.propertyName,
    required this.unitTypeName,
    required this.pricingMethod,
    required this.fieldValues,
    required this.dynamicFields,
    this.distanceKm,
    required this.images,
    this.adultCapacity,
    this.childrenCapacity,
    this.totalPrice,
    this.pricePerNight,
    this.currency,
  });

  @override
  List<Object?> get props => [
        id,
        propertyId,
        unitTypeId,
        name,
        customFeatures,
        propertyName,
        unitTypeName,
        pricingMethod,
        fieldValues,
        dynamicFields,
        distanceKm,
        images,
        adultCapacity,
        childrenCapacity,
        totalPrice,
        pricePerNight,
        currency,
      ];
}

class Money extends Equatable {
  final double amount;
  final String currency;
  final double exchangeRate;

  const Money({
    required this.amount,
    this.currency = 'YER',
    this.exchangeRate = 1.0,
  });

  String get formattedAmount => '${amount.toStringAsFixed(2)} $currency';

  @override
  List<Object?> get props => [amount, currency, exchangeRate];
}

class UnitFieldValue extends Equatable {
  final String valueId;
  final String fieldId;
  final String fieldName;
  final String displayName;
  final String value;
  final String? fieldTypeId;
  final bool? isPrimaryFilter;

  const UnitFieldValue({
    required this.valueId,
    required this.fieldId,
    required this.fieldName,
    required this.displayName,
    required this.value,
    this.fieldTypeId,
    this.isPrimaryFilter,
  });

  @override
  List<Object?> get props => [
        valueId,
        fieldId,
        fieldName,
        displayName,
        value,
        fieldTypeId,
        isPrimaryFilter
      ];
}

class FieldGroupWithValues extends Equatable {
  final String groupId;
  final String groupName;
  final String displayName;
  final String description;
  final List<UnitFieldValue> fieldValues;

  const FieldGroupWithValues({
    required this.groupId,
    required this.groupName,
    required this.displayName,
    required this.description,
    required this.fieldValues,
  });

  @override
  List<Object?> get props => [
        groupId,
        groupName,
        displayName,
        description,
        fieldValues,
      ];
}

class UnitImage extends Equatable {
  final String id;
  final String url;
  final String caption;
  final bool isMain;
  final int displayOrder;
  final bool is360;

  const UnitImage({
    required this.id,
    required this.url,
    required this.caption,
    required this.isMain,
    required this.displayOrder,
    this.is360 = false,
  });

  @override
  List<Object?> get props => [id, url, caption, isMain, displayOrder, is360];
}
