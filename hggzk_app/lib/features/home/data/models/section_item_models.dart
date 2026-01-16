// lib/features/home/data/models/section_item_models.dart

import 'package:equatable/equatable.dart';

class SectionImageModel extends Equatable {
  final String id;
  final String url;
  final bool isMain;
  final int displayOrder;
  final String? name;
  final String? caption;
  final String? altText;
  final DateTime? uploadedAt;
   final bool is360;

  const SectionImageModel({
    required this.id,
    required this.url,
    required this.isMain,
    required this.displayOrder,
    this.name,
    this.caption,
    this.altText,
    this.uploadedAt,
    this.is360 = false,
  });

  factory SectionImageModel.fromJson(Map<String, dynamic> json) {
    return SectionImageModel(
      id: (json['id'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      isMain: json['isMain'] == true || json['isMainImage'] == true,
      displayOrder: (json['displayOrder'] ?? 0) is int
          ? json['displayOrder']
          : int.tryParse((json['displayOrder'] ?? '0').toString()) ?? 0,
      name: json['name']?.toString(),
      caption: json['caption']?.toString(),
      altText: json['altText']?.toString(),
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'].toString())
          : null,
      is360: json['is360'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'isMain': isMain,
      'displayOrder': displayOrder,
      if (name != null) 'name': name,
      if (caption != null) 'caption': caption,
      if (altText != null) 'altText': altText,
      if (uploadedAt != null) 'uploadedAt': uploadedAt!.toIso8601String(),
      'is360': is360,
    };
  }

  @override
  List<Object?> get props => [id, url, isMain, displayOrder, name, caption, altText, uploadedAt, is360];
}

class SectionPropertyItemModel extends Equatable {
  final String id; // propertyId
  final String propertyInSectionId;
  final String name;
  final String description;
  final String address;
  final String city;
  final int starRating;
  final double averageRating;
  final int reviewsCount;
  final double minPrice;
  final double discountedPrice;
  final String currency;
  final String? mainImageUrl;
  final String? mainImageId;
  final List<String> imageUrls;
  final List<SectionImageModel> additionalImages;
  final String propertyType;
  final bool isFeatured;
  final bool isAvailable;
  final int availableUnitsCount;
  final int maxCapacity;
  final double latitude;
  final double longitude;
  final DateTime lastUpdated;
  final Map<String, dynamic> dynamicFieldValues;

  const SectionPropertyItemModel({
    required this.id,
    required this.propertyInSectionId,
    required this.name,
    required this.description,
    required this.address,
    required this.city,
    required this.starRating,
    required this.averageRating,
    required this.reviewsCount,
    required this.minPrice,
    required this.discountedPrice,
    required this.currency,
    required this.mainImageUrl,
    required this.mainImageId,
    required this.imageUrls,
    required this.additionalImages,
    required this.propertyType,
    required this.isFeatured,
    required this.isAvailable,
    required this.availableUnitsCount,
    required this.maxCapacity,
    required this.latitude,
    required this.longitude,
    required this.lastUpdated,
    this.dynamicFieldValues = const {},
  });

  factory SectionPropertyItemModel.fromJson(Map<String, dynamic> json) {
    final images = (json['additionalImages'] as List?)
            ?.map((e) => SectionImageModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <SectionImageModel>[];

    return SectionPropertyItemModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      propertyInSectionId:
          (json['propertyInSectionId'] ?? json['PropertyInSectionId'] ?? '')
              .toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      address:
          (json['address'] ?? json['Address'] ?? '').toString(),
      city: (json['city'] ?? json['City'] ?? '').toString(),
      starRating: int.tryParse(
              (json['starRating'] ??
                      json['StarRating'] ??
                      json['propertyStarRating'] ??
                      json['PropertyStarRating'] ??
                      '0')
                  .toString()) ??
          0,
      averageRating: ((json['averageRating'] ??
                  json['AverageRating'] ??
                  json['propertyAverageRating'] ??
                  json['PropertyAverageRating'] ??
                  0) as num)
          .toDouble(),
      reviewsCount: int.tryParse((json['reviewCount'] ?? json['reviewsCount'] ?? '0').toString()) ?? 0,
      minPrice: ((json['minPrice'] ?? 0) as num).toDouble(),
      discountedPrice: ((json['discountedPrice'] ?? 0) as num).toDouble(),
      currency: (json['currency'] ?? 'YER').toString(),
      mainImageUrl: json['mainImageUrl']?.toString(),
      mainImageId: json['mainImageId']?.toString(),
      imageUrls: List<String>.from(json['imageUrls'] ?? const []),
      additionalImages: images,
      propertyType: (json['propertyType'] ??
              json['PropertyType'] ??
              json['unitTypeName'] ??
              json['UnitTypeName'] ??
              '')
          .toString(),
      isFeatured: (json['isFeatured'] ?? false) == true,
      isAvailable: (json['isAvailable'] ?? true) == true,
      availableUnitsCount: int.tryParse((json['availableUnitsCount'] ?? '0').toString()) ?? 0,
      maxCapacity: int.tryParse((json['maxCapacity'] ?? '0').toString()) ?? 0,
      latitude: ((json['latitude'] ?? 0) as num).toDouble(),
      longitude: ((json['longitude'] ?? 0) as num).toDouble(),
      lastUpdated: DateTime.tryParse((json['lastUpdated'] ?? DateTime.now().toIso8601String()).toString()) ?? DateTime.now(),
      dynamicFieldValues: Map<String, dynamic>.from(json['dynamicFieldValues'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyInSectionId': propertyInSectionId,
      'name': name,
      'description': description,
      'address': address,
      'city': city,
      'starRating': starRating,
      'averageRating': averageRating,
      'reviewsCount': reviewsCount,
      'minPrice': minPrice,
      'discountedPrice': discountedPrice,
      'currency': currency,
      'mainImageUrl': mainImageUrl,
      'mainImageId': mainImageId,
      'imageUrls': imageUrls,
      'additionalImages': additionalImages.map((e) => e.toJson()).toList(),
      'propertyType': propertyType,
      'isFeatured': isFeatured,
      'isAvailable': isAvailable,
      'availableUnitsCount': availableUnitsCount,
      'maxCapacity': maxCapacity,
      'latitude': latitude,
      'longitude': longitude,
      'lastUpdated': lastUpdated.toIso8601String(),
      'dynamicFieldValues': dynamicFieldValues,
    };
  }

  // UI helpers matching previous SearchResultModel getters
  String? get imageUrl => mainImageUrl ?? (imageUrls.isNotEmpty ? imageUrls.first : null);
  String? get location => address.isNotEmpty ? address : city;
  double? get price => (discountedPrice > 0 ? discountedPrice : minPrice);
  double? get rating => averageRating;
  int? get discount {
    if (minPrice > 0 && discountedPrice > 0 && discountedPrice < minPrice) {
      final pct = ((minPrice - discountedPrice) / minPrice) * 100;
      return pct.round();
    }
    return null;
  }
  int? get bedrooms {
    final v = dynamicFieldValues['bedrooms'] ?? dynamicFieldValues['numBedrooms'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }
  int? get bathrooms {
    final v = dynamicFieldValues['bathrooms'] ?? dynamicFieldValues['numBathrooms'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }
  double? get area {
    final v = dynamicFieldValues['area'] ?? dynamicFieldValues['size'];
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
  int get propertiesCount {
    final v = dynamicFieldValues['propertiesCount'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  @override
  List<Object?> get props => [id, propertyInSectionId, name, description, address, city, starRating, averageRating, reviewsCount, minPrice, discountedPrice, currency, mainImageUrl, mainImageId, imageUrls, additionalImages, propertyType, isFeatured, isAvailable, availableUnitsCount, maxCapacity, latitude, longitude, lastUpdated, dynamicFieldValues];
}

class SectionUnitItemModel extends Equatable {
  final String id; // unitId
  final String unitInSectionId;
  final String name; // unit name
  final String propertyId;
  final String? unitTypeId;
  final bool isAvailable;
  final int maxCapacity;
  final String? mainImageUrl;
  final String? mainImageId;
  final List<String> imageUrls;
  final List<SectionImageModel> additionalImages;
  final double minPrice;
  final double discountedPrice;
  final String address;
  final String city;
  final int propertyStarRating;
  final double propertyAverageRating;
  final String? unitTypeName;

  const SectionUnitItemModel({
    required this.id,
    required this.unitInSectionId,
    required this.name,
    required this.propertyId,
    this.unitTypeId,
    required this.isAvailable,
    required this.maxCapacity,
    required this.mainImageUrl,
    required this.mainImageId,
    required this.imageUrls,
    required this.additionalImages,
    required this.minPrice,
    required this.discountedPrice,
    this.address = '',
    this.city = '',
    this.propertyStarRating = 0,
    this.propertyAverageRating = 0,
    this.unitTypeName,
  });

  factory SectionUnitItemModel.fromJson(Map<String, dynamic> json) {
    final images = (json['additionalImages'] as List?)
            ?.map((e) => SectionImageModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <SectionImageModel>[];

    return SectionUnitItemModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      unitInSectionId:
          (json['unitInSectionId'] ?? json['UnitInSectionId'] ?? '')
              .toString(),
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      propertyId: (json['propertyId'] ?? '').toString(),
      unitTypeId: json['unitTypeId']?.toString(),
      isAvailable: (json['isAvailable'] ?? true) == true,
      maxCapacity: int.tryParse((json['maxCapacity'] ?? '0').toString()) ?? 0,
      mainImageUrl: json['mainImageUrl']?.toString(),
      mainImageId: json['mainImageId']?.toString(),
      imageUrls: List<String>.from(json['imageUrls'] ?? const []),
      additionalImages: images,
      minPrice: ((json['minPrice'] ?? 0) as num).toDouble(),
      discountedPrice: ((json['discountedPrice'] ?? 0) as num).toDouble(),
      address: (json['address'] ??
              json['Address'] ??
              json['propertyAddress'] ??
              json['PropertyAddress'] ??
              '')
          .toString(),
      city: (json['city'] ??
              json['City'] ??
              json['propertyCity'] ??
              json['PropertyCity'] ??
              '')
          .toString(),
      propertyStarRating: int.tryParse(
              (json['propertyStarRating'] ??
                      json['PropertyStarRating'] ??
                      '0')
                  .toString()) ??
          0,
      propertyAverageRating: ((json['propertyAverageRating'] ??
                  json['PropertyAverageRating'] ??
                  0) as num)
          .toDouble(),
      unitTypeName:
          (json['unitTypeName'] ?? json['UnitTypeName'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unitInSectionId': unitInSectionId,
      'name': name,
      'propertyId': propertyId,
      if (unitTypeId != null) 'unitTypeId': unitTypeId,
      'isAvailable': isAvailable,
      'maxCapacity': maxCapacity,
      'mainImageUrl': mainImageUrl,
      'mainImageId': mainImageId,
      'imageUrls': imageUrls,
      'additionalImages': additionalImages.map((e) => e.toJson()).toList(),
      'minPrice': minPrice,
      'discountedPrice': discountedPrice,
      'address': address,
      'city': city,
      'propertyStarRating': propertyStarRating,
      'propertyAverageRating': propertyAverageRating,
      if (unitTypeName != null) 'unitTypeName': unitTypeName,
    };
  }

  // UI helpers
  String? get imageUrl => mainImageUrl ?? (imageUrls.isNotEmpty ? imageUrls.first : null);
  double? get price => (discountedPrice > 0 ? discountedPrice : minPrice);
  int? get discount {
    if (minPrice > 0 && discountedPrice > 0 && discountedPrice < minPrice) {
      final pct = ((minPrice - discountedPrice) / minPrice) * 100;
      return pct.round();
    }
    return null;
  }

  String? get location =>
      address.isNotEmpty ? address : (city.isNotEmpty ? city : null);

  double? get rating =>
      propertyAverageRating > 0 ? propertyAverageRating : null;

  @override
  List<Object?> get props => [
        id,
        unitInSectionId,
        name,
        propertyId,
        unitTypeId,
        isAvailable,
        maxCapacity,
        mainImageUrl,
        mainImageId,
        imageUrls,
        additionalImages,
        minPrice,
        discountedPrice,
        address,
        city,
        propertyStarRating,
        propertyAverageRating,
        unitTypeName,
      ];
}
