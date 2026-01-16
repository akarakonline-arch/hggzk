import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../entities/policy.dart';

abstract class PoliciesRepository {
  /// إنشاء سياسة جديدة
  Future<Either<Failure, String>> createPolicy({
    required String propertyId,
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
  });

  /// تحديث سياسة موجودة
  Future<Either<Failure, void>> updatePolicy({
    required String policyId,
    required PolicyType type,
    required String description,
    String? rules,
    int? cancellationWindowDays,
    bool? requireFullPaymentBeforeConfirmation,
    double? minimumDepositPercentage,
    int? minHoursBeforeCheckIn,

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
  });

  /// حذف سياسة
  Future<Either<Failure, void>> deletePolicy(String policyId);

  /// الحصول على جميع السياسات مع الصفحات
  Future<Either<Failure, PaginatedResult<Policy>>> getAllPolicies({
    int pageNumber = 1,
    int pageSize = 20,
    String? searchTerm,
    String? propertyId,
    PolicyType? policyType,
  });

  /// الحصول على سياسة بالمعرف
  Future<Either<Failure, Policy>> getPolicyById(String policyId);

  /// الحصول على سياسات عقار معين
  Future<Either<Failure, List<Policy>>> getPoliciesByProperty(String propertyId);

  /// الحصول على سياسات حسب النوع
  Future<Either<Failure, PaginatedResult<Policy>>> getPoliciesByType({
    required PolicyType type,
    int pageNumber = 1,
    int pageSize = 20,
  });

  /// تفعيل/تعطيل سياسة
  Future<Either<Failure, void>> togglePolicyStatus(String policyId);

  /// الحصول على إحصائيات السياسات
  Future<Either<Failure, PolicyStats>> getPolicyStats({String? propertyId});

  /// البحث عن السياسات
  Future<Either<Failure, PaginatedResult<Policy>>> searchPolicies({
    required String searchTerm,
    int pageNumber = 1,
    int pageSize = 20,
    PolicyType? type,
  });
}
