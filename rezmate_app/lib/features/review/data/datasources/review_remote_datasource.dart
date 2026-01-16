import 'package:dio/dio.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/models/result_dto.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/request_logger.dart';
import '../models/review_model.dart';
import '../models/review_image_model.dart';

abstract class ReviewRemoteDataSource {
  Future<ReviewModel> createReview({
    required String bookingId,
    required String propertyId,
    required int cleanliness,
    required int service,
    required int location,
    required int value,
    required String comment,
    List<String>? imagesBase64,
  });

  Future<PaginatedResult<ReviewModel>> getPropertyReviews({
    required String propertyId,
    required int pageNumber,
    required int pageSize,
    int? rating,
    String? sortBy,
    String? sortDirection,
    bool? withImagesOnly,
    String? userId,
  });

  Future<ReviewsSummaryModel> getPropertyReviewsSummary({
    required String propertyId,
  });

  Future<List<ReviewImageModel>> uploadReviewImages({
    required String reviewId,
    required List<String> imagesBase64,
  });
}

class ReviewRemoteDataSourceImpl implements ReviewRemoteDataSource {
  final ApiClient apiClient;

  ReviewRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ReviewModel> createReview({
    required String bookingId,
    required String propertyId,
    required int cleanliness,
    required int service,
    required int location,
    required int value,
    required String comment,
    List<String>? imagesBase64,
  }) async {
    const requestName = 'review.createReview';
    logRequestStart(requestName, details: {
      'bookingId': bookingId,
      'propertyId': propertyId,
      'cleanliness': cleanliness,
      'service': service,
      'location': location,
      'value': value,
    });
    try {
      final response = await apiClient.post(
        '/api/client/Reviews',
        data: {
          'bookingId': bookingId,
          'propertyId': propertyId,
          'cleanliness': cleanliness,
          'service': service,
          'location': location,
          'value': value,
          'comment': comment,
          'imagesBase64': imagesBase64 ?? [],
        },
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      final resultDto = ResultDto<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json,
      );

      if (resultDto.success && resultDto.data != null) {
        final reviewData = resultDto.data!['review'] ?? resultDto.data!;
        return ReviewModel.fromJson(reviewData);
      } else {
        throw ServerException(
            resultDto.message ?? 'Failed to create review');
      }
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<PaginatedResult<ReviewModel>> getPropertyReviews({
    required String propertyId,
    required int pageNumber,
    required int pageSize,
    int? rating,
    String? sortBy,
    String? sortDirection,
    bool? withImagesOnly,
    String? userId,
  }) async {
    const requestName = 'review.getPropertyReviews';
    logRequestStart(requestName, details: {
      'propertyId': propertyId,
      'pageNumber': pageNumber,
      'pageSize': pageSize,
      if (rating != null) 'rating': rating,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortDirection != null) 'sortDirection': sortDirection,
      if (withImagesOnly != null) 'withImagesOnly': withImagesOnly,
      if (userId != null) 'userId': userId,
    });
    try {
      final queryParams = {
        'propertyId': propertyId,
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        if (rating != null) 'rating': rating,
        if (sortBy != null) 'sortBy': sortBy,
        if (sortDirection != null) 'sortDirection': sortDirection,
        if (withImagesOnly != null) 'withImagesOnly': withImagesOnly,
        if (userId != null) 'userId': userId,
      };

      final response = await apiClient.get(
        '/api/client/Reviews/property',
        queryParameters: queryParams,
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      // Debug: طباعة الاستجابة الخام لمعرفة شكل JSON الفعلي
      // (يمكنك حذف هذه الطباعة بعد التأكد)
      print('📥 [review.getPropertyReviews] raw response data: ${response.data}');

      final body = response.data;

      // 🔍 نحاول دعم أكثر من شكل لاستجابة الباكند
      // 1) { success, data: { items, pageNumber, pageSize, totalCount, ... } }
      // 2) { items, pageNumber, pageSize, totalCount, ... }

      Map<String, dynamic>? paginatedJson;

      if (body is Map<String, dynamic>) {
        // حالة وجود data
        final data = body['data'];
        if (data is Map) {
          paginatedJson = Map<String, dynamic>.from(data as Map);
        } else if (body['items'] is List) {
          // حالة أن النتيجة المرقمة في الجذر مباشرة
          paginatedJson = Map<String, dynamic>.from(body);
        }

        if (paginatedJson != null) {
          return PaginatedResult<ReviewModel>.fromJson(
            paginatedJson,
            (json) => ReviewModel.fromJson(
              Map<String, dynamic>.from(json),
            ),
          );
        }

        // إذا لم نجد items إطلاقًا نحاول قراءة الرسالة
        final message = (body['message'] ?? '').toString();
        if (message.contains('لم يتم العثور على البيانات')) {
          return PaginatedResult<ReviewModel>.empty(
            pageNumber: pageNumber,
            pageSize: pageSize,
          );
        }
      }

      // في حال كان الشكل غير متوقع نرمي استثناء مع بعض التفاصيل للمطور
      throw ServerException(
        'Failed to parse property reviews response. Body type: '
        '${body.runtimeType}',
      );
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      final message = e.toString();
      if (message.contains('لم يتم العثور على البيانات')) {
        return PaginatedResult<ReviewModel>.empty(
          pageNumber: pageNumber,
          pageSize: pageSize,
        );
      }

      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ReviewsSummaryModel> getPropertyReviewsSummary({
    required String propertyId,
  }) async {
    const requestName = 'review.getPropertyReviewsSummary';
    logRequestStart(requestName, details: {
      'propertyId': propertyId,
    });
    try {
      final response = await apiClient.get(
        '/api/client/Reviews/summary',
        queryParameters: {'propertyId': propertyId},
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      final resultDto = ResultDto<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json,
      );

      if (resultDto.success && resultDto.data != null) {
        return ReviewsSummaryModel.fromJson(resultDto.data!);
      } else {
        throw ServerException(
            resultDto.message ?? 'Failed to get reviews summary');
      }
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ReviewImageModel>> uploadReviewImages({
    required String reviewId,
    required List<String> imagesBase64,
  }) async {
    const requestName = 'review.uploadReviewImages';
    logRequestStart(requestName, details: {
      'reviewId': reviewId,
      'imagesCount': imagesBase64.length,
    });
    try {
      final formData = FormData();
      
      for (int i = 0; i < imagesBase64.length; i++) {
        final bytes = imagesBase64[i].split(',').last;
        formData.files.add(
          MapEntry(
            'files',
            MultipartFile.fromString(
              bytes,
              filename: 'review_image_$i.jpg',
            ),
          ),
        );
      }
      
      formData.fields.add(const MapEntry('category', 'review'));
      formData.fields.add(MapEntry('reviewId', reviewId));

      final response = await apiClient.upload(
        '/Reviews/upload',
        formData: formData,
      );

      logRequestSuccess(requestName, statusCode: response.statusCode);

      final resultDto = ResultDto<List<dynamic>>.fromJson(
        response.data,
        (json) => json as List<dynamic>,
      );

      if (resultDto.success && resultDto.data != null) {
        return resultDto.data!
            .map((item) => ReviewImageModel.fromJson(item))
            .toList();
      } else {
        throw ServerException(
            resultDto.message ?? 'Failed to upload review images');
      }
    } catch (e, s) {
      logRequestError(requestName, e, stackTrace: s);
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }
}