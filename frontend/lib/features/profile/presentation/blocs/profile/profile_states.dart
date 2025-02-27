import 'package:equatable/equatable.dart';
import 'package:flutteractixapp/core/messages/message.dart';
import 'package:flutteractixapp/features/profile/domain/entities/device.dart';
import 'package:flutteractixapp/features/profile/domain/entities/profile.dart';

abstract class ProfileState extends Equatable {
  final Message? message;
  final Profile? profile;

  const ProfileState({
    this.message,
    this.profile,
  });

  @override
  List<Object?> get props => [
        message,
        profile,
      ];
}

class ProfileLoading extends ProfileState {
  const ProfileLoading({
    super.profile, // Keep profile here to not switch language / theme when loading something
    super.message,
  });
}

class ProfileUnauthenticated extends ProfileState {
  const ProfileUnauthenticated({
    super.message,
  });
}

class ProfileAuthenticated extends ProfileState {
  @override
  Profile get profile => super.profile!; // Use '!' to ensure non-nullability

  final List<Device> devices;

  const ProfileAuthenticated({
    required super.profile,
    required this.devices,
    super.message,
  });

  @override
  List<Object?> get props => [
        profile,
        devices,
        message,
      ];
}
