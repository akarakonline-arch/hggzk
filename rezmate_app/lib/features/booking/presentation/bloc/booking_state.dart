import 'package:equatable/equatable.dart';
import '../../domain/entities/booking.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {
  const BookingInitial();
}

class BookingLoading extends BookingState {
  const BookingLoading();
}

class CheckingAvailability extends BookingState {
  const CheckingAvailability();
}

class BookingError extends BookingState {
  final String message;
  final bool showAsDialog;
  final String? code;

  const BookingError({
    required this.message,
    this.showAsDialog = false,
    this.code,
  });

  @override
  List<Object> get props => [message, showAsDialog, code ?? ''];
}

class BookingCreated extends BookingState {
  final Booking booking;

  const BookingCreated({required this.booking});

  @override
  List<Object> get props => [booking];
}

class BookingDetailsLoaded extends BookingState {
  final Booking booking;

  const BookingDetailsLoaded({required this.booking});

  @override
  List<Object> get props => [booking];
}

class BookingCancelled extends BookingState {
  const BookingCancelled();
}

class UserBookingsLoaded extends BookingState {
  final List<Booking> bookings;
  final bool hasMore;
  final int currentPage;
  final int totalCount;
  final bool isLoadingMore;

  const UserBookingsLoaded({
    required this.bookings,
    required this.hasMore,
    required this.currentPage,
    required this.totalCount,
    this.isLoadingMore = false,
  });

  UserBookingsLoaded copyWith({
    List<Booking>? bookings,
    bool? hasMore,
    int? currentPage,
    int? totalCount,
    bool? isLoadingMore,
  }) {
    return UserBookingsLoaded(
      bookings: bookings ?? this.bookings,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object> get props => [bookings, hasMore, currentPage, totalCount, isLoadingMore];
}

class UserBookingsSummaryLoaded extends BookingState {
  final Map<String, dynamic> summary;

  const UserBookingsSummaryLoaded({required this.summary});

  @override
  List<Object> get props => [summary];
}

class ServicesAddedToBooking extends BookingState {
  final Booking booking;

  const ServicesAddedToBooking({required this.booking});

  @override
  List<Object> get props => [booking];
}

class AvailabilityChecked extends BookingState {
  final bool isAvailable;
  final double? pricePerNight;
  final double? totalPrice;
  final String? currency;
  final int? totalDays;

  const AvailabilityChecked({
    required this.isAvailable,
    this.pricePerNight,
    this.totalPrice,
    this.currency,
    this.totalDays,
  });

  @override
  List<Object?> get props => [
        isAvailable,
        pricePerNight,
        totalPrice,
        currency,
        totalDays,
      ];
}

class BookingFormUpdated extends BookingState {
  final Map<String, dynamic> formData;

  const BookingFormUpdated({required this.formData});

  @override
  List<Object> get props => [formData];
}

class BookingUpdated extends BookingState {
  const BookingUpdated();
}