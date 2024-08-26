import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthInitRequested extends AuthEvent {}

class AuthLogoutRequested extends AuthEvent {}

class AuthSignupRequested extends AuthEvent {
  final String username;
  final String password;
  final String theme;

  const AuthSignupRequested(
      {required this.username, required this.password, required this.theme});

  @override
  List<Object> get props => [username, password, theme];
}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;

  const AuthLoginRequested({
    required this.username,
    required this.password,
  });

  @override
  List<Object> get props => [username, password];
}

class AuthOtpGenerationRequested extends AuthEvent {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const AuthOtpGenerationRequested(
      {required this.accessToken,
      required this.refreshToken,
      required this.expiresIn});

  @override
  List<Object> get props => [accessToken, refreshToken, expiresIn];
}

class AuthOtpVerificationRequested extends AuthEvent {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String otpBase32;
  final String otpAuthUrl;
  final String code;

  const AuthOtpVerificationRequested(
      {required this.accessToken,
      required this.refreshToken,
      required this.expiresIn,
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
