import 'package:equatable/equatable.dart';
import 'package:flutteractixapp/features/profile/domain/entities/user.dart';

abstract class ProfileState extends Equatable {
  final Exception? error;

  const ProfileState({this.error});

  @override
  List<Object?> get props => [];
}

class ProfileLoading extends ProfileState {}

class ProfileUnauthenticated extends ProfileState {
  const ProfileUnauthenticated({super.error});

  @override
  List<Object?> get props => [error];
}

class ProfileAuthenticated extends ProfileState {
  final User profile;

  const ProfileAuthenticated({required this.profile, super.error});

  @override
  List<Object?> get props => [profile, error];
}
