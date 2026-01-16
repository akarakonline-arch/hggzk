import '../../domain/entities/policy.dart';

class PolicyModel extends Policy {
  const PolicyModel({
    required String id,
    required String propertyId,
    String? propertyName,
    required PolicyType type,
    required String description,
    String? rules,
    int cancellationWindowDays = 0,
    bool requireFullPaymentBeforeConfirmation = false,
    double minimumDepositPercentage = 0.0,
    int minHoursBeforeCheckIn = 0,
    bool? cancellationFreeCancel,
    bool? cancellationFullRefund,
    int? cancellationRefundPercentage,
    int? cancellationDaysBeforeCheckIn,
    int? cancellationHoursBeforeCheckIn,
    bool? cancellationNonRefundable,
    String? cancellationPenaltyAfterDeadline,
    bool? paymentDepositRequired,
    bool? paymentFullPaymentRequired,
    double? paymentDepositPercentage,
    bool? paymentAcceptCash,
    bool? paymentAcceptCard,
    bool? paymentPayAtProperty,
    bool? paymentCashPreferred,
    List<String>? paymentAcceptedMethods,
    String? checkInTime,
    String? checkOutTime,
    String? checkInFrom,
    String? checkInUntil,
    bool? checkInFlexible,
    bool? checkInFlexibleCheckIn,
    bool? checkInRequiresCoordination,
    bool? checkInContactOwner,
    String? checkInEarlyCheckInNote,
    String? checkInLateCheckOutNote,
    String? checkInLateCheckOutFee,
    bool? childrenAllowed,
    int? childrenFreeUnderAge,
    int? childrenHalfPriceUnderAge,
    int? childrenMaxChildrenPerRoom,
    int? childrenMaxChildren,
    String? childrenCribsNote,
    bool? childrenPlaygroundAvailable,
    bool? childrenKidsMenuAvailable,
    bool? petsAllowed,
    String? petsReason,
    double? petsFeeAmount,
    String? petsMaxWeight,
    bool? petsRequiresApproval,
    bool? petsNoFees,
    bool? petsPetFriendly,
    bool? petsOutdoorSpace,
    bool? petsStrict,
    bool? modificationAllowed,
    int? modificationFreeModificationHours,
    String? modificationFeesAfter,
    bool? modificationFlexible,
    String? modificationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) : super(
          id: id,
          propertyId: propertyId,
          propertyName: propertyName,
          type: type,
          description: description,
          rules: rules,
          cancellationWindowDays: cancellationWindowDays,
          requireFullPaymentBeforeConfirmation: requireFullPaymentBeforeConfirmation,
          minimumDepositPercentage: minimumDepositPercentage,
          minHoursBeforeCheckIn: minHoursBeforeCheckIn,
          cancellationFreeCancel: cancellationFreeCancel,
          cancellationFullRefund: cancellationFullRefund,
          cancellationRefundPercentage: cancellationRefundPercentage,
          cancellationDaysBeforeCheckIn: cancellationDaysBeforeCheckIn,
          cancellationHoursBeforeCheckIn: cancellationHoursBeforeCheckIn,
          cancellationNonRefundable: cancellationNonRefundable,
          cancellationPenaltyAfterDeadline: cancellationPenaltyAfterDeadline,
          paymentDepositRequired: paymentDepositRequired,
          paymentFullPaymentRequired: paymentFullPaymentRequired,
          paymentDepositPercentage: paymentDepositPercentage,
          paymentAcceptCash: paymentAcceptCash,
          paymentAcceptCard: paymentAcceptCard,
          paymentPayAtProperty: paymentPayAtProperty,
          paymentCashPreferred: paymentCashPreferred,
          paymentAcceptedMethods: paymentAcceptedMethods,
          checkInTime: checkInTime,
          checkOutTime: checkOutTime,
          checkInFrom: checkInFrom,
          checkInUntil: checkInUntil,
          checkInFlexible: checkInFlexible,
          checkInFlexibleCheckIn: checkInFlexibleCheckIn,
          checkInRequiresCoordination: checkInRequiresCoordination,
          checkInContactOwner: checkInContactOwner,
          checkInEarlyCheckInNote: checkInEarlyCheckInNote,
          checkInLateCheckOutNote: checkInLateCheckOutNote,
          checkInLateCheckOutFee: checkInLateCheckOutFee,
          childrenAllowed: childrenAllowed,
          childrenFreeUnderAge: childrenFreeUnderAge,
          childrenHalfPriceUnderAge: childrenHalfPriceUnderAge,
          childrenMaxChildrenPerRoom: childrenMaxChildrenPerRoom,
          childrenMaxChildren: childrenMaxChildren,
          childrenCribsNote: childrenCribsNote,
          childrenPlaygroundAvailable: childrenPlaygroundAvailable,
          childrenKidsMenuAvailable: childrenKidsMenuAvailable,
          petsAllowed: petsAllowed,
          petsReason: petsReason,
          petsFeeAmount: petsFeeAmount,
          petsMaxWeight: petsMaxWeight,
          petsRequiresApproval: petsRequiresApproval,
          petsNoFees: petsNoFees,
          petsPetFriendly: petsPetFriendly,
          petsOutdoorSpace: petsOutdoorSpace,
          petsStrict: petsStrict,
          modificationAllowed: modificationAllowed,
          modificationFreeModificationHours: modificationFreeModificationHours,
          modificationFeesAfter: modificationFeesAfter,
          modificationFlexible: modificationFlexible,
          modificationReason: modificationReason,
          createdAt: createdAt,
          updatedAt: updatedAt,
          isActive: isActive,
        );

  factory PolicyModel.fromJson(Map<String, dynamic> json) {
    try {
      final model = PolicyModel(
        id: (json['id'] ?? json['policyId'] ?? json['Id'] ?? '').toString(),
        propertyId: (json['propertyId'] ?? json['PropertyId'] ?? '').toString(),
        propertyName: json['propertyName'] ?? json['PropertyName'],
        type: _parsePolicyType(json['type'] ?? json['policyType'] ?? json['Type'] ?? json['PolicyType']),
        description: json['description'] ?? json['Description'] ?? '',
        rules: (json['rules'] ?? json['Rules'])?.toString(),
        cancellationWindowDays: json['cancellationWindowDays'] ?? json['CancellationWindowDays'] ?? 0,
        requireFullPaymentBeforeConfirmation: json['requireFullPaymentBeforeConfirmation'] ?? json['RequireFullPaymentBeforeConfirmation'] ?? false,
        minimumDepositPercentage: (json['minimumDepositPercentage'] ?? json['MinimumDepositPercentage'] ?? 0).toDouble(),
        minHoursBeforeCheckIn: json['minHoursBeforeCheckIn'] ?? json['MinHoursBeforeCheckIn'] ?? 0,
        cancellationFreeCancel: json['cancellationFreeCancel'] ?? json['CancellationFreeCancel'],
        cancellationFullRefund: json['cancellationFullRefund'] ?? json['CancellationFullRefund'],
        cancellationRefundPercentage: json['cancellationRefundPercentage'] ?? json['CancellationRefundPercentage'],
        cancellationDaysBeforeCheckIn: json['cancellationDaysBeforeCheckIn'] ?? json['CancellationDaysBeforeCheckIn'],
        cancellationHoursBeforeCheckIn: json['cancellationHoursBeforeCheckIn'] ?? json['CancellationHoursBeforeCheckIn'],
        cancellationNonRefundable: json['cancellationNonRefundable'] ?? json['CancellationNonRefundable'],
        cancellationPenaltyAfterDeadline: (json['cancellationPenaltyAfterDeadline'] ?? json['CancellationPenaltyAfterDeadline'])?.toString(),
        paymentDepositRequired: json['paymentDepositRequired'] ?? json['PaymentDepositRequired'],
        paymentFullPaymentRequired: json['paymentFullPaymentRequired'] ?? json['PaymentFullPaymentRequired'],
        paymentDepositPercentage: (json['paymentDepositPercentage'] ?? json['PaymentDepositPercentage'])?.toDouble(),
        paymentAcceptCash: json['paymentAcceptCash'] ?? json['PaymentAcceptCash'],
        paymentAcceptCard: json['paymentAcceptCard'] ?? json['PaymentAcceptCard'],
        paymentPayAtProperty: json['paymentPayAtProperty'] ?? json['PaymentPayAtProperty'],
        paymentCashPreferred: json['paymentCashPreferred'] ?? json['PaymentCashPreferred'],
        paymentAcceptedMethods: _parseStringList(json['paymentAcceptedMethods'] ?? json['PaymentAcceptedMethods']),
        checkInTime: (json['checkInTime'] ?? json['CheckInTime'])?.toString(),
        checkOutTime: (json['checkOutTime'] ?? json['CheckOutTime'])?.toString(),
        checkInFrom: (json['checkInFrom'] ?? json['CheckInFrom'])?.toString(),
        checkInUntil: (json['checkInUntil'] ?? json['CheckInUntil'])?.toString(),
        checkInFlexible: json['checkInFlexible'] ?? json['CheckInFlexible'],
        checkInFlexibleCheckIn: json['checkInFlexibleCheckIn'] ?? json['CheckInFlexibleCheckIn'],
        checkInRequiresCoordination: json['checkInRequiresCoordination'] ?? json['CheckInRequiresCoordination'],
        checkInContactOwner: json['checkInContactOwner'] ?? json['CheckInContactOwner'],
        checkInEarlyCheckInNote: (json['checkInEarlyCheckInNote'] ?? json['CheckInEarlyCheckInNote'])?.toString(),
        checkInLateCheckOutNote: (json['checkInLateCheckOutNote'] ?? json['CheckInLateCheckOutNote'])?.toString(),
        checkInLateCheckOutFee: (json['checkInLateCheckOutFee'] ?? json['CheckInLateCheckOutFee'])?.toString(),
        childrenAllowed: json['childrenAllowed'] ?? json['ChildrenAllowed'],
        childrenFreeUnderAge: json['childrenFreeUnderAge'] ?? json['ChildrenFreeUnderAge'],
        childrenHalfPriceUnderAge: json['childrenHalfPriceUnderAge'] ?? json['ChildrenHalfPriceUnderAge'],
        childrenMaxChildrenPerRoom: json['childrenMaxChildrenPerRoom'] ?? json['ChildrenMaxChildrenPerRoom'],
        childrenMaxChildren: json['childrenMaxChildren'] ?? json['ChildrenMaxChildren'],
        childrenCribsNote: (json['childrenCribsNote'] ?? json['ChildrenCribsNote'])?.toString(),
        childrenPlaygroundAvailable: json['childrenPlaygroundAvailable'] ?? json['ChildrenPlaygroundAvailable'],
        childrenKidsMenuAvailable: json['childrenKidsMenuAvailable'] ?? json['ChildrenKidsMenuAvailable'],
        petsAllowed: json['petsAllowed'] ?? json['PetsAllowed'],
        petsReason: (json['petsReason'] ?? json['PetsReason'])?.toString(),
        petsFeeAmount: (json['petsFeeAmount'] ?? json['PetsFeeAmount'])?.toDouble(),
        petsMaxWeight: (json['petsMaxWeight'] ?? json['PetsMaxWeight'])?.toString(),
        petsRequiresApproval: json['petsRequiresApproval'] ?? json['PetsRequiresApproval'],
        petsNoFees: json['petsNoFees'] ?? json['PetsNoFees'],
        petsPetFriendly: json['petsPetFriendly'] ?? json['PetsPetFriendly'],
        petsOutdoorSpace: json['petsOutdoorSpace'] ?? json['PetsOutdoorSpace'],
        petsStrict: json['petsStrict'] ?? json['PetsStrict'],
        modificationAllowed: json['modificationAllowed'] ?? json['ModificationAllowed'],
        modificationFreeModificationHours: json['modificationFreeModificationHours'] ?? json['ModificationFreeModificationHours'],
        modificationFeesAfter: (json['modificationFeesAfter'] ?? json['ModificationFeesAfter'])?.toString(),
        modificationFlexible: json['modificationFlexible'] ?? json['ModificationFlexible'],
        modificationReason: (json['modificationReason'] ?? json['ModificationReason'])?.toString(),
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : (json['CreatedAt'] != null ? DateTime.parse(json['CreatedAt']) : null),
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : (json['UpdatedAt'] != null ? DateTime.parse(json['UpdatedAt']) : null),
        isActive: json['isActive'] ?? json['IsActive'] ?? json['active'] ?? true,
      );
      
      return model;
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'propertyId': propertyId,
      if (propertyName != null) 'propertyName': propertyName,
      'type': type.apiValue,
      'description': description,
      if (rules != null) 'rules': rules,
      'cancellationWindowDays': cancellationWindowDays,
      'requireFullPaymentBeforeConfirmation': requireFullPaymentBeforeConfirmation,
      'minimumDepositPercentage': minimumDepositPercentage,
      'minHoursBeforeCheckIn': minHoursBeforeCheckIn,
      if (cancellationFreeCancel != null) 'cancellationFreeCancel': cancellationFreeCancel,
      if (cancellationFullRefund != null) 'cancellationFullRefund': cancellationFullRefund,
      if (cancellationRefundPercentage != null) 'cancellationRefundPercentage': cancellationRefundPercentage,
      if (cancellationDaysBeforeCheckIn != null) 'cancellationDaysBeforeCheckIn': cancellationDaysBeforeCheckIn,
      if (cancellationHoursBeforeCheckIn != null) 'cancellationHoursBeforeCheckIn': cancellationHoursBeforeCheckIn,
      if (cancellationNonRefundable != null) 'cancellationNonRefundable': cancellationNonRefundable,
      if (cancellationPenaltyAfterDeadline != null) 'cancellationPenaltyAfterDeadline': cancellationPenaltyAfterDeadline,
      if (paymentDepositRequired != null) 'paymentDepositRequired': paymentDepositRequired,
      if (paymentFullPaymentRequired != null) 'paymentFullPaymentRequired': paymentFullPaymentRequired,
      if (paymentDepositPercentage != null) 'paymentDepositPercentage': paymentDepositPercentage,
      if (paymentAcceptCash != null) 'paymentAcceptCash': paymentAcceptCash,
      if (paymentAcceptCard != null) 'paymentAcceptCard': paymentAcceptCard,
      if (paymentPayAtProperty != null) 'paymentPayAtProperty': paymentPayAtProperty,
      if (paymentCashPreferred != null) 'paymentCashPreferred': paymentCashPreferred,
      if (paymentAcceptedMethods != null) 'paymentAcceptedMethods': paymentAcceptedMethods,
      if (checkInTime != null) 'checkInTime': checkInTime,
      if (checkOutTime != null) 'checkOutTime': checkOutTime,
      if (checkInFrom != null) 'checkInFrom': checkInFrom,
      if (checkInUntil != null) 'checkInUntil': checkInUntil,
      if (checkInFlexible != null) 'checkInFlexible': checkInFlexible,
      if (checkInFlexibleCheckIn != null) 'checkInFlexibleCheckIn': checkInFlexibleCheckIn,
      if (checkInRequiresCoordination != null) 'checkInRequiresCoordination': checkInRequiresCoordination,
      if (checkInContactOwner != null) 'checkInContactOwner': checkInContactOwner,
      if (checkInEarlyCheckInNote != null) 'checkInEarlyCheckInNote': checkInEarlyCheckInNote,
      if (checkInLateCheckOutNote != null) 'checkInLateCheckOutNote': checkInLateCheckOutNote,
      if (checkInLateCheckOutFee != null) 'checkInLateCheckOutFee': checkInLateCheckOutFee,
      if (childrenAllowed != null) 'childrenAllowed': childrenAllowed,
      if (childrenFreeUnderAge != null) 'childrenFreeUnderAge': childrenFreeUnderAge,
      if (childrenHalfPriceUnderAge != null) 'childrenHalfPriceUnderAge': childrenHalfPriceUnderAge,
      if (childrenMaxChildrenPerRoom != null) 'childrenMaxChildrenPerRoom': childrenMaxChildrenPerRoom,
      if (childrenMaxChildren != null) 'childrenMaxChildren': childrenMaxChildren,
      if (childrenCribsNote != null) 'childrenCribsNote': childrenCribsNote,
      if (childrenPlaygroundAvailable != null) 'childrenPlaygroundAvailable': childrenPlaygroundAvailable,
      if (childrenKidsMenuAvailable != null) 'childrenKidsMenuAvailable': childrenKidsMenuAvailable,
      if (petsAllowed != null) 'petsAllowed': petsAllowed,
      if (petsReason != null) 'petsReason': petsReason,
      if (petsFeeAmount != null) 'petsFeeAmount': petsFeeAmount,
      if (petsMaxWeight != null) 'petsMaxWeight': petsMaxWeight,
      if (petsRequiresApproval != null) 'petsRequiresApproval': petsRequiresApproval,
      if (petsNoFees != null) 'petsNoFees': petsNoFees,
      if (petsPetFriendly != null) 'petsPetFriendly': petsPetFriendly,
      if (petsOutdoorSpace != null) 'petsOutdoorSpace': petsOutdoorSpace,
      if (petsStrict != null) 'petsStrict': petsStrict,
      if (modificationAllowed != null) 'modificationAllowed': modificationAllowed,
      if (modificationFreeModificationHours != null) 'modificationFreeModificationHours': modificationFreeModificationHours,
      if (modificationFeesAfter != null) 'modificationFeesAfter': modificationFeesAfter,
      if (modificationFlexible != null) 'modificationFlexible': modificationFlexible,
      if (modificationReason != null) 'modificationReason': modificationReason,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory PolicyModel.fromEntity(Policy entity) {
    return PolicyModel(
      id: entity.id,
      propertyId: entity.propertyId,
      propertyName: entity.propertyName,
      type: entity.type,
      description: entity.description,
      rules: entity.rules,
      cancellationWindowDays: entity.cancellationWindowDays,
      requireFullPaymentBeforeConfirmation: entity.requireFullPaymentBeforeConfirmation,
      minimumDepositPercentage: entity.minimumDepositPercentage,
      minHoursBeforeCheckIn: entity.minHoursBeforeCheckIn,
      cancellationFreeCancel: entity.cancellationFreeCancel,
      cancellationFullRefund: entity.cancellationFullRefund,
      cancellationRefundPercentage: entity.cancellationRefundPercentage,
      cancellationDaysBeforeCheckIn: entity.cancellationDaysBeforeCheckIn,
      cancellationHoursBeforeCheckIn: entity.cancellationHoursBeforeCheckIn,
      cancellationNonRefundable: entity.cancellationNonRefundable,
      cancellationPenaltyAfterDeadline: entity.cancellationPenaltyAfterDeadline,
      paymentDepositRequired: entity.paymentDepositRequired,
      paymentFullPaymentRequired: entity.paymentFullPaymentRequired,
      paymentDepositPercentage: entity.paymentDepositPercentage,
      paymentAcceptCash: entity.paymentAcceptCash,
      paymentAcceptCard: entity.paymentAcceptCard,
      paymentPayAtProperty: entity.paymentPayAtProperty,
      paymentCashPreferred: entity.paymentCashPreferred,
      paymentAcceptedMethods: entity.paymentAcceptedMethods,
      checkInTime: entity.checkInTime,
      checkOutTime: entity.checkOutTime,
      checkInFrom: entity.checkInFrom,
      checkInUntil: entity.checkInUntil,
      checkInFlexible: entity.checkInFlexible,
      checkInFlexibleCheckIn: entity.checkInFlexibleCheckIn,
      checkInRequiresCoordination: entity.checkInRequiresCoordination,
      checkInContactOwner: entity.checkInContactOwner,
      checkInEarlyCheckInNote: entity.checkInEarlyCheckInNote,
      checkInLateCheckOutNote: entity.checkInLateCheckOutNote,
      checkInLateCheckOutFee: entity.checkInLateCheckOutFee,
      childrenAllowed: entity.childrenAllowed,
      childrenFreeUnderAge: entity.childrenFreeUnderAge,
      childrenHalfPriceUnderAge: entity.childrenHalfPriceUnderAge,
      childrenMaxChildrenPerRoom: entity.childrenMaxChildrenPerRoom,
      childrenMaxChildren: entity.childrenMaxChildren,
      childrenCribsNote: entity.childrenCribsNote,
      childrenPlaygroundAvailable: entity.childrenPlaygroundAvailable,
      childrenKidsMenuAvailable: entity.childrenKidsMenuAvailable,
      petsAllowed: entity.petsAllowed,
      petsReason: entity.petsReason,
      petsFeeAmount: entity.petsFeeAmount,
      petsMaxWeight: entity.petsMaxWeight,
      petsRequiresApproval: entity.petsRequiresApproval,
      petsNoFees: entity.petsNoFees,
      petsPetFriendly: entity.petsPetFriendly,
      petsOutdoorSpace: entity.petsOutdoorSpace,
      petsStrict: entity.petsStrict,
      modificationAllowed: entity.modificationAllowed,
      modificationFreeModificationHours: entity.modificationFreeModificationHours,
      modificationFeesAfter: entity.modificationFeesAfter,
      modificationFlexible: entity.modificationFlexible,
      modificationReason: entity.modificationReason,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isActive: entity.isActive,
    );
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [value.toString()];
  }

  static PolicyType _parsePolicyType(dynamic value) {
    if (value == null) return PolicyType.cancellation;
    
    if (value is int) {
      switch (value) {
        case 0:
          return PolicyType.cancellation;
        case 1:
          return PolicyType.checkIn;
        case 2:
          return PolicyType.children;
        case 3:
          return PolicyType.pets;
        case 4:
          return PolicyType.payment;
        case 5:
          return PolicyType.modification;
        default:
          return PolicyType.cancellation;
      }
    }
    
    return PolicyType.fromString(value.toString());
  }
}

/// 📊 Model لإحصائيات السياسات
class PolicyStatsModel {
  final int totalPolicies;
  final int activePolicies;
  final int policiesByType;
  final Map<String, int> policyTypeDistribution;
  final double averageCancellationWindow;

  PolicyStatsModel({
    required this.totalPolicies,
    required this.activePolicies,
    required this.policiesByType,
    required this.policyTypeDistribution,
    required this.averageCancellationWindow,
  });

  factory PolicyStatsModel.fromJson(Map<String, dynamic> json) {
    return PolicyStatsModel(
      totalPolicies: json['totalPolicies'] ?? 0,
      activePolicies: json['activePolicies'] ?? 0,
      policiesByType: json['policiesByType'] ?? 0,
      policyTypeDistribution: Map<String, int>.from(json['policyTypeDistribution'] ?? {}),
      averageCancellationWindow: (json['averageCancellationWindow'] ?? 0).toDouble(),
    );
  }

  PolicyStats toEntity() {
    return PolicyStats(
      totalPolicies: totalPolicies,
      activePolicies: activePolicies,
      policiesByType: policiesByType,
      policyTypeDistribution: policyTypeDistribution,
      averageCancellationWindow: averageCancellationWindow,
    );
  }
}
