import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthUnauthenticated extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {}

class AuthAuthenticatedAfterRegistration extends AuthAuthenticated {
  final List<String>? recoveryCodes;
  final bool hasVerifiedOtp;

  AuthAuthenticatedAfterRegistration(
      {this.recoveryCodes, required this.hasVerifiedOtp});

  @override
  List<Object?> get props => [recoveryCodes, hasVerifiedOtp];
}

class AuthAuthenticatedAfterLogin extends AuthAuthenticated {
  final bool hasValidatedOtp;

  AuthAuthenticatedAfterLogin({required this.hasValidatedOtp});

  @override
  List<Object?> get props => [hasValidatedOtp];
}

class AuthFailure extends AuthState {
  final String? message;

  const AuthFailure({this.message});

  @override
  List<Object?> get props => [message];
}

class AuthOtpGenerate extends AuthAuthenticated {
  final String? message;
  final String otpBase32;
  final String otpAuthUrl;

  AuthOtpGenerate({
    this.message,
    required this.otpBase32,
    required this.otpAuthUrl,
  });

  @override
  List<Object?> get props => [message, otpBase32, otpAuthUrl];
}

class AuthOtpVerify extends AuthOtpGenerate {
  AuthOtpVerify(
      {super.message, required super.otpBase32, required super.otpAuthUrl});
}

class AuthOtpValidate extends AuthState {
  final String? message;
  final String userId;

  const AuthOtpValidate({this.message, required this.userId});

  @override
  List<Object?> get props => [message, userId];
}
