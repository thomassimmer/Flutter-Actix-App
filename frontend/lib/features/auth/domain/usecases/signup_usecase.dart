import 'package:dartz/dartz.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/features/auth/domain/entities/user_token.dart';
import 'package:flutteractixapp/features/auth/domain/repositories/auth_repository.dart';

class SignupUseCase {
  final AuthRepository authRepository;

  SignupUseCase(this.authRepository);

  Future<Either<DomainError, UserToken>> call(
      String username, String password, String locale, String theme) async {
    return await authRepository.signup(
        username: username, password: password, locale: locale, theme: theme);
  }
}
