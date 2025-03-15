import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {}

class ProfileClearRequested extends ProfileEvent {}
