import 'package:equatable/equatable.dart';

// Base class for handling failures in the app.
abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object?> get props => [message];
}

// General failure for unexpected errors.
class GeneralFailure extends Failure {
  const GeneralFailure({required String message}) : super(message: message);
}

// Failure for network-related issues.
class NetworkFailure extends Failure {
  const NetworkFailure({required String message}) : super(message: message);
}

// Failure for authentication-related issues, like invalid credentials or OTP failure.
class AuthFailure extends Failure {
  const AuthFailure({required String message}) : super(message: message);
}

// Failure for issues related to data retrieval or storage.
class ServerFailure extends Failure {
  const ServerFailure({required String message}) : super(message: message);
}
