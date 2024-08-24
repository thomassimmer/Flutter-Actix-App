import 'package:equatable/equatable.dart';
import 'package:reallystick/features/profile/domain/entities/user_entity.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileLoading extends ProfileState {}

class ProfileUnauthenticated extends ProfileState {
  final String? message;

  const ProfileUnauthenticated({this.message});

  @override
  List<Object?> get props => [message];
}

class ProfileAuthenticated extends ProfileState {
  final UserEntity profile;

  const ProfileAuthenticated({
    required this.profile,
  });

  @override
  List<Object> get props => [profile];
}
