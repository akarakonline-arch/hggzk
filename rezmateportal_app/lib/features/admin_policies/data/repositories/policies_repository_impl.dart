import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/policy.dart';
import '../../domain/repositories/policies_repository.dart';
import '../datasources/policies_local_datasource.dart';
import '../datasources/policies_remote_datasource.dart';
import '../models/policy_model.dart';

class PoliciesRepositoryImpl implements PoliciesRepository {
  final PoliciesRemoteDataSource remoteDataSource;
  final PoliciesLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  PoliciesRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
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
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final policyId = await remoteDataSource.createPolicy(
          propertyId: propertyId,
          type: type,
          description: description,
          rules: rules,
          cancellationWindowDays: cancellationWindowDays,
          requireFullPaymentBeforeConfirmation:
              requireFullPaymentBeforeConfirmation,
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
        );
        return Right(policyId);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('حدث خطأ غير متوقع: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
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
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updatePolicy(
          policyId: policyId,
          type: type,
          description: description,
          rules: rules,
          cancellationWindowDays: cancellationWindowDays,
          requireFullPaymentBeforeConfirmation:
              requireFullPaymentBeforeConfirmation,
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
        );
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('حدث خطأ غير متوقع: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePolicy(String policyId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.deletePolicy(policyId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure.meta(
          message: e.message,
          code: e.code,
          showAsDialog: e.showAsDialog,
        ));
      } catch (e) {
        return Left(ServerFailure('حدث خطأ غير متوقع: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<Policy>>> getAllPolicies({
    int pageNumber = 1,
    int pageSize = 20,
    String? searchTerm,
    String? propertyId,
    PolicyType? policyType,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getAllPolicies(
          pageNumber: pageNumber,
          pageSize: pageSize,
          searchTerm: searchTerm,
          propertyId: propertyId,
          policyType: policyType,
        );

        if (pageNumber == 1) {
          await localDataSource.cachePolicies(result.items);
        }

        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('حدث خطأ غير متوقع: ${e.toString()}'));
      }
    } else {
      try {
        final cachedPolicies = await localDataSource.getCachedPolicies();
        return Right(
          PaginatedResult(
            items: cachedPolicies,
            pageNumber: pageNumber,
            pageSize: pageSize,
            totalCount: cachedPolicies.length,
          ),
        );
      } catch (e) {
        return const Left(CacheFailure('فشل في تحميل البيانات المحفوظة'));
      }
    }
  }

  @override
  Future<Either<Failure, Policy>> getPolicyById(String policyId) async {
    if (await networkInfo.isConnected) {
      try {
        final policy = await remoteDataSource.getPolicyById(policyId);
        await localDataSource.cachePolicy(policy);
        return Right(policy);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('حدث خطأ غير متوقع: ${e.toString()}'));
      }
    } else {
      try {
        final cachedPolicy = await localDataSource.getCachedPolicy(policyId);
        if (cachedPolicy != null) {
          return Right(cachedPolicy);
        }
        return const Left(CacheFailure('لا توجد بيانات محفوظة'));
      } catch (e) {
        return const Left(CacheFailure('فشل في تحميل البيانات المحفوظة'));
      }
    }
  }

  @override
  Future<Either<Failure, List<Policy>>> getPoliciesByProperty(
      String propertyId) async {
    if (await networkInfo.isConnected) {
      try {
        final policies =
            await remoteDataSource.getPoliciesByProperty(propertyId);
        return Right(policies);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('حدث خطأ غير متوقع: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<Policy>>> getPoliciesByType({
    required PolicyType type,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.getPoliciesByType(
          type: type,
          pageNumber: pageNumber,
          pageSize: pageSize,
        );
        return Right(result);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('حدث خطأ غير متوقع: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, void>> togglePolicyStatus(String policyId) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.togglePolicyStatus(policyId);
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('حدث خطأ غير متوقع: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, PolicyStats>> getPolicyStats(
      {String? propertyId}) async {
    if (await networkInfo.isConnected) {
      try {
        final stats =
            await remoteDataSource.getPolicyStats(propertyId: propertyId);
        return Right(stats.toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } catch (e) {
        return Left(ServerFailure('حدث خطأ غير متوقع: ${e.toString()}'));
      }
    } else {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<Policy>>> searchPolicies({
    required String searchTerm,
    int pageNumber = 1,
    int pageSize = 20,
    PolicyType? type,
  }) async {
    return await getAllPolicies(
      pageNumber: pageNumber,
      pageSize: pageSize,
      searchTerm: searchTerm,
      policyType: type,
    );
  }
}
