import 'package:equatable/equatable.dart';
import 'package:flutteractixapp/core/validators/password.dart';
import 'package:flutteractixapp/core/validators/username.dart';

final class SignupFormState extends Equatable {
  const SignupFormState({
    this.username = const Username.pure(),
    this.password = const Password.pure(),
    this.isValid = true,
    this.errorMessage,
  });

  final Username username;
  final Password password;
  final bool isValid;
  final String? errorMessage;

  @override
  List<Object?> get props => [username, password, isValid, errorMessage];

  SignupFormState copyWith({
    Username? username,
    Password? password,
    bool? isValid,
    String? errorMessage,
  }) {
    return SignupFormState(
      username: username ?? this.username,
      password: password ?? this.password,
      isValid: isValid ?? this.isValid,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
