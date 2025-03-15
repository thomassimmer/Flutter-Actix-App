import 'package:equatable/equatable.dart';
import 'package:flutteractixapp/features/profile/domain/entities/user.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {}

class ProfileClearRequested extends ProfileEvent {}

class ProfileUpdateRequested extends ProfileEvent {
  final User profile;

  const ProfileUpdateRequested({
    required this.profile,
  });

  @override
  List<Object> get props => [profile];
}

class ProfileOtpGenerationRequested extends ProfileEvent {}

class ProfileOtpDisablingRequested extends ProfileEvent {}

class ProfileOtpVerificationRequested extends ProfileEvent {
  final String code;

  const ProfileOtpVerificationRequested({
    required this.code,
  });

  @override
  List<Object> get props => [code];
}
