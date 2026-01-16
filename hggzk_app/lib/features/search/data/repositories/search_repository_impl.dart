import 'package:dartz/dartz.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/paginated_result.dart';
import '../../../../core/enums/search_relaxation_level.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_datasource.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource remoteDataSource;

  SearchRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, PaginatedResult<SearchResult>>> searchProperties({
    String? searchTerm,
    String? city,
    String? propertyTypeId,
    double? minPrice,
    double? maxPrice,
    int? minStarRating,
    List<String>? requiredAmenities,
    String? unitTypeId,
    List<String>? serviceIds,
    DateTime? checkIn,
    DateTime? checkOut,
    int? adults,
    int? children,
    int? guestsCount,
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? preferredCurrency,
    String? sortBy,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    try {
      final result = await remoteDataSource.searchProperties(
        searchTerm: searchTerm,
        city: city,
        propertyTypeId: propertyTypeId,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minStarRating: minStarRating,
        requiredAmenities: requiredAmenities,
        unitTypeId: unitTypeId,
        serviceIds: serviceIds,
        checkIn: checkIn,
        checkOut: checkOut,
        adults: adults,
        children: children,
        guestsCount: guestsCount,
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        preferredCurrency: preferredCurrency,
        sortBy: sortBy,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );

      if (result.isSuccess && result.data != null) {
        final dto = result.data!;

        // Debug: Print response details
        print('🔍 [SearchRepository] Response received:');
        print('   - Properties count: ${dto.properties.length}');
        print('   - wasRelaxed: ${dto.wasRelaxed}');
        print('   - relaxationLevel: ${dto.relaxationLevel}');
        print('   - userMessage: ${dto.userMessage}');
        print('   - relaxedFilters: ${dto.relaxedFilters}');

        // Debug: Check filterMismatches in properties
        for (var prop in dto.properties) {
          if (prop.filterMismatches.isNotEmpty) {
            print(
                '   - Property "${prop.name}" has ${prop.filterMismatches.length} mismatches');
          }
        }

        final paginatedResult = PaginatedResult<SearchResult>(
          items: dto.properties.map((model) => model as SearchResult).toList(),
          pageNumber: dto.currentPage,
          pageSize: dto.pageSize,
          totalCount: dto.totalCount,
          metadata: {
            'totalPages': dto.totalPages,
            'hasPreviousPage': dto.hasPreviousPage,
            'hasNextPage': dto.hasNextPage,
            'appliedFilters': dto.appliedFilters,
            'searchTimeMs': dto.searchTimeMs,
            'statistics': dto.statistics,
            'relaxationLevel': _relaxationLevelToString(dto.relaxationLevel),
            'relaxedFilters': dto.relaxedFilters,
            'searchStrategy': dto.searchStrategy,
            'originalCriteria': dto.originalCriteria,
            'actualCriteria': dto.actualCriteria,
            'userMessage': dto.userMessage,
            'suggestedActions': dto.suggestedActions,
            'wasRelaxed': dto.wasRelaxed,
          },
        );
        return Right(paginatedResult);
      } else {
        return Left(ServerFailure(result.message ?? 'Search failed'));
      }
    } catch (error) {
      return ErrorHandler.handle(error);
    }
  }

  @override
  Future<Either<Failure, SearchFilters>> getSearchFilters() async {
    try {
      final result = await remoteDataSource.getSearchFilters();

      if (result.isSuccess && result.data != null) {
        return Right(result.data! as SearchFilters);
      } else {
        return Left(
            ServerFailure(result.message ?? 'Failed to get search filters'));
      }
    } catch (error) {
      return ErrorHandler.handle(error);
    }
  }

  @override
  Future<Either<Failure, List<String>>> getSearchSuggestions({
    required String query,
    int limit = 10,
  }) async {
    try {
      final result = await remoteDataSource.getSearchSuggestions(
        query: query,
        limit: limit,
      );

      if (result.isSuccess && result.data != null) {
        return Right(result.data!);
      } else {
        return Left(
            ServerFailure(result.message ?? 'Failed to get suggestions'));
      }
    } catch (error) {
      return ErrorHandler.handle(error);
    }
  }

  @override
  Future<Either<Failure, List<SearchResult>>> getRecommendedProperties({
    String? userId,
    int limit = 10,
  }) async {
    try {
      final result = await remoteDataSource.getRecommendedProperties(
        userId: userId,
        limit: limit,
      );

      if (result.isSuccess && result.data != null) {
        final recommendations =
            result.data!.items.map((model) => model as SearchResult).toList();
        return Right(recommendations);
      } else {
        return Left(
            ServerFailure(result.message ?? 'Failed to get recommendations'));
      }
    } catch (error) {
      return ErrorHandler.handle(error);
    }
  }

  @override
  Future<Either<Failure, List<String>>> getPopularDestinations({
    int limit = 10,
  }) async {
    try {
      final result = await remoteDataSource.getPopularDestinations(
        limit: limit,
      );

      if (result.isSuccess && result.data != null) {
        return Right(result.data!);
      } else {
        return Left(ServerFailure(
            result.message ?? 'Failed to get popular destinations'));
      }
    } catch (error) {
      return ErrorHandler.handle(error);
    }
  }

  String _relaxationLevelToString(SearchRelaxationLevel level) {
    switch (level) {
      case SearchRelaxationLevel.exact:
        return 'Exact';
      case SearchRelaxationLevel.minorRelaxation:
        return 'MinorRelaxation';
      case SearchRelaxationLevel.moderateRelaxation:
        return 'ModerateRelaxation';
      case SearchRelaxationLevel.majorRelaxation:
        return 'MajorRelaxation';
      case SearchRelaxationLevel.alternativeSuggestions:
        return 'AlternativeSuggestions';
    }
  }
}
