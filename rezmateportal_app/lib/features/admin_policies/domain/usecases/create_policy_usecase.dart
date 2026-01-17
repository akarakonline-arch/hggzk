import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/policy.dart';
import '../repositories/policies_repository.dart';

class CreatePolicyUseCase implements UseCase<String, CreatePolicyParams> {
  final PoliciesRepository repository;

  CreatePolicyUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(CreatePolicyParams params) async {
    return await repository.createPolicy(
      propertyId: params.propertyId,
      type: params.type,
      description: params.description,
      rules: params.rules,
      cancellationWindowDays: params.cancellationWindowDays,
      requireFullPaymentBeforeConfirmation: params.requireFullPaymentBeforeConfirmation,
      minimumDepositPercentage: params.minimumDepositPercentage,
      minHoursBeforeCheckIn: params.minHoursBeforeCheckIn,
      cancellationFreeCancel: params.cancellationFreeCancel,
      cancellationFullRefund: params.cancellationFullRefund,
      cancellationRefundPercentage: params.cancellationRefundPercentage,
      cancellationDaysBeforeCheckIn: params.cancellationDaysBeforeCheckIn,
      cancellationHoursBeforeCheckIn: params.cancellationHoursBeforeCheckIn,
      cancellationNonRefundable: params.cancellationNonRefundable,
      cancellationPenaltyAfterDeadline: params.cancellationPenaltyAfterDeadline,
      paymentDepositRequired: params.paymentDepositRequired,
      paymentFullPaymentRequired: params.paymentFullPaymentRequired,
      paymentDepositPercentage: params.paymentDepositPercentage,
      paymentAcceptCash: params.paymentAcceptCash,
      paymentAcceptCard: params.paymentAcceptCard,
      paymentPayAtProperty: params.paymentPayAtProperty,
      paymentCashPreferred: params.paymentCashPreferred,
      paymentAcceptedMethods: params.paymentAcceptedMethods,
      checkInTime: params.checkInTime,
      checkOutTime: params.checkOutTime,
      checkInFrom: params.checkInFrom,
      checkInUntil: params.checkInUntil,
      checkInFlexible: params.checkInFlexible,
      checkInFlexibleCheckIn: params.checkInFlexibleCheckIn,
      checkInRequiresCoordination: params.checkInRequiresCoordination,
      checkInContactOwner: params.checkInContactOwner,
      checkInEarlyCheckInNote: params.checkInEarlyCheckInNote,
      checkInLateCheckOutNote: params.checkInLateCheckOutNote,
      checkInLateCheckOutFee: params.checkInLateCheckOutFee,
      childrenAllowed: params.childrenAllowed,
      childrenFreeUnderAge: params.childrenFreeUnderAge,
      childrenHalfPriceUnderAge: params.childrenHalfPriceUnderAge,
      childrenMaxChildrenPerRoom: params.childrenMaxChildrenPerRoom,
      childrenMaxChildren: params.childrenMaxChildren,
      childrenCribsNote: params.childrenCribsNote,
      childrenPlaygroundAvailable: params.childrenPlaygroundAvailable,
      childrenKidsMenuAvailable: params.childrenKidsMenuAvailable,
      petsAllowed: params.petsAllowed,
      petsReason: params.petsReason,
      petsFeeAmount: params.petsFeeAmount,
      petsMaxWeight: params.petsMaxWeight,
      petsRequiresApproval: params.petsRequiresApproval,
      petsNoFees: params.petsNoFees,
      petsPetFriendly: params.petsPetFriendly,
      petsOutdoorSpace: params.petsOutdoorSpace,
      petsStrict: params.petsStrict,
      modificationAllowed: params.modificationAllowed,
      modificationFreeModificationHours: params.modificationFreeModificationHours,
      modificationFeesAfter: params.modificationFeesAfter,
      modificationFlexible: params.modificationFlexible,
      modificationReason: params.modificationReason,
    );
  }
}

class CreatePolicyParams extends Equatable {
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

  const CreatePolicyParams({
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
