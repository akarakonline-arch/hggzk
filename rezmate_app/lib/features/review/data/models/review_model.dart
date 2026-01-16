import '../../domain/entities/review.dart';
import 'review_image_model.dart';

class ReviewModel extends Review {
  const ReviewModel({
    required super.id,
    required super.userId,
    required super.userName,
    super.userAvatar,
    required super.bookingId,
    required super.propertyId,
    required super.cleanliness,
    required super.service,
    required super.location,
    required super.value,
    required super.rating,
    required super.title,
    required super.comment,
    required super.createdAt,
    super.updatedAt,
    required super.images,
    required super.isUserReview,
    required super.likesCount,
    required super.isLikedByUser,
    super.managementReply,
    super.bookingType,
    required super.isRecommended,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userAvatar: json['userAvatar'],
      bookingId: json['bookingId'] ?? '',
      propertyId: json['propertyId'] ?? '',
      cleanliness: json['cleanliness'] ?? 0,
      service: json['service'] ?? 0,
      location: json['location'] ?? 0,
      value: json['value'] ?? 0,
      rating: (json['rating'] ?? 0).toDouble(),
      title: json['title'] ?? '',
      comment: json['comment'] ?? '',
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      images: (json['images'] as List?)
              ?.map((e) => ReviewImageModel.fromJson(e))
              .toList() ??
          [],
      isUserReview: json['isUserReview'] ?? false,
      likesCount: json['likesCount'] ?? 0,
      isLikedByUser: json['isLikedByUser'] ?? false,
      managementReply: json['managementReply'] != null
          ? ReviewReplyModel.fromJson(json['managementReply'])
          : null,
      bookingType: json['bookingType'],
      isRecommended: json['isRecommended'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'bookingId': bookingId,
      'propertyId': propertyId,
      'cleanliness': cleanliness,
      'service': service,
      'location': location,
      'value': value,
      'rating': rating,
      'title': title,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'images': images.map((e) => (e as ReviewImageModel).toJson()).toList(),
      'isUserReview': isUserReview,
      'likesCount': likesCount,
      'isLikedByUser': isLikedByUser,
      'managementReply': managementReply != null
          ? (managementReply as ReviewReplyModel).toJson()
          : null,
      'bookingType': bookingType,
      'isRecommended': isRecommended,
    };
  }

  Review toEntity() {
    return Review(
      id: id,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      bookingId: bookingId,
      propertyId: propertyId,
      cleanliness: cleanliness,
      service: service,
      location: location,
      value: value,
      rating: rating,
      title: title,
      comment: comment,
      createdAt: createdAt,
      updatedAt: updatedAt,
      images: images,
      isUserReview: isUserReview,
      likesCount: likesCount,
      isLikedByUser: isLikedByUser,
      managementReply: managementReply,
      bookingType: bookingType,
      isRecommended: isRecommended,
    );
  }
}

class ReviewReplyModel extends ReviewReply {
  const ReviewReplyModel({
    required super.id,
    required super.content,
    required super.createdAt,
    required super.replierName,
    required super.replierPosition,
  });

  factory ReviewReplyModel.fromJson(Map<String, dynamic> json) {
    return ReviewReplyModel(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      replierName: json['replierName'] ?? '',
      replierPosition: json['replierPosition'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'replierName': replierName,
      'replierPosition': replierPosition,
    };
  }
}

class ReviewsSummaryModel extends ReviewsSummary {
  const ReviewsSummaryModel({
    required super.totalReviews,
    required super.averageRating,
    required super.ratingDistribution,
    required super.ratingPercentages,
    required super.reviewsWithImagesCount,
    required super.recommendedCount,
    required super.latestReviews,
    required super.topReviews,
    required super.commonKeywords,
    required super.managementResponseRate,
  });

  factory ReviewsSummaryModel.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse numeric values that might come as strings
    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int _toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    // Convert ratingDistribution which may have string keys in JSON to Map<int,int>
    Map<int, int> _parseIntIntMap(dynamic src) {
      final result = <int, int>{};
      if (src is Map) {
        // src keys may be int or String
        src.forEach((k, v) {
          final key = k is int ? k : int.tryParse(k.toString()) ?? null;
          if (key != null) {
            result[key] = _toInt(v);
          }
        });
      }
      return result;
    }

    // Convert ratingPercentages which may have string keys and numeric/string values
    Map<int, double> _parseIntDoubleMap(dynamic src) {
      final result = <int, double>{};
      if (src is Map) {
        src.forEach((k, v) {
          final key = k is int ? k : int.tryParse(k.toString()) ?? null;
          if (key != null) {
            result[key] = _toDouble(v);
          }
        });
      }
      return result;
    }

    return ReviewsSummaryModel(
      totalReviews: _toInt(json['totalReviews']),
      averageRating: _toDouble(json['averageRating']),
      ratingDistribution: _parseIntIntMap(json['ratingDistribution'] ?? {}),
      ratingPercentages: _parseIntDoubleMap(json['ratingPercentages'] ?? {}),
      reviewsWithImagesCount: _toInt(json['reviewsWithImagesCount']),
      recommendedCount: _toInt(json['recommendedCount']),
      latestReviews: (json['latestReviews'] as List?)
              ?.map((e) => ReviewModel.fromJson(e))
              .toList() ??
          [],
      topReviews: (json['topReviews'] as List?)
              ?.map((e) => ReviewModel.fromJson(e))
              .toList() ??
          [],
      commonKeywords: (json['commonKeywords'] as List?)
              ?.map((e) => ReviewKeywordModel.fromJson(e))
              .toList() ??
          [],
      managementResponseRate: _toDouble(json['managementResponseRate']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalReviews': totalReviews,
      'averageRating': averageRating,
      'ratingDistribution': ratingDistribution,
      'ratingPercentages': ratingPercentages,
      'reviewsWithImagesCount': reviewsWithImagesCount,
      'recommendedCount': recommendedCount,
      'latestReviews':
          latestReviews.map((e) => (e as ReviewModel).toJson()).toList(),
      'topReviews': topReviews.map((e) => (e as ReviewModel).toJson()).toList(),
      'commonKeywords': commonKeywords
          .map((e) => (e as ReviewKeywordModel).toJson())
          .toList(),
      'managementResponseRate': managementResponseRate,
    };
  }

  ReviewsSummary toEntity() {
    return ReviewsSummary(
      totalReviews: totalReviews,
      averageRating: averageRating,
      ratingDistribution: ratingDistribution,
      ratingPercentages: ratingPercentages,
      reviewsWithImagesCount: reviewsWithImagesCount,
      recommendedCount: recommendedCount,
      latestReviews: latestReviews,
      topReviews: topReviews,
      commonKeywords: commonKeywords,
      managementResponseRate: managementResponseRate,
    );
  }
}

class ReviewKeywordModel extends ReviewKeyword {
  const ReviewKeywordModel({
    required super.keyword,
    required super.count,
    required super.percentage,
    required super.sentiment,
  });

  factory ReviewKeywordModel.fromJson(Map<String, dynamic> json) {
    return ReviewKeywordModel(
      keyword: json['keyword'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
      sentiment: json['sentiment'] ?? 'Neutral',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keyword': keyword,
      'count': count,
      'percentage': percentage,
      'sentiment': sentiment,
    };
  }
}
