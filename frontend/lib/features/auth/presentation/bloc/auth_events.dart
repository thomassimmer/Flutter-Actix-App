import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
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

class AuthOtpGenerationRequested extends AuthEvent {}

class AuthOtpVerificationRequested extends AuthEvent {
  final String otpBase32;
  final String otpAuthUrl;
  final String code;

  const AuthOtpVerificationRequested(
      {required this.otpBase32, required this.otpAuthUrl, required this.code});
}

class AuthOtpValidationRequested extends AuthEvent {
  final String userId;
  final String code;

  const AuthOtpValidationRequested({required this.userId, required this.code});

  @override
  List<Object> get props => [userId, code];
}

class AuthAccountRecoveryForUsernameRequested extends AuthEvent {
  final String username;
  final bool passwordForgotten;

  const AuthAccountRecoveryForUsernameRequested(
      {required this.username, required this.passwordForgotten});

  @override
  List<Object> get props => [username, passwordForgotten];
}

class AuthDoesAccountHaveOtpEnabledRequested extends AuthEvent {
  final String username;
  final bool passwordForgotten;

  const AuthDoesAccountHaveOtpEnabledRequested(
      {required this.username, required this.passwordForgotten});

  @override
  List<Object?> get props => [username, passwordForgotten];
}

class AuthAccountRecoveryWithOtpDisabledRequested extends AuthEvent {
  final String username;
  final String recoveryCode;

  const AuthAccountRecoveryWithOtpDisabledRequested(
      {required this.username, required this.recoveryCode});

  @override
  List<Object?> get props => [username, recoveryCode];
}

class AuthAccountRecoveryWithOtpEnabledAndPasswordRequested extends AuthEvent {
  final String username;
  final String password;
  final String recoveryCode;

  const AuthAccountRecoveryWithOtpEnabledAndPasswordRequested(
      {required this.username,
      required this.password,
      required this.recoveryCode});

  @override
  List<Object?> get props => [username, password, recoveryCode];
}

class AuthAccountRecoveryWithOtpEnabledAndOtpRequested extends AuthEvent {
  final String username;
  final String code;
  final String recoveryCode;

  const AuthAccountRecoveryWithOtpEnabledAndOtpRequested(
      {required this.username, required this.code, required this.recoveryCode});

  @override
  List<Object?> get props => [username, code, recoveryCode];
}
