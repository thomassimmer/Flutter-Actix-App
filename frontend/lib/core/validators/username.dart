import 'package:flutteractixapp/features/auth/domain/errors/domain_error.dart';
import 'package:formz/formz.dart';

class Username extends FormzInput<String, Exception> {
  const Username.pure() : super.pure('');

  const Username.dirty([super.value = '']) : super.dirty();

  @override
  Exception? validator(String? value) {
    final RegExp pattern = RegExp(r'^[a-zA-Z0-9]([._-]?[a-zA-Z0-9]+)*$');
    // Length check (example: min 3, max 20)
    if (value!.length < 3 || value.length > 20) {
      return UsernameWrongSizeError();
    }
    // Regex pattern check
    if (pattern.hasMatch(value)) {
      return null;
    }

    return UsernameNotRespectingRulesError();
  }
}
