import 'package:equatable/equatable.dart';
import 'package:flutteractixapp/core/errors/domain_error.dart';
import 'package:flutteractixapp/features/profile/domain/entities/user.dart';

abstract class ProfileState extends Equatable {
  final DomainError? error;
  final User? profile;

  const ProfileState({this.error, this.profile});

  @override
  List<Object?> get props => [error, profile];
}

class ProfileLoading extends ProfileState {
  const ProfileLoading(
      {super.profile, // Keep profile here to not switch language / theme when loading something
      super.error});

  @override
  List<Object?> get props => [profile, error];
}

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
