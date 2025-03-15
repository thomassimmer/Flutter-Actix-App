import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthSignupRequested extends AuthEvent {
  final String username;
  final String password;

  const AuthSignupRequested({
    required this.username,
    required this.password,
  });

  @override
  List<Object> get props => [username, password];
}

class AuthLoginRequested extends AuthSignupRequested {
  const AuthLoginRequested({
    required super.username,
    required super.password,
  });
}

class AuthOtpGenerationRequested extends AuthEvent {
  final String accessToken;
  final String refreshToken;
  final String expiresIn;

  const AuthOtpGenerationRequested(
      {required this.accessToken,
      required this.refreshToken,
      required this.expiresIn});

  @override
  List<Object> get props => [accessToken, refreshToken, expiresIn];
}

class AuthOtpVerificationRequested extends AuthOtpGenerationRequested {
  final String otpBase32;
  final String otpAuthUrl;
  final String code;

  const AuthOtpVerificationRequested(
      {required super.accessToken,
      required super.refreshToken,
      required super.expiresIn,
      required this.otpBase32,
      required this.otpAuthUrl,
      required this.code});
}

class AuthOtpValidationRequested extends AuthEvent {
  final String userId;
  final String code;

  const AuthOtpValidationRequested({required this.userId, required this.code});

  @override
  List<Object> get props => [userId, code];
}
