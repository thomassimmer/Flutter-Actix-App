import 'package:equatable/equatable.dart';
import 'package:flutteractixapp/core/messages/message.dart';
import 'package:flutteractixapp/features/profile/domain/entities/user.dart';

abstract class ProfileState extends Equatable {
  final Message? message;
  final User? profile;

  const ProfileState({this.message, this.profile});

  @override
  List<Object?> get props => [message, profile];
}

class ProfileLoading extends ProfileState {
  const ProfileLoading(
      {super.profile, // Keep profile here to not switch language / theme when loading something
      super.message});

  @override
  List<Object?> get props => [profile, message];
}

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
