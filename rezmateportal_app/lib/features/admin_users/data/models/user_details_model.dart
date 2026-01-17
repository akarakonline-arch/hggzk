import 'package:rezmateportal/core/enums/payment_method_enum.dart';
import '../../domain/entities/user_details.dart';

class UserWalletAccountModel extends UserWalletAccount {
  const UserWalletAccountModel({
    required super.id,
    required super.walletType,
    required super.accountNumber,
    super.accountName,
    required super.isDefault,
  });

  factory UserWalletAccountModel.fromJson(Map<String, dynamic> json) {
    final walletTypeRaw = json['walletType'];
    PaymentMethod parsedWalletType;
    if (walletTypeRaw is num) {
      parsedWalletType = PaymentMethodExtension.fromBackendValue(walletTypeRaw.toInt());
    } else if (walletTypeRaw is String) {
      final asInt = int.tryParse(walletTypeRaw);
      parsedWalletType = asInt != null
          ? PaymentMethodExtension.fromBackendValue(asInt)
          : PaymentMethodExtension.fromString(walletTypeRaw);
    } else {
      parsedWalletType = PaymentMethod.cash;
    }

    return UserWalletAccountModel(
      id: (json['id'] ?? '').toString(),
      walletType: parsedWalletType,
      accountNumber: (json['accountNumber'] ?? '').toString(),
      accountName: json['accountName']?.toString(),
      isDefault: (json['isDefault'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'walletType': walletType.backendValue,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'isDefault': isDefault,
    };
  }
}

class UserDetailsModel extends UserDetails {
  const UserDetailsModel({
    required String id,
    required String userName,
    String? avatarUrl,
    required String email,
    required String phoneNumber,
    required DateTime createdAt,
    required bool isActive,
    DateTime? lastSeen,
    DateTime? lastLoginDate,
    required int bookingsCount,
    required int canceledBookingsCount,
    required int pendingBookingsCount,
    DateTime? firstBookingDate,
    DateTime? lastBookingDate,
    required int reportsCreatedCount,
    required int reportsAgainstCount,
    required double totalPayments,
    required double totalRefunds,
    required int reviewsCount,
    int? loyaltyPoints,
    String? role,
    String? propertyId,
    String? propertyName,
    int? unitsCount,
    int? propertyImagesCount,
    int? unitImagesCount,
    double? netRevenue,
    int? repliesCount,
    List<UserWalletAccount>? walletAccounts,
  }) : super(
          id: id,
          userName: userName,
          avatarUrl: avatarUrl,
          email: email,
          phoneNumber: phoneNumber,
          createdAt: createdAt,
          isActive: isActive,
          lastSeen: lastSeen,
          lastLoginDate: lastLoginDate,
          bookingsCount: bookingsCount,
          canceledBookingsCount: canceledBookingsCount,
          pendingBookingsCount: pendingBookingsCount,
          firstBookingDate: firstBookingDate,
          lastBookingDate: lastBookingDate,
          reportsCreatedCount: reportsCreatedCount,
          reportsAgainstCount: reportsAgainstCount,
          totalPayments: totalPayments,
          totalRefunds: totalRefunds,
          reviewsCount: reviewsCount,
          loyaltyPoints: loyaltyPoints,
          role: role,
          propertyId: propertyId,
          propertyName: propertyName,
          unitsCount: unitsCount,
          propertyImagesCount: propertyImagesCount,
          unitImagesCount: unitImagesCount,
          netRevenue: netRevenue,
          repliesCount: repliesCount,
          walletAccounts: walletAccounts ?? const [],
        );

  factory UserDetailsModel.fromJson(Map<String, dynamic> json) {
    final accountsJson = json['walletAccounts'];
    final walletAccounts = (accountsJson is List)
        ? accountsJson
            .whereType<Map>()
            .map((e) => UserWalletAccountModel.fromJson(
                e.map((k, v) => MapEntry(k.toString(), v))))
            .toList()
        : <UserWalletAccountModel>[];
    return UserDetailsModel(
      id: json['id'] as String,
      userName: json['userName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool,
      lastSeen: json['lastSeen'] != null
          ? DateTime.tryParse(json['lastSeen'].toString())
          : null,
      lastLoginDate: json['lastLoginDate'] != null
          ? DateTime.tryParse(json['lastLoginDate'].toString())
          : null,
      bookingsCount: json['bookingsCount'] as int,
      canceledBookingsCount: json['canceledBookingsCount'] as int,
      pendingBookingsCount: json['pendingBookingsCount'] as int,
      firstBookingDate: json['firstBookingDate'] != null
          ? DateTime.parse(json['firstBookingDate'] as String)
          : null,
      lastBookingDate: json['lastBookingDate'] != null
          ? DateTime.parse(json['lastBookingDate'] as String)
          : null,
      reportsCreatedCount: json['reportsCreatedCount'] as int,
      reportsAgainstCount: json['reportsAgainstCount'] as int,
      totalPayments: (json['totalPayments'] as num).toDouble(),
      totalRefunds: (json['totalRefunds'] as num).toDouble(),
      reviewsCount: json['reviewsCount'] as int,
      loyaltyPoints: json['loyaltyPoints'] as int?,
      role: json['role'] as String?,
      propertyId: json['propertyId'] as String?,
      propertyName: json['propertyName'] as String?,
      unitsCount: json['unitsCount'] as int?,
      propertyImagesCount: json['propertyImagesCount'] as int?,
      unitImagesCount: json['unitImagesCount'] as int?,
      netRevenue: json['netRevenue'] != null
          ? (json['netRevenue'] as num).toDouble()
          : null,
      repliesCount: json['repliesCount'] as int?,
      walletAccounts: walletAccounts,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'avatarUrl': avatarUrl,
      'email': email,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'lastSeen': lastSeen?.toIso8601String(),
      'lastLoginDate': lastLoginDate?.toIso8601String(),
      'bookingsCount': bookingsCount,
      'canceledBookingsCount': canceledBookingsCount,
      'pendingBookingsCount': pendingBookingsCount,
      'firstBookingDate': firstBookingDate?.toIso8601String(),
      'lastBookingDate': lastBookingDate?.toIso8601String(),
      'reportsCreatedCount': reportsCreatedCount,
      'reportsAgainstCount': reportsAgainstCount,
      'totalPayments': totalPayments,
      'totalRefunds': totalRefunds,
      'reviewsCount': reviewsCount,
      'loyaltyPoints': loyaltyPoints,
      'role': role,
      'propertyId': propertyId,
      'propertyName': propertyName,
      'unitsCount': unitsCount,
      'propertyImagesCount': propertyImagesCount,
      'unitImagesCount': unitImagesCount,
      'netRevenue': netRevenue,
      'repliesCount': repliesCount,
      'walletAccounts': walletAccounts
          .map((e) => UserWalletAccountModel(
                id: e.id,
                walletType: e.walletType,
                accountNumber: e.accountNumber,
                accountName: e.accountName,
                isDefault: e.isDefault,
              ).toJson())
          .toList(),
    };
  }
}