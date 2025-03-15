import 'package:equatable/equatable.dart';

sealed class SignupFormEvent extends Equatable {
  const SignupFormEvent();

  @override
  List<Object?> get props => [];
}

class SignupFormUsernameChangedEvent extends SignupFormEvent {
  final String username;

  const SignupFormUsernameChangedEvent(this.username);

  @override
  List<Object?> get props => [username];
}

class SignupFormPasswordChangedEvent extends SignupFormEvent {
  final String password;

  const SignupFormPasswordChangedEvent(this.password);

  @override
  List<Object?> get props => [password];
}
