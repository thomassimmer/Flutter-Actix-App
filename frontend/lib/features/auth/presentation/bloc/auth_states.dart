import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthUnauthenticated extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String accessToken;
  final String refreshToken;
  final String expiresIn;

  const AuthAuthenticated({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  @override
  List<Object?> get props => [
        accessToken,
        refreshToken,
        expiresIn,
      ];
}

class AuthAuthenticatedAfterRegistration extends AuthAuthenticated {
  final String? recoveryCodes;
  final bool hasVerifiedOtp;

  const AuthAuthenticatedAfterRegistration(
      {required super.accessToken,
      required super.refreshToken,
      required super.expiresIn,
      this.recoveryCodes,
      required this.hasVerifiedOtp});

  @override
  List<Object?> get props =>
      [accessToken, refreshToken, expiresIn, recoveryCodes, hasVerifiedOtp];
}

class AuthAuthenticatedAfterLogin extends AuthAuthenticated {
  final bool hasValidatedOtp;

  const AuthAuthenticatedAfterLogin(
      {required super.accessToken,
      required super.refreshToken,
      required super.expiresIn,
      required this.hasValidatedOtp});

  @override
  List<Object?> get props => [
        accessToken,
        refreshToken,
        expiresIn,
        hasValidatedOtp,
      ];
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

  const AuthOtpGenerate({
    required super.accessToken,
    required super.refreshToken,
    required super.expiresIn,
    this.message,
    required this.otpBase32,
    required this.otpAuthUrl,
  });

  @override
  List<Object?> get props =>
      [accessToken, refreshToken, expiresIn, message, otpBase32, otpAuthUrl];
}

class AuthOtpVerify extends AuthOtpGenerate {
  const AuthOtpVerify(
      {required super.accessToken,
      required super.refreshToken,
      required super.expiresIn,
      super.message,
      required super.otpBase32,
      required super.otpAuthUrl});
}

class AuthOtpValidate extends AuthState {
  final String? message;
  final String userId;

  const AuthOtpValidate({this.message, required this.userId});

  @override
  List<Object?> get props => [message, userId];
}
