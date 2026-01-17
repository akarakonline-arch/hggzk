import 'package:equatable/equatable.dart';
import '../../domain/entities/policy.dart';

abstract class PoliciesEvent extends Equatable {
  const PoliciesEvent();

  @override
  List<Object?> get props => [];
}

/// تحميل السياسات
class LoadPoliciesEvent extends PoliciesEvent {
  final int pageNumber;
  final int pageSize;
  final String? searchTerm;
  final String? propertyId;
  final PolicyType? policyType;

  const LoadPoliciesEvent({
    this.pageNumber = 1,
    this.pageSize = 20,
    this.searchTerm,
    this.propertyId,
    this.policyType,
  });

  @override
  List<Object?> get props => [pageNumber, pageSize, searchTerm, propertyId, policyType];
}

/// إنشاء سياسة جديدة
class CreatePolicyEvent extends PoliciesEvent {
  final String propertyId;
  final PolicyType type;
  final String description;
  final String? rules;
  final int cancellationWindowDays;
  final bool requireFullPaymentBeforeConfirmation;
  final double minimumDepositPercentage;
  final int minHoursBeforeCheckIn;

  final bool? cancellationFreeCancel;
  final bool? cancellationFullRefund;
  final int? cancellationRefundPercentage;
  final int? cancellationDaysBeforeCheckIn;
  final int? cancellationHoursBeforeCheckIn;
  final bool? cancellationNonRefundable;
  final String? cancellationPenaltyAfterDeadline;

  final bool? paymentDepositRequired;
  final bool? paymentFullPaymentRequired;
  final double? paymentDepositPercentage;
  final bool? paymentAcceptCash;
  final bool? paymentAcceptCard;
  final bool? paymentPayAtProperty;
  final bool? paymentCashPreferred;
  final List<String>? paymentAcceptedMethods;

  final String? checkInTime;
  final String? checkOutTime;
  final String? checkInFrom;
  final String? checkInUntil;
  final bool? checkInFlexible;
  final bool? checkInFlexibleCheckIn;
  final bool? checkInRequiresCoordination;
  final bool? checkInContactOwner;
  final String? checkInEarlyCheckInNote;
  final String? checkInLateCheckOutNote;
  final String? checkInLateCheckOutFee;

  final bool? childrenAllowed;
  final int? childrenFreeUnderAge;
  final int? childrenHalfPriceUnderAge;
  final int? childrenMaxChildrenPerRoom;
  final int? childrenMaxChildren;
  final String? childrenCribsNote;
  final bool? childrenPlaygroundAvailable;
  final bool? childrenKidsMenuAvailable;

  final bool? petsAllowed;
  final String? petsReason;
  final double? petsFeeAmount;
  final String? petsMaxWeight;
  final bool? petsRequiresApproval;
  final bool? petsNoFees;
  final bool? petsPetFriendly;
  final bool? petsOutdoorSpace;
  final bool? petsStrict;

  final bool? modificationAllowed;
  final int? modificationFreeModificationHours;
  final String? modificationFeesAfter;
  final bool? modificationFlexible;
  final String? modificationReason;

  const CreatePolicyEvent({
    required this.propertyId,
    required this.type,
    required this.description,
    this.rules,
    this.cancellationWindowDays = 0,
    this.requireFullPaymentBeforeConfirmation = false,
    this.minimumDepositPercentage = 0.0,
    this.minHoursBeforeCheckIn = 0,

    this.cancellationFreeCancel,
    this.cancellationFullRefund,
    this.cancellationRefundPercentage,
    this.cancellationDaysBeforeCheckIn,
    this.cancellationHoursBeforeCheckIn,
    this.cancellationNonRefundable,
    this.cancellationPenaltyAfterDeadline,

    this.paymentDepositRequired,
    this.paymentFullPaymentRequired,
    this.paymentDepositPercentage,
    this.paymentAcceptCash,
    this.paymentAcceptCard,
    this.paymentPayAtProperty,
    this.paymentCashPreferred,
    this.paymentAcceptedMethods,

    this.checkInTime,
    this.checkOutTime,
    this.checkInFrom,
    this.checkInUntil,
    this.checkInFlexible,
    this.checkInFlexibleCheckIn,
    this.checkInRequiresCoordination,
    this.checkInContactOwner,
    this.checkInEarlyCheckInNote,
    this.checkInLateCheckOutNote,
    this.checkInLateCheckOutFee,

    this.childrenAllowed,
    this.childrenFreeUnderAge,
    this.childrenHalfPriceUnderAge,
    this.childrenMaxChildrenPerRoom,
    this.childrenMaxChildren,
    this.childrenCribsNote,
    this.childrenPlaygroundAvailable,
    this.childrenKidsMenuAvailable,

    this.petsAllowed,
    this.petsReason,
    this.petsFeeAmount,
    this.petsMaxWeight,
    this.petsRequiresApproval,
    this.petsNoFees,
    this.petsPetFriendly,
    this.petsOutdoorSpace,
    this.petsStrict,

    this.modificationAllowed,
    this.modificationFreeModificationHours,
    this.modificationFeesAfter,
    this.modificationFlexible,
    this.modificationReason,
  });

  @override
  List<Object?> get props => [
        propertyId,
        type,
        description,
        rules,
        cancellationWindowDays,
        requireFullPaymentBeforeConfirmation,
        minimumDepositPercentage,
        minHoursBeforeCheckIn,
        cancellationFreeCancel,
        cancellationFullRefund,
        cancellationRefundPercentage,
        cancellationDaysBeforeCheckIn,
        cancellationHoursBeforeCheckIn,
        cancellationNonRefundable,
        cancellationPenaltyAfterDeadline,
        paymentDepositRequired,
        paymentFullPaymentRequired,
        paymentDepositPercentage,
        paymentAcceptCash,
        paymentAcceptCard,
        paymentPayAtProperty,
        paymentCashPreferred,
        paymentAcceptedMethods,
        checkInTime,
        checkOutTime,
        checkInFrom,
        checkInUntil,
        checkInFlexible,
        checkInFlexibleCheckIn,
        checkInRequiresCoordination,
        checkInContactOwner,
        checkInEarlyCheckInNote,
        checkInLateCheckOutNote,
        checkInLateCheckOutFee,
        childrenAllowed,
        childrenFreeUnderAge,
        childrenHalfPriceUnderAge,
        childrenMaxChildrenPerRoom,
        childrenMaxChildren,
        childrenCribsNote,
        childrenPlaygroundAvailable,
        childrenKidsMenuAvailable,
        petsAllowed,
        petsReason,
        petsFeeAmount,
        petsMaxWeight,
        petsRequiresApproval,
        petsNoFees,
        petsPetFriendly,
        petsOutdoorSpace,
        petsStrict,
        modificationAllowed,
        modificationFreeModificationHours,
        modificationFeesAfter,
        modificationFlexible,
        modificationReason,
      ];
}

/// تحديث سياسة
class UpdatePolicyEvent extends PoliciesEvent {
  final String policyId;
  final PolicyType type;
  final String description;
  final String? rules;
  final int? cancellationWindowDays;
  final bool? requireFullPaymentBeforeConfirmation;
  final double? minimumDepositPercentage;
  final int? minHoursBeforeCheckIn;

  final bool? cancellationFreeCancel;
  final bool? cancellationFullRefund;
  final int? cancellationRefundPercentage;
  final int? cancellationDaysBeforeCheckIn;
  final int? cancellationHoursBeforeCheckIn;
  final bool? cancellationNonRefundable;
  final String? cancellationPenaltyAfterDeadline;

  final bool? paymentDepositRequired;
  final bool? paymentFullPaymentRequired;
  final double? paymentDepositPercentage;
  final bool? paymentAcceptCash;
  final bool? paymentAcceptCard;
  final bool? paymentPayAtProperty;
  final bool? paymentCashPreferred;
  final List<String>? paymentAcceptedMethods;

  final String? checkInTime;
  final String? checkOutTime;
  final String? checkInFrom;
  final String? checkInUntil;
  final bool? checkInFlexible;
  final bool? checkInFlexibleCheckIn;
  final bool? checkInRequiresCoordination;
  final bool? checkInContactOwner;
  final String? checkInEarlyCheckInNote;
  final String? checkInLateCheckOutNote;
  final String? checkInLateCheckOutFee;

  final bool? childrenAllowed;
  final int? childrenFreeUnderAge;
  final int? childrenHalfPriceUnderAge;
  final int? childrenMaxChildrenPerRoom;
  final int? childrenMaxChildren;
  final String? childrenCribsNote;
  final bool? childrenPlaygroundAvailable;
  final bool? childrenKidsMenuAvailable;

  final bool? petsAllowed;
  final String? petsReason;
  final double? petsFeeAmount;
  final String? petsMaxWeight;
  final bool? petsRequiresApproval;
  final bool? petsNoFees;
  final bool? petsPetFriendly;
  final bool? petsOutdoorSpace;
  final bool? petsStrict;

  final bool? modificationAllowed;
  final int? modificationFreeModificationHours;
  final String? modificationFeesAfter;
  final bool? modificationFlexible;
  final String? modificationReason;

  const UpdatePolicyEvent({
    required this.policyId,
    required this.type,
    required this.description,
    this.rules,
    this.cancellationWindowDays,
    this.requireFullPaymentBeforeConfirmation,
    this.minimumDepositPercentage,
    this.minHoursBeforeCheckIn,

    this.cancellationFreeCancel,
    this.cancellationFullRefund,
    this.cancellationRefundPercentage,
    this.cancellationDaysBeforeCheckIn,
    this.cancellationHoursBeforeCheckIn,
    this.cancellationNonRefundable,
    this.cancellationPenaltyAfterDeadline,

    this.paymentDepositRequired,
    this.paymentFullPaymentRequired,
    this.paymentDepositPercentage,
    this.paymentAcceptCash,
    this.paymentAcceptCard,
    this.paymentPayAtProperty,
    this.paymentCashPreferred,
    this.paymentAcceptedMethods,

    this.checkInTime,
    this.checkOutTime,
    this.checkInFrom,
    this.checkInUntil,
    this.checkInFlexible,
    this.checkInFlexibleCheckIn,
    this.checkInRequiresCoordination,
    this.checkInContactOwner,
    this.checkInEarlyCheckInNote,
    this.checkInLateCheckOutNote,
    this.checkInLateCheckOutFee,

    this.childrenAllowed,
    this.childrenFreeUnderAge,
    this.childrenHalfPriceUnderAge,
    this.childrenMaxChildrenPerRoom,
    this.childrenMaxChildren,
    this.childrenCribsNote,
    this.childrenPlaygroundAvailable,
    this.childrenKidsMenuAvailable,

    this.petsAllowed,
    this.petsReason,
    this.petsFeeAmount,
    this.petsMaxWeight,
    this.petsRequiresApproval,
    this.petsNoFees,
    this.petsPetFriendly,
    this.petsOutdoorSpace,
    this.petsStrict,

    this.modificationAllowed,
    this.modificationFreeModificationHours,
    this.modificationFeesAfter,
    this.modificationFlexible,
    this.modificationReason,
  });

  @override
  List<Object?> get props => [
        policyId,
        type,
        description,
        rules,
        cancellationWindowDays,
        requireFullPaymentBeforeConfirmation,
        minimumDepositPercentage,
        minHoursBeforeCheckIn,
        cancellationFreeCancel,
        cancellationFullRefund,
        cancellationRefundPercentage,
        cancellationDaysBeforeCheckIn,
        cancellationHoursBeforeCheckIn,
        cancellationNonRefundable,
        cancellationPenaltyAfterDeadline,
        paymentDepositRequired,
        paymentFullPaymentRequired,
        paymentDepositPercentage,
        paymentAcceptCash,
        paymentAcceptCard,
        paymentPayAtProperty,
        paymentCashPreferred,
        paymentAcceptedMethods,
        checkInTime,
        checkOutTime,
        checkInFrom,
        checkInUntil,
        checkInFlexible,
        checkInFlexibleCheckIn,
        checkInRequiresCoordination,
        checkInContactOwner,
        checkInEarlyCheckInNote,
        checkInLateCheckOutNote,
        checkInLateCheckOutFee,
        childrenAllowed,
        childrenFreeUnderAge,
        childrenHalfPriceUnderAge,
        childrenMaxChildrenPerRoom,
        childrenMaxChildren,
        childrenCribsNote,
        childrenPlaygroundAvailable,
        childrenKidsMenuAvailable,
        petsAllowed,
        petsReason,
        petsFeeAmount,
        petsMaxWeight,
        petsRequiresApproval,
        petsNoFees,
        petsPetFriendly,
        petsOutdoorSpace,
        petsStrict,
        modificationAllowed,
        modificationFreeModificationHours,
        modificationFeesAfter,
        modificationFlexible,
        modificationReason,
      ];
}

/// حذف سياسة
class DeletePolicyEvent extends PoliciesEvent {
  final String policyId;

  const DeletePolicyEvent({required this.policyId});

  @override
  List<Object?> get props => [policyId];
}

/// تفعيل/تعطيل سياسة
class TogglePolicyStatusEvent extends PoliciesEvent {
  final String policyId;

  const TogglePolicyStatusEvent({required this.policyId});

  @override
  List<Object?> get props => [policyId];
}

/// تحميل إحصائيات السياسات
class LoadPolicyStatsEvent extends PoliciesEvent {
  const LoadPolicyStatsEvent();
}

/// البحث عن السياسات
class SearchPoliciesEvent extends PoliciesEvent {
  final String searchTerm;
  final PolicyType? type;

  const SearchPoliciesEvent({
    required this.searchTerm,
    this.type,
  });

  @override
  List<Object?> get props => [searchTerm, type];
}

/// اختيار سياسة
class SelectPolicyEvent extends PoliciesEvent {
  final String policyId;

  const SelectPolicyEvent({required this.policyId});

  @override
  List<Object?> get props => [policyId];
}

/// إلغاء اختيار السياسة
class DeselectPolicyEvent extends PoliciesEvent {
  const DeselectPolicyEvent();
}

/// تحديث الصفحة
class RefreshPoliciesEvent extends PoliciesEvent {
  const RefreshPoliciesEvent();
}

/// تغيير الصفحة
class ChangePageEvent extends PoliciesEvent {
  final int pageNumber;

  const ChangePageEvent({required this.pageNumber});

  @override
  List<Object?> get props => [pageNumber];
}

/// تغيير حجم الصفحة
class ChangePageSizeEvent extends PoliciesEvent {
  final int pageSize;

  const ChangePageSizeEvent({required this.pageSize});

  @override
  List<Object?> get props => [pageSize];
}

/// تطبيق الفلاتر
class ApplyFiltersEvent extends PoliciesEvent {
  final String? propertyId;
  final PolicyType? policyType;

  const ApplyFiltersEvent({
    this.propertyId,
    this.policyType,
  });

  @override
  List<Object?> get props => [propertyId, policyType];
}

/// مسح الفلاتر
class ClearFiltersEvent extends PoliciesEvent {
  const ClearFiltersEvent();
}

/// تحميل سياسة بالمعرف
class LoadPolicyByIdEvent extends PoliciesEvent {
  final String policyId;

  const LoadPolicyByIdEvent({required this.policyId});

  @override
  List<Object?> get props => [policyId];
}

/// تحميل سياسات عقار معين
class LoadPoliciesByPropertyEvent extends PoliciesEvent {
  final String propertyId;

  const LoadPoliciesByPropertyEvent({required this.propertyId});

  @override
  List<Object?> get props => [propertyId];
}

/// تحميل سياسات حسب النوع
class LoadPoliciesByTypeEvent extends PoliciesEvent {
  final PolicyType type;
  final int pageNumber;
  final int pageSize;

  const LoadPoliciesByTypeEvent({
    required this.type,
    this.pageNumber = 1,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [type, pageNumber, pageSize];
}
