import 'package:flutteractixapp/features/auth/domain/errors/domain_error.dart';
import 'package:formz/formz.dart';

class Password extends FormzInput<String, Exception> {
  const Password.pure() : super.pure('');

  const Password.dirty([super.value = '']) : super.dirty();

  @override
  Exception? validator(String? value) {
    if (value!.length < 8) {
      return PasswordTooShortError();
    }

    bool hasLetter = value.contains(RegExp(r'[A-Za-z]'));
    bool hasDigit = value.contains(RegExp(r'\d'));
    bool hasSpecial = value.contains(RegExp(r'[@$!%*?&_]'));
    bool validCharacters = value.contains(RegExp(r'^[A-Za-z\d@$!%*?&_]+$'));

    if (hasLetter && hasDigit && hasSpecial && validCharacters) {
      return null;
    }

    return PasswordNotComplexEnoughError();
  }
}
