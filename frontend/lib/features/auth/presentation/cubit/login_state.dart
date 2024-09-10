import 'package:equatable/equatable.dart';
import 'package:flutteractixapp/features/auth/presentation/cubit/login_models.dart';

final class LoginState extends Equatable {
  const LoginState({
    this.username = const Username.pure(),
    this.password = const Password.pure(),
    this.isValid = false,
    this.errorMessage,
  });

  final Username username;
  final Password password;
  final bool isValid;
  final String? errorMessage;

  @override
  List<Object?> get props => [username, password, isValid, errorMessage];

  LoginState copyWith({
    Username? username,
    Password? password,
    bool? isValid,
    String? errorMessage,
  }) {
    return LoginState(
      username: username ?? this.username,
      password: password ?? this.password,
      isValid: isValid ?? this.isValid,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
