import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/models/paginated_result.dart';
import '../models/amenity_model.dart';

abstract class AmenitiesRemoteDataSource {
  Future<String> createAmenity({
    required String name,
    required String description,
    required String icon,
    String? propertyTypeId,
    bool isDefaultForType = false,
  });

  Future<bool> updateAmenity({
    required String amenityId,
    String? name,
    String? description,
    String? icon,
  });

  Future<bool> deleteAmenity(String amenityId);

  Future<PaginatedResult<AmenityModel>> getAllAmenities({
    int? pageNumber,
    int? pageSize,
    String? searchTerm,
    String? propertyId,
    bool? isAssigned,
    bool? isFree,
    String? propertyTypeId,
  });

  Future<bool> assignAmenityToProperty({
    required String amenityId,
    required String propertyId,
    bool isAvailable = true,
    double? extraCost,
    String? description,
  });

  Future<AmenityStatsModel> getAmenityStats();

  Future<bool> toggleAmenityStatus(String amenityId);

  Future<List<AmenityModel>> getPopularAmenities({int limit = 10});

  Future<bool> assignAmenityToPropertyType({
    required String amenityId,
    required String propertyTypeId,
    bool isDefault = false,
  });
}

class AmenitiesRemoteDataSourceImpl implements AmenitiesRemoteDataSource {
  final ApiClient apiClient;
  static const String _baseEndpoint = '/api/admin/amenities';

  AmenitiesRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<String> createAmenity({
    required String name,
    required String description,
    required String icon,
    String? propertyTypeId,
    bool isDefaultForType = false,
  }) async {
    try {
      final response = await apiClient.post(
        _baseEndpoint,
        data: {
          'name': name,
          'description': description,
          'icon': icon,
          if (propertyTypeId != null) 'propertyTypeId': propertyTypeId,
          if (propertyTypeId != null) 'isDefaultForType': isDefaultForType,
        },
      );

      if (response.data['isSuccess'] == true ||
          response.data['success'] == true) {
        return (response.data['data'] ?? response.data['id'] ?? '').toString();
      } else {
        throw ApiException(
            message: response.data['message'] ?? 'فشل إنشاء المرفق');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<bool> updateAmenity({
    required String amenityId,
    String? name,
    String? description,
    String? icon,
  }) async {
    try {
      final response = await apiClient.put(
        '$_baseEndpoint/$amenityId',
        data: {
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (icon != null) 'icon': icon,
        },
      );

      if (response.data['isSuccess'] == true ||
          response.data['success'] == true) {
        return true;
      } else {
        throw ApiException(
            message: response.data['message'] ?? 'فشل تحديث المرفق');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<bool> deleteAmenity(String amenityId) async {
    try {
      final response = await apiClient.delete('$_baseEndpoint/$amenityId');

      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        if (map['isSuccess'] == true || map['success'] == true) return true;
        // Surface backend reason on conflict
        if (response.statusCode == 409 ||
            map['errorCode'] == 'AMENITY_DELETE_CONFLICT') {
          throw ApiException(
              message:
                  map['message'] ?? 'لا يمكن حذف المرفق لارتباطه ببيانات أخرى',
              statusCode: 409,
              code: 'AMENITY_DELETE_CONFLICT');
        }
      }
      if (response.statusCode == 200 || response.statusCode == 204) return true;
      throw ApiException(message: response.data['message'] ?? 'فشل حذف المرفق');
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<PaginatedResult<AmenityModel>> getAllAmenities({
    int? pageNumber,
    int? pageSize,
    String? searchTerm,
    String? propertyId,
    bool? isAssigned,
    bool? isFree,
    String? propertyTypeId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (pageNumber != null) queryParams['pageNumber'] = pageNumber;
      if (pageSize != null) queryParams['pageSize'] = pageSize;
      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParams['searchTerm'] = searchTerm;
      }
      if (propertyId != null) queryParams['propertyId'] = propertyId;
      if (isAssigned != null) queryParams['isAssigned'] = isAssigned;
      if (isFree != null) queryParams['isFree'] = isFree;
      if (propertyTypeId != null)
        queryParams['propertyTypeId'] = propertyTypeId;

      final response = await apiClient.get(
        _baseEndpoint,
        queryParameters: queryParams,
      );

      if (response.data != null) {
        // Handle multiple response formats from different backend versions
        dynamic root = response.data;

        // If wrapped in 'data' object, unwrap it
        if (root is Map && root['data'] is Map) {
          root = root['data'];
        }

        List<dynamic> itemsList = [];
        int totalCount = 0;
        int currentPage = pageNumber ?? 1;
        int currentPageSize = pageSize ?? 10;

        // Handle different response structures
        if (root is Map) {
          // Try different key names for items array
          if (root['items'] != null && root['items'] is List) {
            itemsList = root['items'] as List;
          } else if (root['Items'] != null && root['Items'] is List) {
            itemsList = root['Items'] as List;
          }

          // Try different key names for total count
          totalCount = root['totalCount'] ??
              root['total'] ??
              root['Total'] ??
              itemsList.length;

          // Try different key names for page number
          currentPage =
              root['pageNumber'] ?? root['page'] ?? root['Page'] ?? currentPage;

          // Try different key names for page size
          currentPageSize = root['pageSize'] ??
              root['limit'] ??
              root['Limit'] ??
              currentPageSize;
        } else if (root is List) {
          itemsList = root;
          totalCount = itemsList.length;
        }

        final items = itemsList
            .map((json) => AmenityModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return PaginatedResult<AmenityModel>(
          items: items,
          totalCount: totalCount,
          pageNumber: currentPage,
          pageSize: currentPageSize,
        );
      } else {
        throw ApiException(message: 'استجابة غير صالحة من الخادم');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<bool> assignAmenityToProperty({
    required String amenityId,
    required String propertyId,
    bool isAvailable = true,
    double? extraCost,
    String? description,
  }) async {
    try {
      final response = await apiClient.post(
        '$_baseEndpoint/$amenityId/assign/property/$propertyId',
        data: {
          'isAvailable': isAvailable,
          if (extraCost != null) 'extraCost': extraCost,
          if (description != null) 'description': description,
        },
      );

      if (response.data['isSuccess'] == true) {
        return true;
      } else {
        throw ApiException(
            message: response.data['message'] ?? 'فشل إسناد المرفق');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<AmenityStatsModel> getAmenityStats() async {
    try {
      final response = await apiClient.get('$_baseEndpoint/stats');

      if (response.data['isSuccess'] == true ||
          response.data['success'] == true) {
        return AmenityStatsModel.fromJson(response.data['data']);
      } else {
        throw ApiException(
            message: response.data['message'] ?? 'فشل جلب الإحصائيات');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<bool> toggleAmenityStatus(String amenityId) async {
    try {
      final response = await apiClient.post(
        '$_baseEndpoint/$amenityId/toggle-status',
      );

      if (response.data['isSuccess'] == true ||
          response.data['success'] == true) {
        return true;
      } else {
        throw ApiException(
            message: response.data['message'] ?? 'فشل تغيير الحالة');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<List<AmenityModel>> getPopularAmenities({int limit = 10}) async {
    try {
      final response = await apiClient.get(
        '$_baseEndpoint/popular',
        queryParameters: {'limit': limit},
      );

      if (response.data['isSuccess'] == true ||
          response.data['success'] == true) {
        return (response.data['data'] as List? ?? [])
            .map((json) => AmenityModel.fromJson(json))
            .toList();
      } else {
        throw ApiException(
            message: response.data['message'] ?? 'فشل جلب المرافق الشائعة');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<bool> assignAmenityToPropertyType({
    required String amenityId,
    required String propertyTypeId,
    bool isDefault = false,
  }) async {
    try {
      final response = await apiClient.post(
        '$_baseEndpoint/$amenityId/assign/property-type/$propertyTypeId',
        data: {
          'isDefault': isDefault,
        },
      );

      if (response.data['isSuccess'] == true ||
          response.data['success'] == true) {
        return true;
      } else {
        throw ApiException(
            message: response.data['message'] ?? 'فشل ربط المرفق بنوع العقار');
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}
