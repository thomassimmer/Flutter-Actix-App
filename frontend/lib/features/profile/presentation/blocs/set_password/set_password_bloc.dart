import 'package:bloc/bloc.dart';
import 'package:flutteractixapp/core/validators/password.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/set_password/set_password_events.dart';
import 'package:flutteractixapp/features/profile/presentation/blocs/set_password/set_password_states.dart';
import 'package:formz/formz.dart';

class ProfileSetPasswordFormBloc
    extends Bloc<SetPasswordFormEvent, SetPasswordFormState> {
  ProfileSetPasswordFormBloc() : super(const SetPasswordFormState()) {
    on<SetPasswordFormPasswordChangedEvent>(_passwordChanged);
  }

  Future<void> _passwordChanged(
      SetPasswordFormPasswordChangedEvent event, Emitter emit) async {
    final password = Password.dirty(event.password);

    emit(
      state.copyWith(
        password: password,
        isValid: Formz.validate([password]),
      ),
    );
  }
}
