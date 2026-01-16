import 'package:dartz/dartz.dart';
import 'package:hggzk/core/usecases/usecase.dart';
import 'package:hggzk/features/search/domain/entities/search_result.dart';
import '../../../../core/error/failures.dart';
import '../repositories/search_repository.dart';

class GetSearchFiltersUseCase implements UseCase<SearchFilters, NoParams> {
  final SearchRepository repository;

  GetSearchFiltersUseCase(this.repository);

  @override
  Future<Either<Failure, SearchFilters>> call(NoParams params) async {
    return await repository.getSearchFilters();
  }
}