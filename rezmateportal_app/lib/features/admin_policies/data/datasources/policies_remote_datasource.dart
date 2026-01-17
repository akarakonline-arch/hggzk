import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/policy.dart';
import '../models/policy_model.dart';

abstract class PoliciesRemoteDataSource {
  Future<String> createPolicy({
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

  Future<void> updatePolicy({
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

  Future<void> deletePolicy(String policyId);

  Future<PaginatedResult<PolicyModel>> getAllPolicies({
    int pageNumber = 1,
    int pageSize = 20,
    String? searchTerm,
    String? propertyId,
    PolicyType? policyType,
  });

  Future<PolicyModel> getPolicyById(String policyId);

  Future<List<PolicyModel>> getPoliciesByProperty(String propertyId);

  Future<PaginatedResult<PolicyModel>> getPoliciesByType({
    required PolicyType type,
    int pageNumber = 1,
    int pageSize = 20,
  });

  Future<void> togglePolicyStatus(String policyId);

  Future<PolicyStatsModel> getPolicyStats({String? propertyId});
}

class PoliciesRemoteDataSourceImpl implements PoliciesRemoteDataSource {
  final ApiClient apiClient;

  PoliciesRemoteDataSourceImpl({required this.apiClient});

  String get _baseUrl => '${ApiConstants.adminBaseUrl}/property-policies';

  @override
  Future<String> createPolicy({
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
    try {
      final data = <String, dynamic>{
        'propertyId': propertyId,
        'type': type.apiValue,
        'description': description,
        'cancellationWindowDays': cancellationWindowDays,
        'requireFullPaymentBeforeConfirmation':
            requireFullPaymentBeforeConfirmation,
        'minimumDepositPercentage': minimumDepositPercentage,
        'minHoursBeforeCheckIn': minHoursBeforeCheckIn,
      };

      if (rules != null && rules.isNotEmpty) data['rules'] = rules;

      if (cancellationFreeCancel != null) data['cancellationFreeCancel'] = cancellationFreeCancel;
      if (cancellationFullRefund != null) data['cancellationFullRefund'] = cancellationFullRefund;
      if (cancellationRefundPercentage != null) data['cancellationRefundPercentage'] = cancellationRefundPercentage;
      if (cancellationDaysBeforeCheckIn != null) data['cancellationDaysBeforeCheckIn'] = cancellationDaysBeforeCheckIn;
      if (cancellationHoursBeforeCheckIn != null) data['cancellationHoursBeforeCheckIn'] = cancellationHoursBeforeCheckIn;
      if (cancellationNonRefundable != null) data['cancellationNonRefundable'] = cancellationNonRefundable;
      if (cancellationPenaltyAfterDeadline != null) data['cancellationPenaltyAfterDeadline'] = cancellationPenaltyAfterDeadline;

      if (paymentDepositRequired != null) data['paymentDepositRequired'] = paymentDepositRequired;
      if (paymentFullPaymentRequired != null) data['paymentFullPaymentRequired'] = paymentFullPaymentRequired;
      if (paymentDepositPercentage != null) data['paymentDepositPercentage'] = paymentDepositPercentage;
      if (paymentAcceptCash != null) data['paymentAcceptCash'] = paymentAcceptCash;
      if (paymentAcceptCard != null) data['paymentAcceptCard'] = paymentAcceptCard;
      if (paymentPayAtProperty != null) data['paymentPayAtProperty'] = paymentPayAtProperty;
      if (paymentCashPreferred != null) data['paymentCashPreferred'] = paymentCashPreferred;
      if (paymentAcceptedMethods != null) data['paymentAcceptedMethods'] = paymentAcceptedMethods;

      if (checkInTime != null) data['checkInTime'] = checkInTime;
      if (checkOutTime != null) data['checkOutTime'] = checkOutTime;
      if (checkInFrom != null) data['checkInFrom'] = checkInFrom;
      if (checkInUntil != null) data['checkInUntil'] = checkInUntil;
      if (checkInFlexible != null) data['checkInFlexible'] = checkInFlexible;
      if (checkInFlexibleCheckIn != null) data['checkInFlexibleCheckIn'] = checkInFlexibleCheckIn;
      if (checkInRequiresCoordination != null) data['checkInRequiresCoordination'] = checkInRequiresCoordination;
      if (checkInContactOwner != null) data['checkInContactOwner'] = checkInContactOwner;
      if (checkInEarlyCheckInNote != null) data['checkInEarlyCheckInNote'] = checkInEarlyCheckInNote;
      if (checkInLateCheckOutNote != null) data['checkInLateCheckOutNote'] = checkInLateCheckOutNote;
      if (checkInLateCheckOutFee != null) data['checkInLateCheckOutFee'] = checkInLateCheckOutFee;

      if (childrenAllowed != null) data['childrenAllowed'] = childrenAllowed;
      if (childrenFreeUnderAge != null) data['childrenFreeUnderAge'] = childrenFreeUnderAge;
      if (childrenHalfPriceUnderAge != null) data['childrenHalfPriceUnderAge'] = childrenHalfPriceUnderAge;
      if (childrenMaxChildrenPerRoom != null) data['childrenMaxChildrenPerRoom'] = childrenMaxChildrenPerRoom;
      if (childrenMaxChildren != null) data['childrenMaxChildren'] = childrenMaxChildren;
      if (childrenCribsNote != null) data['childrenCribsNote'] = childrenCribsNote;
      if (childrenPlaygroundAvailable != null) data['childrenPlaygroundAvailable'] = childrenPlaygroundAvailable;
      if (childrenKidsMenuAvailable != null) data['childrenKidsMenuAvailable'] = childrenKidsMenuAvailable;

      if (petsAllowed != null) data['petsAllowed'] = petsAllowed;
      if (petsReason != null) data['petsReason'] = petsReason;
      if (petsFeeAmount != null) data['petsFeeAmount'] = petsFeeAmount;
      if (petsMaxWeight != null) data['petsMaxWeight'] = petsMaxWeight;
      if (petsRequiresApproval != null) data['petsRequiresApproval'] = petsRequiresApproval;
      if (petsNoFees != null) data['petsNoFees'] = petsNoFees;
      if (petsPetFriendly != null) data['petsPetFriendly'] = petsPetFriendly;
      if (petsOutdoorSpace != null) data['petsOutdoorSpace'] = petsOutdoorSpace;
      if (petsStrict != null) data['petsStrict'] = petsStrict;

      if (modificationAllowed != null) data['modificationAllowed'] = modificationAllowed;
      if (modificationFreeModificationHours != null) data['modificationFreeModificationHours'] = modificationFreeModificationHours;
      if (modificationFeesAfter != null) data['modificationFeesAfter'] = modificationFeesAfter;
      if (modificationFlexible != null) data['modificationFlexible'] = modificationFlexible;
      if (modificationReason != null) data['modificationReason'] = modificationReason;

      final response = await apiClient.post(
        _baseUrl,
        data: data,
      );

      if (response.data['isSuccess'] == true) {
        return (response.data['data'] ?? response.data['result'] ?? '').toString();
      }
      throw Exception(response.data['message'] ?? 'فشل إنشاء السياسة');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updatePolicy({
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
    try {
      final data = <String, dynamic>{
        'policyId': policyId,
        'type': type.apiValue,
        'description': description,
      };

      if (rules != null && rules.isNotEmpty) data['rules'] = rules;

      if (cancellationWindowDays != null) data['cancellationWindowDays'] = cancellationWindowDays;
      if (requireFullPaymentBeforeConfirmation != null) data['requireFullPaymentBeforeConfirmation'] = requireFullPaymentBeforeConfirmation;
      if (minimumDepositPercentage != null) data['minimumDepositPercentage'] = minimumDepositPercentage;
      if (minHoursBeforeCheckIn != null) data['minHoursBeforeCheckIn'] = minHoursBeforeCheckIn;

      if (cancellationFreeCancel != null) data['cancellationFreeCancel'] = cancellationFreeCancel;
      if (cancellationFullRefund != null) data['cancellationFullRefund'] = cancellationFullRefund;
      if (cancellationRefundPercentage != null) data['cancellationRefundPercentage'] = cancellationRefundPercentage;
      if (cancellationDaysBeforeCheckIn != null) data['cancellationDaysBeforeCheckIn'] = cancellationDaysBeforeCheckIn;
      if (cancellationHoursBeforeCheckIn != null) data['cancellationHoursBeforeCheckIn'] = cancellationHoursBeforeCheckIn;
      if (cancellationNonRefundable != null) data['cancellationNonRefundable'] = cancellationNonRefundable;
      if (cancellationPenaltyAfterDeadline != null) data['cancellationPenaltyAfterDeadline'] = cancellationPenaltyAfterDeadline;

      if (paymentDepositRequired != null) data['paymentDepositRequired'] = paymentDepositRequired;
      if (paymentFullPaymentRequired != null) data['paymentFullPaymentRequired'] = paymentFullPaymentRequired;
      if (paymentDepositPercentage != null) data['paymentDepositPercentage'] = paymentDepositPercentage;
      if (paymentAcceptCash != null) data['paymentAcceptCash'] = paymentAcceptCash;
      if (paymentAcceptCard != null) data['paymentAcceptCard'] = paymentAcceptCard;
      if (paymentPayAtProperty != null) data['paymentPayAtProperty'] = paymentPayAtProperty;
      if (paymentCashPreferred != null) data['paymentCashPreferred'] = paymentCashPreferred;
      if (paymentAcceptedMethods != null) data['paymentAcceptedMethods'] = paymentAcceptedMethods;

      if (checkInTime != null) data['checkInTime'] = checkInTime;
      if (checkOutTime != null) data['checkOutTime'] = checkOutTime;
      if (checkInFrom != null) data['checkInFrom'] = checkInFrom;
      if (checkInUntil != null) data['checkInUntil'] = checkInUntil;
      if (checkInFlexible != null) data['checkInFlexible'] = checkInFlexible;
      if (checkInFlexibleCheckIn != null) data['checkInFlexibleCheckIn'] = checkInFlexibleCheckIn;
      if (checkInRequiresCoordination != null) data['checkInRequiresCoordination'] = checkInRequiresCoordination;
      if (checkInContactOwner != null) data['checkInContactOwner'] = checkInContactOwner;
      if (checkInEarlyCheckInNote != null) data['checkInEarlyCheckInNote'] = checkInEarlyCheckInNote;
      if (checkInLateCheckOutNote != null) data['checkInLateCheckOutNote'] = checkInLateCheckOutNote;
      if (checkInLateCheckOutFee != null) data['checkInLateCheckOutFee'] = checkInLateCheckOutFee;

      if (childrenAllowed != null) data['childrenAllowed'] = childrenAllowed;
      if (childrenFreeUnderAge != null) data['childrenFreeUnderAge'] = childrenFreeUnderAge;
      if (childrenHalfPriceUnderAge != null) data['childrenHalfPriceUnderAge'] = childrenHalfPriceUnderAge;
      if (childrenMaxChildrenPerRoom != null) data['childrenMaxChildrenPerRoom'] = childrenMaxChildrenPerRoom;
      if (childrenMaxChildren != null) data['childrenMaxChildren'] = childrenMaxChildren;
      if (childrenCribsNote != null) data['childrenCribsNote'] = childrenCribsNote;
      if (childrenPlaygroundAvailable != null) data['childrenPlaygroundAvailable'] = childrenPlaygroundAvailable;
      if (childrenKidsMenuAvailable != null) data['childrenKidsMenuAvailable'] = childrenKidsMenuAvailable;

      if (petsAllowed != null) data['petsAllowed'] = petsAllowed;
      if (petsReason != null) data['petsReason'] = petsReason;
      if (petsFeeAmount != null) data['petsFeeAmount'] = petsFeeAmount;
      if (petsMaxWeight != null) data['petsMaxWeight'] = petsMaxWeight;
      if (petsRequiresApproval != null) data['petsRequiresApproval'] = petsRequiresApproval;
      if (petsNoFees != null) data['petsNoFees'] = petsNoFees;
      if (petsPetFriendly != null) data['petsPetFriendly'] = petsPetFriendly;
      if (petsOutdoorSpace != null) data['petsOutdoorSpace'] = petsOutdoorSpace;
      if (petsStrict != null) data['petsStrict'] = petsStrict;

      if (modificationAllowed != null) data['modificationAllowed'] = modificationAllowed;
      if (modificationFreeModificationHours != null) data['modificationFreeModificationHours'] = modificationFreeModificationHours;
      if (modificationFeesAfter != null) data['modificationFeesAfter'] = modificationFeesAfter;
      if (modificationFlexible != null) data['modificationFlexible'] = modificationFlexible;
      if (modificationReason != null) data['modificationReason'] = modificationReason;

      final response = await apiClient.put(
        '$_baseUrl/$policyId',
        data: data,
      );

      if (response.data['isSuccess'] != true) {
        throw Exception(response.data['message'] ?? 'فشل تحديث السياسة');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deletePolicy(String policyId) async {
    try {
      final response = await apiClient.delete('$_baseUrl/$policyId');

      final data = response.data;
      final bool isSuccess = data is Map<String, dynamic>
          ? (data['isSuccess'] == true || data['success'] == true)
          : false;

      if (!isSuccess) {
        if (data is Map<String, dynamic>) {
          final message = data['message'] ?? 'فشل حذف السياسة';
          final code = data['errorCode']?.toString() ?? data['code']?.toString();
          final showAsDialog = data['showAsDialog'] == true;

          throw ServerException(
            message.toString(),
            code: code,
            showAsDialog: showAsDialog,
          );
        }

        throw const ServerException('فشل حذف السياسة');
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? 'فشل حذف السياسة';
        final code = data['errorCode']?.toString() ?? data['code']?.toString();
        final showAsDialog = data['showAsDialog'] == true;

        throw ServerException(
          message.toString(),
          code: code,
          showAsDialog: showAsDialog,
        );
      }

      throw const ServerException('فشل حذف السياسة');
    }
  }

  @override
  Future<PaginatedResult<PolicyModel>> getAllPolicies({
    int pageNumber = 1,
    int pageSize = 20,
    String? searchTerm,
    String? propertyId,
    PolicyType? policyType,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      };

      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParameters['searchTerm'] = searchTerm;
      }
      if (propertyId != null && propertyId.isNotEmpty) {
        queryParameters['propertyId'] = propertyId;
      }
      if (policyType != null) {
        queryParameters['policyType'] = policyType.apiValue;
      }

      final response = await apiClient.get(
        '$_baseUrl/all',
        queryParameters: queryParameters,
      );

      // التعامل مع Response مباشر (بدون wrapper)
      final data = response.data;
      
      if (data == null) {
        return PaginatedResult(
          items: [],
          pageNumber: pageNumber,
          pageSize: pageSize,
          totalCount: 0,
        );
      }
      
      // التعامل مع PaginatedResult مباشر من الباك إند
      if (data is Map<String, dynamic>) {
        // Check if it has 'isSuccess' wrapper (ResultDto)
        if (data.containsKey('isSuccess')) {
          if (data['isSuccess'] == true) {
            final innerData = data['data'] ?? data['result'];
            if (innerData is Map<String, dynamic> && innerData.containsKey('items')) {
              final items = (innerData['items'] as List?)
                  ?.map((item) => PolicyModel.fromJson(item))
                  .toList() ?? [];
              
              return PaginatedResult(
                items: items,
                pageNumber: innerData['pageNumber'] ?? pageNumber,
                pageSize: innerData['pageSize'] ?? pageSize,
                totalCount: innerData['totalCount'] ?? items.length,
              );
            }
          }
        }
        // Direct PaginatedResult (no wrapper)
        else if (data.containsKey('items')) {
          final itemsList = data['items'] as List?;
          
          final items = itemsList
              ?.map((item) {
                try {
                  return PolicyModel.fromJson(item);
                } catch (e) {
                  print('❌ Failed to parse item: $e');
                  return null;
                }
              })
              .where((item) => item != null)
              .cast<PolicyModel>()
              .toList() ?? [];
          
          return PaginatedResult(
            items: items,
            pageNumber: data['pageNumber'] ?? pageNumber,
            pageSize: data['pageSize'] ?? pageSize,
            totalCount: data['totalCount'] ?? items.length,
          );
        }
      }
      
      return PaginatedResult(
        items: [],
        pageNumber: pageNumber,
        pageSize: pageSize,
        totalCount: 0,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PolicyModel> getPolicyById(String policyId) async {
    try {
      final response = await apiClient.get('$_baseUrl/$policyId');

      if (response.data['isSuccess'] == true) {
        final data = response.data['data'] ?? response.data['result'];
        return PolicyModel.fromJson(data);
      }
      throw Exception(response.data['message'] ?? 'فشل جلب بيانات السياسة');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<PolicyModel>> getPoliciesByProperty(String propertyId) async {
    try {
      final response = await apiClient.get(
        _baseUrl,
        queryParameters: {'propertyId': propertyId},
      );

      if (response.data['isSuccess'] == true) {
        final data = response.data['data'] ?? response.data['result'];
        
        if (data is Map<String, dynamic> && data.containsKey('items')) {
          return (data['items'] as List)
              .map((item) => PolicyModel.fromJson(item))
              .toList();
        } else if (data is List) {
          return data.map((item) => PolicyModel.fromJson(item)).toList();
        }
      }
      
      return [];
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PaginatedResult<PolicyModel>> getPoliciesByType({
    required PolicyType type,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await apiClient.get(
        '$_baseUrl/by-type',
        queryParameters: {
          'type': type.apiValue,
          'pageNumber': pageNumber,
          'pageSize': pageSize,
        },
      );

      if (response.data['isSuccess'] == true) {
        final data = response.data['data'] ?? response.data['result'];
        
        if (data is Map<String, dynamic>) {
          final items = (data['items'] as List?)
              ?.map((item) => PolicyModel.fromJson(item))
              .toList() ?? [];
          
          return PaginatedResult(
            items: items,
            pageNumber: data['pageNumber'] ?? pageNumber,
            pageSize: data['pageSize'] ?? pageSize,
            totalCount: data['totalCount'] ?? items.length,
          );
        }
      }
      
      return PaginatedResult(
        items: [],
        pageNumber: pageNumber,
        pageSize: pageSize,
        totalCount: 0,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> togglePolicyStatus(String policyId) async {
    try {
      final response = await apiClient.patch('$_baseUrl/$policyId/toggle-status');

      if (response.data['isSuccess'] != true) {
        throw Exception(response.data['message'] ?? 'فشل تغيير حالة السياسة');
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<PolicyStatsModel> getPolicyStats({String? propertyId}) async {
    try {
      final response = await apiClient.get(
        '$_baseUrl/stats',
        queryParameters: propertyId != null && propertyId.isNotEmpty
            ? {'propertyId': propertyId}
            : null,
      );

      if (response.data['isSuccess'] == true) {
        final data = response.data['data'] ?? response.data['result'];
        return PolicyStatsModel.fromJson(data);
      }
      
      return PolicyStatsModel(
        totalPolicies: 0,
        activePolicies: 0,
        policiesByType: 0,
        policyTypeDistribution: {},
        averageCancellationWindow: 0,
      );
    } catch (e) {
      return PolicyStatsModel(
        totalPolicies: 0,
        activePolicies: 0,
        policiesByType: 0,
        policyTypeDistribution: {},
        averageCancellationWindow: 0,
      );
    }
  }
}
