import 'package:equatable/equatable.dart';

sealed class UpdatePasswordFormEvent extends Equatable {
  const UpdatePasswordFormEvent();

  @override
  List<Object?> get props => [];
}

class UpdatePasswordFormPasswordChangedEvent extends UpdatePasswordFormEvent {
  final String password;

  const UpdatePasswordFormPasswordChangedEvent(this.password);

  @override
  List<Object?> get props => [password];
}
