import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class ProfileInitializeEvent extends ProfileEvent {}

class ProfileLogoutEvent extends ProfileEvent {}

class ProfileUpdateThemeEvent extends ProfileEvent {
  final String theme;

  const ProfileUpdateThemeEvent({
    required this.theme,
  });

  @override
  List<Object> get props => [theme];
}

class ProfileUpdateLocaleEvent extends ProfileEvent {
  final String locale;

  const ProfileUpdateLocaleEvent({
    required this.locale,
  });

  @override
  List<Object> get props => [locale];
}

class ProfileGenerateTwoFactorAuthenticationConfigEvent extends ProfileEvent {}

class ProfileDisableTwoFactorAuthenticationEvent extends ProfileEvent {}

class ProfileVerifyOneTimePasswordEvent extends ProfileEvent {
  final String code;

  const ProfileVerifyOneTimePasswordEvent({
    required this.code,
  });

  @override
  List<Object> get props => [code];
}

class ProfileSetPasswordEvent extends ProfileEvent {
  final String newPassword;

  const ProfileSetPasswordEvent({required this.newPassword});

  @override
  List<Object> get props => [newPassword];
}

class ProfileUpdatePasswordEvent extends ProfileEvent {
  final String currentPassword;
  final String newPassword;

  const ProfileUpdatePasswordEvent(
      {required this.currentPassword, required this.newPassword});

  @override
  List<Object> get props => [currentPassword, newPassword];
}
