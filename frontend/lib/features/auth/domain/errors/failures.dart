// General failure for unexpected errors.
import 'package:reallystick/core/constants/errors.dart';

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

// Failure class specific to storage issues
class StorageFailure extends Failure {
  const StorageFailure({required String message}) : super(message: message);
}
