import 'package:equatable/equatable.dart';
import 'package:flutteractixapp/core/messages/message.dart';

abstract class AuthState extends Equatable {
  final Message? message;

  const AuthState({this.message});

  @override
  List<Object?> get props => [message];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({super.message});

  @override
  List<Object?> get props => [message];
}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({super.message});

  @override
  List<Object?> get props => [message];
}

class AuthAuthenticatedAfterRegistration extends AuthAuthenticated {
  final List<String>? recoveryCodes;
  final bool hasVerifiedOtp;

  AuthAuthenticatedAfterRegistration(
      {super.message, this.recoveryCodes, required this.hasVerifiedOtp});

  @override
  List<Object?> get props => [message, recoveryCodes, hasVerifiedOtp];
}

class AuthAuthenticatedAfterLogin extends AuthAuthenticated {
  final bool hasValidatedOtp;

  AuthAuthenticatedAfterLogin({super.message, required this.hasValidatedOtp});

  @override
  List<Object?> get props => [message, hasValidatedOtp];
}

class AuthOtpGenerate extends AuthAuthenticated {
  final String otpBase32;
  final String otpAuthUrl;

  AuthOtpGenerate({
    super.message,
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
  final String userId;

  const AuthOtpValidate({super.message, required this.userId});

  @override
  List<Object?> get props => [message, userId];
}

class AuthRecoveringAccountUsernameStep extends AuthUnauthenticated {
  final String username;
  final bool passwordForgotten;

  AuthRecoveringAccountUsernameStep(
      {super.message, required this.username, required this.passwordForgotten});

  @override
  List<Object?> get props => [message, username, passwordForgotten];
}

class AuthRecoveringAccountWithOtpDisabled
    extends AuthRecoveringAccountUsernameStep {
  AuthRecoveringAccountWithOtpDisabled(
      {super.message,
      required super.username,
      required super.passwordForgotten});
}

class AuthRecoveringAccountWithOtpEnabledAndUsingPassword
    extends AuthRecoveringAccountUsernameStep {
  AuthRecoveringAccountWithOtpEnabledAndUsingPassword(
      {super.message,
      required super.username,
      required super.passwordForgotten});
}

class AuthRecoveringAccountWithOtpEnabledAndUsingOtp
    extends AuthRecoveringAccountUsernameStep {
  AuthRecoveringAccountWithOtpEnabledAndUsingOtp(
      {super.message,
      required super.username,
      required super.passwordForgotten});
}
