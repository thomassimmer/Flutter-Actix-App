import 'package:dartz/dartz.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/features/auth/data/storage/token_storage.dart';
import 'package:flutteractixapp/features/auth/domain/entities/user_token.dart';
import 'package:flutteractixapp/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository authRepository;

  LoginUseCase(this.authRepository);

  Future<Either<DomainError, Either<UserToken, String>>> call(
      String username, String password) async {
    final result =
        await authRepository.login(username: username, password: password);

    await result.fold((_) async {}, (userTokenOrUserId) async {
      await userTokenOrUserId.fold((userToken) async {
        // Store tokens securely after successful login
        await TokenStorage().saveTokens(
          userToken.accessToken,
          userToken.refreshToken,
        );
      }, (r) async {});
    });

    return result;
  }
}
