import 'package:equatable/equatable.dart';
import 'package:flutteractixapp/core/messages/message.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthInitializeEvent extends AuthEvent {}

class AuthLogoutEvent extends AuthEvent {
  final Message? message;

  const AuthLogoutEvent({this.message});

  @override
  List<Object?> get props => [message];
}

class AuthSignupEvent extends AuthEvent {
  final String username;
  final String password;
  final String theme;

  const AuthSignupEvent(
      {required this.username, required this.password, required this.theme});

  @override
  List<Object> get props => [username, password, theme];
}

class AuthLoginEvent extends AuthEvent {
  final String username;
  final String password;

  const AuthLoginEvent({
    required this.username,
    required this.password,
  });

  @override
  List<Object> get props => [username, password];
}

class AuthGenerateTwoFactorAuthenticationConfigEvent extends AuthEvent {}

class AuthVerifyOneTimePasswordEvent extends AuthEvent {
  final String otpBase32;
  final String otpAuthUrl;
  final String code;

  const AuthVerifyOneTimePasswordEvent(
      {required this.otpBase32, required this.otpAuthUrl, required this.code});
}

class AuthValidateOneTimePasswordEvent extends AuthEvent {
  final String userId;
  final String code;

  const AuthValidateOneTimePasswordEvent(
      {required this.userId, required this.code});

  @override
  List<Object> get props => [userId, code];
}

class AuthRecoverAccountForUsernameEvent extends AuthEvent {
  final String username;
  final bool passwordForgotten;

  const AuthRecoverAccountForUsernameEvent(
      {required this.username, required this.passwordForgotten});

  @override
  List<Object> get props => [username, passwordForgotten];
}

class AuthCheckIfAccountHasTwoFactorAuthenticationEnabledEvent
    extends AuthEvent {
  final String username;
  final bool passwordForgotten;

  const AuthCheckIfAccountHasTwoFactorAuthenticationEnabledEvent(
      {required this.username, required this.passwordForgotten});

  @override
  List<Object?> get props => [username, passwordForgotten];
}

class AuthRecoverAccountWithoutTwoFactorAuthenticationEnabledEvent
    extends AuthEvent {
  final String username;
  final String recoveryCode;

  const AuthRecoverAccountWithoutTwoFactorAuthenticationEnabledEvent(
      {required this.username, required this.recoveryCode});

  @override
  List<Object?> get props => [username, recoveryCode];
}

class AuthRecoverAccountWithTwoFactorAuthenticationAndPasswordEvent
    extends AuthEvent {
  final String username;
  final String password;
  final String recoveryCode;

  const AuthRecoverAccountWithTwoFactorAuthenticationAndPasswordEvent(
      {required this.username,
      required this.password,
      required this.recoveryCode});

  @override
  List<Object?> get props => [username, password, recoveryCode];
}

class AuthRecoverAccountWithTwoFactorAuthenticationAndOneTimePasswordEvent
    extends AuthEvent {
  final String username;
  final String code;
  final String recoveryCode;

  const AuthRecoverAccountWithTwoFactorAuthenticationAndOneTimePasswordEvent(
      {required this.username, required this.code, required this.recoveryCode});

  @override
  List<Object?> get props => [username, code, recoveryCode];
}
