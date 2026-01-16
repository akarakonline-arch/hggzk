import 'dart:convert';
import '../../domain/entities/unit.dart';

class UnitModel extends Unit {
  const UnitModel({
    required super.id,
    required super.propertyId,
    required super.unitTypeId,
    required super.name,
    required super.customFeatures,
    required super.propertyName,
    required super.unitTypeName,
    required super.pricingMethod,
    required super.fieldValues,
    required super.dynamicFields,
    super.distanceKm,
    required super.images,
    super.adultCapacity,
    super.childrenCapacity,
    super.totalPrice,
    super.pricePerNight,
    super.currency,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    final unitType = json['unitType'] as Map<String, dynamic>?;
    final unitTypeName =
        (json['unitTypeName'] ?? unitType?['name'] ?? '').toString();
    final unitTypeId =
        (json['unitTypeId'] ?? unitType?['id']?.toString() ?? '').toString();

    final cf = json['customFeatures'];
    final customFeatures =
        cf == null ? '' : (cf is String ? cf : jsonEncode(cf));

    final images = (json['images'] as List?)
            ?.map((e) => UnitImageModel.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    final fieldValues = (json['fieldValues'] as List?)
            ?.map((e) =>
                UnitFieldValueModel.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        [];

    return UnitModel(
      id: (json['id'] ?? '').toString(),
      propertyId: (json['propertyId'] ?? '').toString(),
      unitTypeId: unitTypeId,
      name: (json['name'] ?? '').toString(),
      customFeatures: customFeatures,
      propertyName: (json['propertyName'] ?? '').toString(),
      unitTypeName: unitTypeName,
      pricingMethod: _parsePricingMethod(json['pricingMethod']),
      fieldValues: fieldValues,
      dynamicFields: (json['dynamicFields'] as List?)
              ?.map((e) => FieldGroupWithValuesModel.fromJson(
                  Map<String, dynamic>.from(e)))
              .toList() ??
          [],
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      images: images,
      adultCapacity: json['adultCapacity'] as int?,
      childrenCapacity: json['childrenCapacity'] as int?,
      totalPrice: (json['totalPrice'] as num?)?.toDouble(),
      pricePerNight: (json['pricePerNight'] as num?)?.toDouble(),
      currency: json['currency']?.toString(),
    );
  }

  static PricingMethod _parsePricingMethod(dynamic method) {
    if (method == null) return PricingMethod.daily;
    switch (method.toString().toLowerCase()) {
      case 'hourly':
        return PricingMethod.hourly;
      case 'weekly':
        return PricingMethod.weekly;
      case 'monthly':
        return PricingMethod.monthly;
      default:
        return PricingMethod.daily;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      'unitTypeId': unitTypeId,
      'name': name,
      'customFeatures': customFeatures,
      'propertyName': propertyName,
      'unitTypeName': unitTypeName,
      'pricingMethod': pricingMethod.name,
      'fieldValues':
          fieldValues.map((e) => (e as UnitFieldValueModel).toJson()).toList(),
      'dynamicFields': dynamicFields
          .map((e) => (e as FieldGroupWithValuesModel).toJson())
          .toList(),
      'distanceKm': distanceKm,
      'images': images.map((e) => (e as UnitImageModel).toJson()).toList(),
      'adultCapacity': adultCapacity,
      'childrenCapacity': childrenCapacity,
      'totalPrice': totalPrice,
      'pricePerNight': pricePerNight,
      'currency': currency,
    };
  }
}

class MoneyModel extends Money {
  const MoneyModel({
    required super.amount,
    super.currency,
    super.exchangeRate,
  });

  factory MoneyModel.fromJson(Map<String, dynamic> json) {
    return MoneyModel(
      amount: (json['amount'] ?? 0).toDouble(),
      currency: (json['currency'] ?? 'YER').toString(),
      exchangeRate: (json['exchangeRate'] ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'exchangeRate': exchangeRate,
      'formattedAmount': formattedAmount,
    };
  }
}

class UnitFieldValueModel extends UnitFieldValue {
  const UnitFieldValueModel({
    required super.valueId,
    required super.fieldId,
    required super.fieldName,
    required super.displayName,
    required super.value,
    super.fieldTypeId,
    super.isPrimaryFilter,
  });

  factory UnitFieldValueModel.fromJson(Map<String, dynamic> json) {
    // Support both detailed and simple shapes
    final hasIds = json.containsKey('valueId') || json.containsKey('fieldId');
    if (hasIds) {
      return UnitFieldValueModel(
        valueId: (json['valueId'] ?? '').toString(),
        fieldId: (json['fieldId'] ?? '').toString(),
        fieldName: (json['fieldName'] ?? '').toString(),
        displayName: (json['displayName'] ?? '').toString(),
        value: (json['value'] ?? '').toString(),
        fieldTypeId: json['fieldTypeId']?.toString(),
        isPrimaryFilter: json['isPrimaryFilter'] as bool?,
      );
    }
    return UnitFieldValueModel(
      valueId: '',
      fieldId: '',
      fieldName: (json['fieldName'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
      fieldTypeId: json['fieldTypeId']?.toString(),
      isPrimaryFilter: json['isPrimaryFilter'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'valueId': valueId,
      'fieldId': fieldId,
      'fieldName': fieldName,
      'displayName': displayName,
      'value': value,
      'fieldTypeId': fieldTypeId,
      'isPrimaryFilter': isPrimaryFilter,
    };
  }
}

class FieldGroupWithValuesModel extends FieldGroupWithValues {
  const FieldGroupWithValuesModel({
    required super.groupId,
    required super.groupName,
    required super.displayName,
    required super.description,
    required super.fieldValues,
  });

  factory FieldGroupWithValuesModel.fromJson(Map<String, dynamic> json) {
    return FieldGroupWithValuesModel(
      groupId: (json['groupId'] ?? '').toString(),
      groupName: (json['groupName'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      fieldValues: (json['fieldValues'] as List?)
              ?.map((e) =>
                  UnitFieldValueModel.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'displayName': displayName,
      'description': description,
      'fieldValues':
          fieldValues.map((e) => (e as UnitFieldValueModel).toJson()).toList(),
    };
  }
}

class UnitImageModel extends UnitImage {
  const UnitImageModel({
    required super.id,
    required super.url,
    required super.caption,
    required super.isMain,
    required super.displayOrder,
    super.is360,
  });

  factory UnitImageModel.fromJson(Map<String, dynamic> json) {
    return UnitImageModel(
      id: (json['id'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      caption: (json['caption'] ?? '').toString(),
      isMain: (json['isMain'] ?? false) as bool,
      displayOrder: (json['displayOrder'] ?? 0) as int,
      is360: (json['is360'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'caption': caption,
      'isMain': isMain,
      'displayOrder': displayOrder,
      'is360': is360,
    };
  }
}
