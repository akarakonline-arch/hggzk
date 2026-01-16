import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_property_details_usecase.dart';
import '../../domain/usecases/get_property_units_usecase.dart';
import '../../domain/usecases/get_property_reviews_usecase.dart';
import '../../domain/usecases/add_to_favorites_usecase.dart';
import '../../domain/usecases/remove_from_favorites_usecase.dart';
import '../../domain/usecases/check_property_availability_usecase.dart';
import '../../../../services/filter_storage_service.dart';
import '../../../../injection_container.dart';
import 'property_event.dart';
import 'property_state.dart';

class PropertyBloc extends Bloc<PropertyEvent, PropertyState> {
  final GetPropertyDetailsUseCase getPropertyDetailsUseCase;
  final GetPropertyUnitsUseCase getPropertyUnitsUseCase;
  final GetPropertyReviewsUseCase getPropertyReviewsUseCase;
  final AddToFavoritesUseCase addToFavoritesUseCase;
  final RemoveFromFavoritesUseCase removeFromFavoritesUseCase;
  final CheckPropertyAvailabilityUseCase checkPropertyAvailabilityUseCase;

  PropertyBloc({
    required this.getPropertyDetailsUseCase,
    required this.getPropertyUnitsUseCase,
    required this.getPropertyReviewsUseCase,
    required this.addToFavoritesUseCase,
    required this.removeFromFavoritesUseCase,
    required this.checkPropertyAvailabilityUseCase,
  }) : super(PropertyInitial()) {
    on<GetPropertyDetailsEvent>(_onGetPropertyDetails);
    on<GetPropertyUnitsEvent>(_onGetPropertyUnits);
    on<GetPropertyReviewsEvent>(_onGetPropertyReviews);
    on<AddToFavoritesEvent>(_onAddToFavorites);
    on<RemoveFromFavoritesEvent>(_onRemoveFromFavorites);
    on<UpdateViewCountEvent>(_onUpdateViewCount);
    on<ToggleFavoriteEvent>(_onToggleFavorite);
    on<SelectUnitEvent>(_onSelectUnit);
    on<SelectImageEvent>(_onSelectImage);
    on<CheckPropertyAvailabilityEvent>(_onCheckPropertyAvailability);
  }

  Future<void> _onGetPropertyDetails(
    GetPropertyDetailsEvent event,
    Emitter<PropertyState> emit,
  ) async {
    emit(PropertyLoading());

    final result = await getPropertyDetailsUseCase(
      GetPropertyDetailsParams(
        propertyId: event.propertyId,
        userId: event.userId,
        userRole: event.userRole,
      ),
    );

    result.fold(
      (failure) => emit(PropertyError(message: failure.message)),
      (property) {
        emit(PropertyDetailsLoaded(
          property: property,
          isFavorite: property.isFavorite,
        ));

        // Load saved dates and guests from FilterStorageService to fetch dynamic unit pricing
        final selections = sl<FilterStorageService>().getHomeSelections();
        final DateTime? checkIn = selections['checkIn'] as DateTime?;
        final DateTime? checkOut = selections['checkOut'] as DateTime?;
        final int adults = (selections['adults'] as int?) ?? 1;
        final int children = (selections['children'] as int?) ?? 0;
        final int guests = (adults + children) <= 0 ? 1 : (adults + children);

        if (checkIn != null && checkOut != null) {
          add(CheckPropertyAvailabilityEvent(
            propertyId: event.propertyId,
            checkInDate: checkIn,
            checkOutDate: checkOut,
            guestsCount: guests,
          ));
        }
      },
    );
  }

  Future<void> _onGetPropertyUnits(
    GetPropertyUnitsEvent event,
    Emitter<PropertyState> emit,
  ) async {
    final previousState = state;

    final result = await getPropertyUnitsUseCase(
      GetPropertyUnitsParams(
        propertyId: event.propertyId,
        checkInDate: event.checkInDate,
        checkOutDate: event.checkOutDate,
        guestsCount: event.guestsCount,
      ),
    );

    result.fold(
      (failure) {
        // Preserve current details UI; do not break if units call fails
        if (previousState is PropertyDetailsLoaded ||
            previousState is PropertyWithDetails) {
          return;
        }
        emit(PropertyError(message: failure.message));
      },
      (units) {
        if (previousState is PropertyWithDetails) {
          emit(previousState.copyWith(units: units));
        } else if (previousState is PropertyDetailsLoaded) {
          final latest = state;
          final latestIsFavorite = latest is PropertyWithDetails
              ? latest.isFavorite
              : latest is PropertyDetailsLoaded
                  ? latest.isFavorite
                  : previousState.isFavorite;
          final latestPending = latest is PropertyWithDetails
              ? latest.isFavoritePending
              : latest is PropertyDetailsLoaded
                  ? latest.isFavoritePending
                  : false;
          final latestQueued = latest is PropertyWithDetails
              ? latest.queuedFavoriteTarget
              : latest is PropertyDetailsLoaded
                  ? latest.queuedFavoriteTarget
                  : null;
          final latestProperty = latest is PropertyWithDetails
              ? latest.property
              : latest is PropertyDetailsLoaded
                  ? latest.property
                  : previousState.property;
          final latestSelectedIndex = latest is PropertyWithDetails
              ? latest.selectedImageIndex
              : latest is PropertyDetailsLoaded
                  ? latest.selectedImageIndex
                  : previousState.selectedImageIndex;
          final latestSelectedUnitId = latest is PropertyWithDetails
              ? latest.selectedUnitId
              : latest is PropertyDetailsLoaded
                  ? latest.selectedUnitId
                  : previousState.selectedUnitId;
          final latestAvailability = latest is PropertyWithDetails
              ? latest.availability
              : latest is PropertyDetailsLoaded
                  ? latest.availability
                  : previousState.availability;
          emit(PropertyWithDetails(
            property: latestProperty,
            units: units,
            reviews: const [],
            isFavorite: latestIsFavorite,
            selectedImageIndex: latestSelectedIndex,
            selectedUnitId: latestSelectedUnitId,
            isFavoritePending: latestPending,
            queuedFavoriteTarget: latestQueued,
            availability: latestAvailability,
          ));
        } else {
          emit(PropertyUnitsLoaded(
            units: units,
            checkInDate: event.checkInDate,
            checkOutDate: event.checkOutDate,
            guestsCount: event.guestsCount,
          ));
        }
      },
    );
  }

  Future<void> _onGetPropertyReviews(
    GetPropertyReviewsEvent event,
    Emitter<PropertyState> emit,
  ) async {
    emit(PropertyReviewsLoading());

    final result = await getPropertyReviewsUseCase(
      GetPropertyReviewsParams(
        propertyId: event.propertyId,
        pageNumber: event.pageNumber,
        pageSize: event.pageSize,
        sortBy: event.sortBy,
        sortDirection: event.sortDirection,
        withImagesOnly: event.withImagesOnly,
        userId: event.userId,
      ),
    );

    result.fold(
      (failure) => emit(PropertyError(message: failure.message)),
      (reviews) => emit(PropertyReviewsLoaded(
        reviews: reviews,
        currentPage: event.pageNumber,
        hasReachedMax: reviews.length < event.pageSize,
      )),
    );
  }

  Future<void> _onAddToFavorites(
    AddToFavoritesEvent event,
    Emitter<PropertyState> emit,
  ) async {
    final result = await addToFavoritesUseCase(
      AddToFavoritesParams(
        propertyId: event.propertyId,
        userId: event.userId,
        notes: event.notes,
        desiredVisitDate: event.desiredVisitDate,
        expectedBudget: event.expectedBudget,
        currency: event.currency,
      ),
    );

    result.fold(
      (failure) {
        final s = state;
        if (s is PropertyDetailsLoaded) {
          final queued = s.queuedFavoriteTarget;
          emit(s.copyWith(isFavorite: false, isFavoritePending: false));
          if (queued != null && queued != false) {
            emit(s.copyWith(
                isFavorite: queued,
                isFavoritePending: true,
                queuedFavoriteTarget: null));
            add(queued
                ? AddToFavoritesEvent(
                    propertyId: event.propertyId, userId: event.userId)
                : RemoveFromFavoritesEvent(
                    propertyId: event.propertyId, userId: event.userId));
          }
        } else if (s is PropertyWithDetails) {
          final queued = s.queuedFavoriteTarget;
          emit(s.copyWith(isFavorite: false, isFavoritePending: false));
          if (queued != null && queued != false) {
            emit(s.copyWith(
                isFavorite: queued,
                isFavoritePending: true,
                queuedFavoriteTarget: null));
            add(queued
                ? AddToFavoritesEvent(
                    propertyId: event.propertyId, userId: event.userId)
                : RemoveFromFavoritesEvent(
                    propertyId: event.propertyId, userId: event.userId));
          }
        }
      },
      (success) {
        final s = state;
        if (s is PropertyDetailsLoaded) {
          final queued = s.queuedFavoriteTarget;
          if (queued == null) {
            emit(s.copyWith(isFavorite: true, isFavoritePending: false));
          } else if (queued == true) {
            emit(s.copyWith(
                isFavorite: true,
                isFavoritePending: false,
                queuedFavoriteTarget: null));
          } else {
            emit(s.copyWith(
                isFavorite: false,
                isFavoritePending: true,
                queuedFavoriteTarget: null));
            add(RemoveFromFavoritesEvent(
                propertyId: event.propertyId, userId: event.userId));
          }
        } else if (s is PropertyWithDetails) {
          final queued = s.queuedFavoriteTarget;
          if (queued == null) {
            emit(s.copyWith(isFavorite: true, isFavoritePending: false));
          } else if (queued == true) {
            emit(s.copyWith(
                isFavorite: true,
                isFavoritePending: false,
                queuedFavoriteTarget: null));
          } else {
            emit(s.copyWith(
                isFavorite: false,
                isFavoritePending: true,
                queuedFavoriteTarget: null));
            add(RemoveFromFavoritesEvent(
                propertyId: event.propertyId, userId: event.userId));
          }
        }
        emit(const PropertyFavoriteUpdated(
          isFavorite: true,
          message: 'تمت الإضافة إلى المفضلة',
        ));
      },
    );
  }

  Future<void> _onRemoveFromFavorites(
    RemoveFromFavoritesEvent event,
    Emitter<PropertyState> emit,
  ) async {
    final result = await removeFromFavoritesUseCase(
      RemoveFromFavoritesParams(
        propertyId: event.propertyId,
        userId: event.userId,
      ),
    );

    result.fold(
      (failure) {
        final s = state;
        if (s is PropertyDetailsLoaded) {
          final queued = s.queuedFavoriteTarget;
          emit(s.copyWith(isFavorite: true, isFavoritePending: false));
          if (queued != null && queued != true) {
            emit(s.copyWith(
                isFavorite: queued,
                isFavoritePending: true,
                queuedFavoriteTarget: null));
            add(queued
                ? AddToFavoritesEvent(
                    propertyId: event.propertyId, userId: event.userId)
                : RemoveFromFavoritesEvent(
                    propertyId: event.propertyId, userId: event.userId));
          }
        } else if (s is PropertyWithDetails) {
          final queued = s.queuedFavoriteTarget;
          emit(s.copyWith(isFavorite: true, isFavoritePending: false));
          if (queued != null && queued != true) {
            emit(s.copyWith(
                isFavorite: queued,
                isFavoritePending: true,
                queuedFavoriteTarget: null));
            add(queued
                ? AddToFavoritesEvent(
                    propertyId: event.propertyId, userId: event.userId)
                : RemoveFromFavoritesEvent(
                    propertyId: event.propertyId, userId: event.userId));
          }
        }
      },
      (success) {
        final s = state;
        if (s is PropertyDetailsLoaded) {
          final queued = s.queuedFavoriteTarget;
          if (queued == null) {
            emit(s.copyWith(isFavorite: false, isFavoritePending: false));
          } else if (queued == false) {
            emit(s.copyWith(
                isFavorite: false,
                isFavoritePending: false,
                queuedFavoriteTarget: null));
          } else {
            emit(s.copyWith(
                isFavorite: true,
                isFavoritePending: true,
                queuedFavoriteTarget: null));
            add(AddToFavoritesEvent(
                propertyId: event.propertyId, userId: event.userId));
          }
        } else if (s is PropertyWithDetails) {
          final queued = s.queuedFavoriteTarget;
          if (queued == null) {
            emit(s.copyWith(isFavorite: false, isFavoritePending: false));
          } else if (queued == false) {
            emit(s.copyWith(
                isFavorite: false,
                isFavoritePending: false,
                queuedFavoriteTarget: null));
          } else {
            emit(s.copyWith(
                isFavorite: true,
                isFavoritePending: true,
                queuedFavoriteTarget: null));
            add(AddToFavoritesEvent(
                propertyId: event.propertyId, userId: event.userId));
          }
        }
        emit(const PropertyFavoriteUpdated(
          isFavorite: false,
          message: 'تمت الإزالة من المفضلة',
        ));
      },
    );
  }

  Future<void> _onUpdateViewCount(
    UpdateViewCountEvent event,
    Emitter<PropertyState> emit,
  ) async {
    // Silently update view count
  }

  Future<void> _onToggleFavorite(
    ToggleFavoriteEvent event,
    Emitter<PropertyState> emit,
  ) async {
    final s = state;
    final bool currentIsFavorite = s is PropertyDetailsLoaded
        ? s.isFavorite
        : s is PropertyWithDetails
            ? s.isFavorite
            : event.isFavorite;
    final bool newIsFavorite = !currentIsFavorite;
    if (s is PropertyDetailsLoaded) {
      if (s.isFavoritePending) {
        emit(s.copyWith(
            isFavorite: newIsFavorite, queuedFavoriteTarget: newIsFavorite));
        return;
      }
      emit(s.copyWith(
          isFavorite: newIsFavorite,
          isFavoritePending: true,
          queuedFavoriteTarget: null));
    } else if (s is PropertyWithDetails) {
      if (s.isFavoritePending) {
        emit(s.copyWith(
            isFavorite: newIsFavorite, queuedFavoriteTarget: newIsFavorite));
        return;
      }
      emit(s.copyWith(
          isFavorite: newIsFavorite,
          isFavoritePending: true,
          queuedFavoriteTarget: null));
    }
    if (currentIsFavorite) {
      add(RemoveFromFavoritesEvent(
        propertyId: event.propertyId,
        userId: event.userId,
      ));
    } else {
      add(AddToFavoritesEvent(
        propertyId: event.propertyId,
        userId: event.userId,
      ));
    }
  }

  Future<void> _onSelectUnit(
    SelectUnitEvent event,
    Emitter<PropertyState> emit,
  ) async {
    print('[PropertyBloc] SelectUnitEvent: unitId=${event.unitId}');
    print('[PropertyBloc] current state type: ${state.runtimeType}');
    if (state is PropertyDetailsLoaded) {
      final currentState = state as PropertyDetailsLoaded;
      final currentSelected = currentState.selectedUnitId;
      final newSelected = currentSelected == event.unitId ? null : event.unitId;
      print(
          '[PropertyBloc] emitting PropertyDetailsLoaded with selectedUnitId=$newSelected');
      emit(PropertyDetailsLoaded(
        property: currentState.property,
        isFavorite: currentState.isFavorite,
        selectedImageIndex: currentState.selectedImageIndex,
        selectedUnitId: newSelected,
        isFavoritePending: currentState.isFavoritePending,
        queuedFavoriteTarget: currentState.queuedFavoriteTarget,
        availability: currentState.availability,
      ));
    } else if (state is PropertyUnitsLoaded) {
      final currentState = state as PropertyUnitsLoaded;
      final currentSelected = currentState.selectedUnitId;
      final newSelected = currentSelected == event.unitId ? null : event.unitId;
      print(
          '[PropertyBloc] emitting PropertyUnitsLoaded with selectedUnitId=$newSelected');
      emit(PropertyUnitsLoaded(
        units: currentState.units,
        selectedUnitId: newSelected,
        checkInDate: currentState.checkInDate,
        checkOutDate: currentState.checkOutDate,
        guestsCount: currentState.guestsCount,
      ));
    } else if (state is PropertyWithDetails) {
      final currentState = state as PropertyWithDetails;
      final currentSelected = currentState.selectedUnitId;
      final newSelected = currentSelected == event.unitId ? null : event.unitId;
      print(
          '[PropertyBloc] emitting PropertyWithDetails with selectedUnitId=$newSelected');
      emit(PropertyWithDetails(
        property: currentState.property,
        units: currentState.units,
        reviews: currentState.reviews,
        isFavorite: currentState.isFavorite,
        selectedImageIndex: currentState.selectedImageIndex,
        selectedUnitId: newSelected,
        isFavoritePending: currentState.isFavoritePending,
        queuedFavoriteTarget: currentState.queuedFavoriteTarget,
        availability: currentState.availability,
      ));
    } else {
      print(
          '[PropertyBloc] WARNING: SelectUnitEvent ignored, state type: ${state.runtimeType}');
    }
  }

  Future<void> _onSelectImage(
    SelectImageEvent event,
    Emitter<PropertyState> emit,
  ) async {
    if (state is PropertyDetailsLoaded) {
      final currentState = state as PropertyDetailsLoaded;
      emit(currentState.copyWith(selectedImageIndex: event.imageIndex));
    } else if (state is PropertyWithDetails) {
      final currentState = state as PropertyWithDetails;
      emit(currentState.copyWith(selectedImageIndex: event.imageIndex));
    }
  }

  Future<void> _onCheckPropertyAvailability(
    CheckPropertyAvailabilityEvent event,
    Emitter<PropertyState> emit,
  ) async {
    final params = CheckPropertyAvailabilityParams(
      propertyId: event.propertyId,
      checkInDate: event.checkInDate,
      checkOutDate: event.checkOutDate,
      guestsCount: event.guestsCount,
    );

    final result = await checkPropertyAvailabilityUseCase(params);

    result.fold(
      (failure) {
        final s = state;
        if (s is PropertyWithDetails) {
          emit(s.copyWith(availability: null));
        } else if (s is PropertyDetailsLoaded) {
          emit(s.copyWith(availability: null));
        }
      },
      (availability) {
        final s = state;
        if (s is PropertyWithDetails) {
          emit(s.copyWith(availability: availability));
        } else if (s is PropertyDetailsLoaded) {
          emit(s.copyWith(availability: availability));
        }
      },
    );
  }
}
