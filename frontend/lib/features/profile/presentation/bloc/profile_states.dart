import 'package:equatable/equatable.dart';
import 'package:reallystick/features/profile/domain/entities/user.dart';

abstract class ProfileState extends Equatable {
  final String? message;

  const ProfileState({this.message});

  @override
  List<Object?> get props => [];
}

class ProfileLoading extends ProfileState {}

class ProfileUnauthenticated extends ProfileState {
  const ProfileUnauthenticated({super.message});

  @override
  List<Object?> get props => [message];
}

class ProfileAuthenticated extends ProfileState {
  final User profile;

  const ProfileAuthenticated({required this.profile, super.message});

  @override
  List<Object?> get props => [profile, message];
}
