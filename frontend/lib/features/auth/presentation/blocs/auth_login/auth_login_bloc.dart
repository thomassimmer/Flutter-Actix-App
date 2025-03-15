import 'package:bloc/bloc.dart';
import 'package:flutteractixapp/core/validators/password.dart';
import 'package:flutteractixapp/core/validators/username.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth_login/auth_login_events.dart';
import 'package:flutteractixapp/features/auth/presentation/blocs/auth_login/auth_login_states.dart';
import 'package:formz/formz.dart';

class AuthSignupFormBloc extends Bloc<SignupFormEvent, SignupFormState> {
  AuthSignupFormBloc() : super(const SignupFormState()) {
    on<SignupFormUsernameChangedEvent>(_usernameChanged);
    on<SignupFormPasswordChangedEvent>(_passwordChanged);
  }

  Future<void> _usernameChanged(
      SignupFormUsernameChangedEvent event, Emitter emit) async {
    final username = Username.dirty(event.username);

    emit(
      state.copyWith(
        username: username,
        isValid: Formz.validate([username, state.password]),
      ),
    );
  }

  Future<void> _passwordChanged(
      SignupFormPasswordChangedEvent event, Emitter emit) async {
    final password = Password.dirty(event.password);

    emit(
      state.copyWith(
        password: password,
        isValid: Formz.validate([state.username, password]),
      ),
    );
  }
}
