import 'package:equatable/equatable.dart';

sealed class SetPasswordFormEvent extends Equatable {
  const SetPasswordFormEvent();

  @override
  List<Object?> get props => [];
}

class SetPasswordFormPasswordChangedEvent extends SetPasswordFormEvent {
  final String password;

  const SetPasswordFormPasswordChangedEvent(this.password);

  @override
  List<Object?> get props => [password];
}
