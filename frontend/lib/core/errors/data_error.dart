import 'package:equatable/equatable.dart';

// Base class for handling failures in the app.
abstract class DataError extends Equatable implements Exception {
  final String message;

  DataError({this.message = "An error occurred. Please try again."});

  @override
  String toString() => message;
}

class NetworkError extends DataError {
  NetworkError([String message = 'Failed to connect to the server.']) : super();

  @override
  List<Object?> get props => [message];
}

class ParsingError extends DataError {
  ParsingError([String message = 'Failed to parse response data.']) : super();

  @override
  List<Object?> get props => [message];
}

class SerializingError extends DataError {
  SerializingError([String message = 'Failed to serializer request data.'])
      : super();

  @override
  List<Object?> get props => [message];
}

class UnknownError extends DataError {
  UnknownError([String message = 'An unexpected error occurred.']) : super();

  @override
  List<Object?> get props => [message];
}
