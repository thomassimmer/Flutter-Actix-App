import 'package:formz/formz.dart';

class PasswordTooShortError implements Exception {}

class PasswordNotComplexEnough implements Exception {}

class Password extends FormzInput<String, Exception> {
  const Password.pure() : super.pure('');

  const Password.dirty([super.value = '']) : super.dirty();

  @override
  Exception? validator(String? value) {
    if (value!.length < 8) {
      return PasswordTooShortError();
    } else if (!RegExp(
            r'(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]')
        .hasMatch(value)) {
      return PasswordNotComplexEnough();
    }
    return null;
  }
}

enum UsernameValidationError { invalid }

class Username extends FormzInput<String, UsernameValidationError> {
  const Username.pure() : super.pure('');

  const Username.dirty([super.value = '']) : super.dirty();

  @override
  UsernameValidationError? validator(String? value) {
    // TODO
    return null;
  }
}
