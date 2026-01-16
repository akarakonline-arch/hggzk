import 'package:equatable/equatable.dart';

abstract class SupportState extends Equatable {
  const SupportState();

  @override
  List<Object?> get props => [];
}

class SupportInitial extends SupportState {}

class SupportLoading extends SupportState {}

class SupportSuccess extends SupportState {
  final String message;
  final String referenceNumber;

  const SupportSuccess({
    required this.message,
    required this.referenceNumber,
  });

  @override
  List<Object?> get props => [message, referenceNumber];
}

class SupportError extends SupportState {
  final String message;

  const SupportError({required this.message});

  @override
  List<Object?> get props => [message];
}
