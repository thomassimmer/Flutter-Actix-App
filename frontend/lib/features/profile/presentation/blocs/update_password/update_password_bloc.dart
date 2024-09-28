import 'package:bloc/bloc.dart';
import 'package:flutteractixapp/core/validators/password.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/update_password/update_password_events.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/update_password/update_password_states.dart';
import 'package:formz/formz.dart';

class ProfileUpdatePasswordFormBloc
    extends Bloc<UpdatePasswordFormEvent, UpdatePasswordFormState> {
  ProfileUpdatePasswordFormBloc() : super(const UpdatePasswordFormState()) {
    on<UpdatePasswordFormPasswordChangedEvent>(_passwordChanged);
  }

  Future<void> _passwordChanged(
      UpdatePasswordFormPasswordChangedEvent event, Emitter emit) async {
    final password = Password.dirty(event.password);

    emit(
      state.copyWith(
        password: password,
        isValid: Formz.validate([password]),
      ),
    );
  }
}
