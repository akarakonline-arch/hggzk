import '../../domain/entities/user.dart';
import 'package:hggzkportal/core/enums/payment_method_enum.dart';
import 'package:hggzkportal/features/admin_users/domain/entities/user_details.dart'
    show UserWalletAccount;

class UserModel extends User {
  const UserModel({
    required super.userId,
    required super.name,
    required super.email,
    required super.phone,
    required super.roles,
    super.accountRole,
    super.propertyId,
    super.propertyName,
    super.propertyCurrency,
    super.profileImage,
    super.emailVerifiedAt,
    super.phoneVerifiedAt,
    super.walletAccounts,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final accountsJson = json['walletAccounts'];
    final walletAccounts = (accountsJson is List)
        ? accountsJson
            .map((e) => e is Map ? e : null)
            .whereType<Map>()
            .map((m) {
              final map = m.map((k, v) => MapEntry(k.toString(), v));
              final raw = map['walletType'];
              PaymentMethod parsed;
              if (raw is num) {
                parsed = PaymentMethodExtension.fromBackendValue(raw.toInt());
              } else if (raw is String) {
                final asInt = int.tryParse(raw);
                parsed = asInt != null
                    ? PaymentMethodExtension.fromBackendValue(asInt)
                    : PaymentMethodExtension.fromString(raw);
              } else {
                parsed = PaymentMethod.cash;
              }

              return UserWalletAccount(
                id: (map['id'] ?? '').toString(),
                walletType: parsed,
                accountNumber: (map['accountNumber'] ?? '').toString(),
                accountName: map['accountName']?.toString(),
                isDefault: (map['isDefault'] as bool?) ?? false,
              );
            })
            .toList()
        : <UserWalletAccount>[];

    return UserModel(
      userId: (json['userId'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? json['userName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? json['phoneNumber'] ?? '').toString(),
      roles: json['roles'] != null
          ? List<String>.from(json['roles'])
          : json['role'] != null
              ? [json['role'].toString()]
              : <String>[],
      accountRole:
          (json['accountRole'] ?? json['account_role'] ?? json['role'] ?? '')
              .toString(),
      propertyId: (json['propertyId'] ?? json['property_id'])?.toString(),
      propertyName: (json['propertyName'] ?? json['property_name'])?.toString(),
      propertyCurrency: (json['propertyCurrency'] ??
              json['property_currency'] ??
              json['currency'])
          ?.toString(),
      profileImage: json['profileImage'] ??
          json['profile_image'] ??
          json['profileImageUrl'],
      emailVerifiedAt: json['emailVerifiedAt'] != null
          ? DateTime.tryParse(json['emailVerifiedAt'])
          : json['email_verified_at'] != null
              ? DateTime.tryParse(json['email_verified_at'])
              : null,
      phoneVerifiedAt: json['phoneVerifiedAt'] != null
          ? DateTime.tryParse(json['phoneVerifiedAt'])
          : json['phone_verified_at'] != null
              ? DateTime.tryParse(json['phone_verified_at'])
              : null,
      walletAccounts: walletAccounts,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : json['created_at'] != null
              ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
              : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : json['updated_at'] != null
              ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'roles': roles,
      'accountRole': accountRole,
      'propertyId': propertyId,
      'propertyName': propertyName,
      'propertyCurrency': propertyCurrency,
      'profileImage': profileImage,
      'emailVerifiedAt': emailVerifiedAt?.toIso8601String(),
      'phoneVerifiedAt': phoneVerifiedAt?.toIso8601String(),
      'walletAccounts': walletAccounts
          .map((e) => {
                'id': e.id,
                'walletType': e.walletType.backendValue,
                'accountNumber': e.accountNumber,
                'accountName': e.accountName,
                'isDefault': e.isDefault,
              })
          .toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      userId: user.userId,
      name: user.name,
      email: user.email,
      phone: user.phone,
      roles: user.roles,
      profileImage: user.profileImage,
      emailVerifiedAt: user.emailVerifiedAt,
      phoneVerifiedAt: user.phoneVerifiedAt,
      walletAccounts: user.walletAccounts,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }
}
