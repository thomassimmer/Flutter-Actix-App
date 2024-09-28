import 'package:equatable/equatable.dart';
import 'package:flutteractixapp/core/validators/password.dart';

final class UpdatePasswordFormState extends Equatable {
  const UpdatePasswordFormState({
    this.password = const Password.pure(),
    this.isValid = true,
    this.errorMessage,
  });

  final Password password;
  final bool isValid;
  final String? errorMessage;

  @override
  List<Object?> get props => [password, isValid, errorMessage];

  UpdatePasswordFormState copyWith({
    Password? password,
    bool? isValid,
    String? errorMessage,
  }) {
    return UpdatePasswordFormState(
      password: password ?? this.password,
      isValid: isValid ?? this.isValid,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
