import 'package:equatable/equatable.dart';
import 'package:reallystick/features/profile/domain/entities/user_entity.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {}

class ProfileClearRequested extends ProfileEvent {}

class ProfileUpdateRequested extends ProfileEvent {
  final UserEntity profile;

  const ProfileUpdateRequested({
    required this.profile,
  });

  @override
  List<Object> get props => [profile];
}
