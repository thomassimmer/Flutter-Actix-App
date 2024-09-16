import 'package:dartz/dartz.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/features/auth/data/storage/token_storage.dart';
import 'package:flutteractixapp/features/auth/domain/entities/user_token.dart';
import 'package:flutteractixapp/features/auth/domain/repositories/auth_repository.dart';

class SignupUseCase {
  final AuthRepository authRepository;

  SignupUseCase(this.authRepository);

  Future<Either<DomainError, UserToken>> call(
      String username, String password, String locale, String theme) async {
    final result = await authRepository.signup(
        username: username, password: password, locale: locale, theme: theme);

    await result.fold((_) async {}, (userToken) async {
      // Store tokens securely after successful login
      await TokenStorage().saveTokens(
        userToken.accessToken,
        userToken.refreshToken,
      );
    });

    return result;
  }
}
