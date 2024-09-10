import 'package:bloc/bloc.dart';
import 'package:flutteractixapp/features/auth/presentation/cubit/login_models.dart';
import 'package:flutteractixapp/features/auth/presentation/cubit/login_state.dart';
import 'package:formz/formz.dart';

class LoginCubit extends Cubit<LoginState> {
  LoginCubit() : super(const LoginState());

  void usernameChanged(String value) {
    final email = Username.dirty(value);
    emit(
      state.copyWith(
        username: email,
        isValid: Formz.validate([email, state.password]),
      ),
    );
  }

  void passwordChanged(String value) {
    final password = Password.dirty(value);
    emit(
      state.copyWith(
        password: password,
        isValid: Formz.validate([state.username, password]),
      ),
    );
  }
}
