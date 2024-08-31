// domain/errors/domain_error.dart
import 'package:flutteractixapp/core/errors/domain_error.dart';

class UnauthorizedDomainError extends DomainError {
  UnauthorizedDomainError([String message = 'You are not authenticated'])
      : super();

  @override
  List<Object?> get props => [message];
}

class InvalidRegisterDomainError extends DomainError {
  InvalidRegisterDomainError([String message = 'The register data is invalid.'])
      : super();

  @override
  List<Object?> get props => [message];
}

class InvalidLoginDomainError extends DomainError {
  InvalidLoginDomainError([String message = 'The login data is invalid.'])
      : super();

  @override
  List<Object?> get props => [message];
}

class InvalidOtpGenerationDomainError extends DomainError {
  InvalidOtpGenerationDomainError(
      [String message = 'The otp generation data is invalid.'])
      : super();

  @override
  List<Object?> get props => [message];
}

class InvalidOtpVerificationDomainError extends DomainError {
  InvalidOtpVerificationDomainError(
      [String message = 'The otp verification data is invalid.'])
      : super();

  @override
  List<Object?> get props => [message];
}

class InvalidOtpValidationDomainError extends DomainError {
  InvalidOtpValidationDomainError(
      [String message = 'The otp validation data is invalid.'])
      : super();

  @override
  List<Object?> get props => [message];
}

class InvalidOtpDisablingDomainError extends DomainError {
  InvalidOtpDisablingDomainError(
      [String message = 'The otp disabling data is invalid.'])
      : super();

  @override
  List<Object?> get props => [message];
}
