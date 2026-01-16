import 'package:dio/dio.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/request_logger.dart';
import '../models/property_detail_model.dart';
import '../models/unit_model.dart';
import '../models/review_model.dart';
import '../models/property_availability_model.dart';

abstract class PropertyRemoteDataSource {
  Future<PropertyDetailModel> getPropertyDetails({
    required String propertyId,
    String? userId,
    String? userRole,
  });

  Future<List<UnitModel>> getPropertyUnits({
    required String propertyId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    required int guestsCount,
  });

  Future<List<ReviewModel>> getPropertyReviews({
    required String propertyId,
    int pageNumber = 1,
    int pageSize = 20,
    String? sortBy,
    String? sortDirection,
    bool withImagesOnly = false,
    String? userId,
  });

  Future<bool> addToFavorites({
    required String propertyId,
    required String userId,
    String? notes,
    DateTime? desiredVisitDate,
    double? expectedBudget,
    String currency = 'YER',
  });

  Future<bool> removeFromFavorites({
    required String propertyId,
    required String userId,
  });

  Future<bool> updateViewCount({
    required String propertyId,
  });

  Future<PropertyAvailabilityModel> checkAvailability({
    required String propertyId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int guestsCount,
  });
}

class PropertyRemoteDataSourceImpl implements PropertyRemoteDataSource {
  final ApiClient apiClient;

  PropertyRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<PropertyAvailabilityModel> checkAvailability({
    required String propertyId,
    required DateTime checkInDate,
    required DateTime checkOutDate,
    required int guestsCount,
  }) async {
    const requestName = 'checkAvailability';
    logRequestStart(requestName, details: {
      'propertyId': propertyId,
      'checkInDate': checkInDate.toIso8601String(),
      'checkOutDate': checkOutDate.toIso8601String(),
      'guestsCount': guestsCount,
    });
    try {
      final response = await apiClient.get(
        '/api/client/properties/availability',
        queryParameters: <String, dynamic>{
          'propertyId': propertyId,
          // ✅ يجب أن تتطابق أسماء البارامترات مع خصائص CheckPropertyAvailabilityQuery في الباك اند
          // PropertyId, CheckInDate, CheckOutDate, GuestsCount
          'checkInDate': checkInDate.toIso8601String(),
          'checkOutDate': checkOutDate.toIso8601String(),
          'guestsCount': guestsCount,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final body = response.data;

        // ✅ دعم أكثر من شكل للاستجابة + التعامل مع حالة success=false أو data=null
        if (body is Map<String, dynamic>) {
          final success = body['success'];
          final message = body['message']?.toString();
          final errorCode = body['errorCode']?.toString() ?? body['code']?.toString();
          final showAsDialog = body['showAsDialog'] == true;

          // إذا الـ backend أعاد success=false (مثل: "تاريخ الوصول يجب أن يكون قبل تاريخ المغادرة")
          if (success is bool && !success) {
            throw ServerException(
              message ?? 'Failed to check availability',
              code: errorCode,
              showAsDialog: showAsDialog,
            );
          }

          final rootData = body['data'];

          if (rootData is Map<String, dynamic>) {
            return PropertyAvailabilityModel.fromJson(rootData);
          }

          // بعض الـ APIs قد ترسل البيانات مباشرة بدون حقل data
          if (rootData == null && body.isNotEmpty) {
            // جرّب استخدام الجذر نفسه كبيانات توفّر إذا كان Map
            return PropertyAvailabilityModel.fromJson(body);
          }

          // إذا لم نجد بيانات صالحة، اعتبرها خطأ منطقي واضح بدلاً من كراش
          throw ServerException(
            message ?? 'لا توجد بيانات توفّر متاحة لهذا العقار.',
            code: errorCode,
            showAsDialog: showAsDialog,
          );
        }

        // إذا لم تكن الاستجابة Map، فهذا شكل غير متوقع
        throw const ServerException('Invalid availability response format');
      } else {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          throw ServerException(
            data['message']?.toString() ?? 'Failed to check availability',
            code: data['errorCode']?.toString() ?? data['code']?.toString(),
            showAsDialog: data['showAsDialog'] == true,
          );
        }
        throw const ServerException('Failed to check availability');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        throw ServerException(
          data['message']?.toString() ?? e.message ?? 'Network error occurred',
          code: data['errorCode']?.toString() ?? data['code']?.toString(),
          showAsDialog: data['showAsDialog'] == true,
        );
      }
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<PropertyDetailModel> getPropertyDetails({
    required String propertyId,
    String? userId,
    String? userRole,
  }) async {
    const requestName = 'getPropertyDetails';
    logRequestStart(requestName, details: {
      'propertyId': propertyId,
      if (userId != null) 'userId': userId,
      if (userRole != null) 'userRole': userRole,
    });
    try {
      final queryParams = <String, dynamic>{};
      if (userId != null) {
        queryParams['userId'] = userId;
      }
      if (userRole != null) {
        queryParams['userRole'] = userRole;
      }

      final response = await apiClient.get(
        '/api/client/properties/$propertyId',
        queryParameters: queryParams,
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final data = response.data['data'];
        return PropertyDetailModel.fromJson(data);
      } else {
        throw ServerException(
            response.data['message'] ?? 'Failed to load property details');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<List<UnitModel>> getPropertyUnits({
    required String propertyId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    required int guestsCount,
  }) async {
    const requestName = 'getPropertyUnits';
    logRequestStart(requestName, details: {
      'propertyId': propertyId,
      if (checkInDate != null) 'checkInDate': checkInDate.toIso8601String(),
      if (checkOutDate != null) 'checkOutDate': checkOutDate.toIso8601String(),
      'guestsCount': guestsCount,
    });
    try {
      final response = await apiClient.get(
        '/api/client/units/available',
        queryParameters: <String, dynamic>{
          'propertyId': propertyId,
          if (checkInDate != null) 'checkIn': checkInDate.toIso8601String(),
          if (checkOutDate != null) 'checkOut': checkOutDate.toIso8601String(),
          'guestsCount': guestsCount,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final body = response.data;
        List<dynamic>? unitsJson;
        if (body is Map<String, dynamic>) {
          final rootData = body['data'];
          if (rootData is Map<String, dynamic> && rootData['units'] is List) {
            unitsJson = rootData['units'] as List<dynamic>;
          } else if (rootData is List) {
            unitsJson = rootData;
          } else if (body['units'] is List) {
            unitsJson = body['units'] as List<dynamic>;
          } else if (body['items'] is List) {
            unitsJson = body['items'] as List<dynamic>;
          }
        } else if (body is List) {
          unitsJson = body;
        }
        if (unitsJson == null) {
          // Graceful fallback: empty list when response has no units array
          return <UnitModel>[];
        }
        return unitsJson.map((json) => UnitModel.fromJson(json)).toList();
      } else {
        throw ServerException(
            response.data['message'] ?? 'Failed to load units');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<List<ReviewModel>> getPropertyReviews({
    required String propertyId,
    int pageNumber = 1,
    int pageSize = 20,
    String? sortBy,
    String? sortDirection,
    bool withImagesOnly = false,
    String? userId,
  }) async {
    const requestName = 'getPropertyReviews';
    logRequestStart(requestName, details: {
      'propertyId': propertyId,
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortDirection != null) 'sortDirection': sortDirection,
      'withImagesOnly': withImagesOnly,
      if (userId != null) 'userId': userId,
    });
    try {
      final response = await apiClient.get(
        '/api/client/reviews/property',
        queryParameters: <String, dynamic>{
          'propertyId': propertyId,
          'pageNumber': pageNumber,
          'pageSize': pageSize,
          if (sortBy != null) 'sortBy': sortBy,
          if (sortDirection != null) 'sortDirection': sortDirection,
          'withImagesOnly': withImagesOnly,
          if (userId != null) 'userId': userId,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final data = response.data['data']['items'] as List;
        return data.map((json) => ReviewModel.fromJson(json)).toList();
      } else {
        throw ServerException(
            response.data['message'] ?? 'Failed to load reviews');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<bool> addToFavorites({
    required String propertyId,
    required String userId,
    String? notes,
    DateTime? desiredVisitDate,
    double? expectedBudget,
    String currency = 'YER',
  }) async {
    const requestName = 'addToFavorites';
    logRequestStart(requestName, details: {
      'propertyId': propertyId,
      'userId': userId,
      if (notes != null) 'notes': notes,
      if (desiredVisitDate != null)
        'desiredVisitDate': desiredVisitDate.toIso8601String(),
      if (expectedBudget != null) 'expectedBudget': expectedBudget,
      'currency': currency,
    });
    try {
      final response = await apiClient.post(
        '/api/client/favorites',
        data: <String, dynamic>{
          'userId': userId,
          'propertyId': propertyId,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.data;
        bool success = false;
        if (body is Map<String, dynamic>) {
          if (body['success'] is bool) success = body['success'] as bool;
          final data = body['data'];
          if (data is bool) {
            success = data;
          } else if (data is Map) {
            final map = Map<String, dynamic>.from(data as Map);
            if (map['success'] is bool) success = map['success'] as bool;
            if (map['Success'] is bool) success = map['Success'] as bool;
          }
        }
        return success;
      } else {
        throw ServerException(
            response.data['message'] ?? 'Failed to add to favorites');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<bool> removeFromFavorites({
    required String propertyId,
    required String userId,
  }) async {
    const requestName = 'removeFromFavorites';
    logRequestStart(requestName, details: {
      'propertyId': propertyId,
      'userId': userId,
    });
    try {
      final response = await apiClient.delete(
        '/api/client/favorites',
        data: {
          'propertyId': propertyId,
          'userId': userId,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        final body = response.data;
        bool success = false;
        if (body is Map<String, dynamic>) {
          if (body['success'] is bool) success = body['success'] as bool;
          final data = body['data'];
          if (data is bool) {
            success = data;
          } else if (data is Map) {
            final map = Map<String, dynamic>.from(data as Map);
            if (map['success'] is bool) success = map['success'] as bool;
            if (map['Success'] is bool) success = map['Success'] as bool;
          }
        }
        return success;
      } else {
        throw ServerException(
            response.data['message'] ?? 'Failed to remove from favorites');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException('Unexpected error: $e');
    }
  }

  @override
  Future<bool> updateViewCount({
    required String propertyId,
  }) async {
    const requestName = 'updateViewCount';
    logRequestStart(requestName, details: {
      'propertyId': propertyId,
    });
    try {
      final response = await apiClient.post(
        '/api/client/properties/view-count',
        data: {
          'propertyId': propertyId,
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      if (response.statusCode == 200) {
        return response.data['data'] ?? false;
      } else {
        throw ServerException(
            response.data['message'] ?? 'Failed to update view count');
      }
    } on DioException catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException(e.message ?? 'Network error occurred');
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      throw ServerException('Unexpected error: $e');
    }
  }
}
