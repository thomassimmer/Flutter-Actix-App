import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  final Exception? error;

  const AuthState({this.error});

  @override
  List<Object?> get props => [error];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({super.error});

  @override
  List<Object?> get props => [error];
}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({super.error});

  @override
  List<Object?> get props => [error];
}

class AuthAuthenticatedAfterRegistration extends AuthAuthenticated {
  final List<String>? recoveryCodes;
  final bool hasVerifiedOtp;

  AuthAuthenticatedAfterRegistration(
      {super.error, this.recoveryCodes, required this.hasVerifiedOtp});

  @override
  List<Object?> get props => [error, recoveryCodes, hasVerifiedOtp];
}

class AuthAuthenticatedAfterLogin extends AuthAuthenticated {
  final bool hasValidatedOtp;

  AuthAuthenticatedAfterLogin({super.error, required this.hasValidatedOtp});

  @override
  List<Object?> get props => [error, hasValidatedOtp];
}

class AuthOtpGenerate extends AuthAuthenticated {
  final String otpBase32;
  final String otpAuthUrl;

  AuthOtpGenerate({
    super.error,
    required this.otpBase32,
    required this.otpAuthUrl,
  });

  @override
  List<Object?> get props => [error, otpBase32, otpAuthUrl];
}

class AuthOtpVerify extends AuthOtpGenerate {
  AuthOtpVerify(
      {super.error, required super.otpBase32, required super.otpAuthUrl});
}

class AuthOtpValidate extends AuthState {
  final String userId;

  const AuthOtpValidate({super.error, required this.userId});

  @override
  List<Object?> get props => [error, userId];
}

class AuthRecoveringAccountUsernameStep extends AuthUnauthenticated {
  final String username;
  final bool passwordForgotten;

  AuthRecoveringAccountUsernameStep(
      {super.error, required this.username, required this.passwordForgotten});

  @override
  List<Object?> get props => [error, username, passwordForgotten];
}

class AuthRecoveringAccountWithOtpDisabled
    extends AuthRecoveringAccountUsernameStep {
  AuthRecoveringAccountWithOtpDisabled(
      {super.error, required super.username, required super.passwordForgotten});
}

class AuthRecoveringAccountWithOtpEnabledAndUsingPassword
    extends AuthRecoveringAccountUsernameStep {
  AuthRecoveringAccountWithOtpEnabledAndUsingPassword(
      {super.error, required super.username, required super.passwordForgotten});
}

class AuthRecoveringAccountWithOtpEnabledAndUsingOtp
    extends AuthRecoveringAccountUsernameStep {
  AuthRecoveringAccountWithOtpEnabledAndUsingOtp(
      {super.error, required super.username, required super.passwordForgotten});
}
