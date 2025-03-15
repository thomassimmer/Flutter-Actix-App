import 'package:equatable/equatable.dart';

// Base class for handling failures in the app.
abstract class DomainError extends Equatable implements Exception {
  final String message;

  DomainError({this.message = "An error occurred. Please try again."});

  @override
  String toString() => message;
}

class NetworkDomainError extends DomainError {
  NetworkDomainError(
      [String message =
          'A network error occurred while fetching data. Please try again.'])
      : super();

  @override
  List<Object?> get props => [message];
}

class UnknownDomainError extends DomainError {
  UnknownDomainError(
      [String message =
          'An unexpected domain error occurred. Please try again.'])
      : super();

  @override
  List<Object?> get props => [message];
}
