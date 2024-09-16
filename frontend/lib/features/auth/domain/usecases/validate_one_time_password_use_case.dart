import 'package:dartz/dartz.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/features/auth/data/storage/token_storage.dart';
import 'package:flutteractixapp/features/auth/domain/entities/user_token.dart';
import 'package:flutteractixapp/features/auth/domain/repositories/auth_repository.dart';

class ValidateOneTimePasswordUseCase {
  final AuthRepository authRepository;

  ValidateOneTimePasswordUseCase(this.authRepository);

  /// Validates the OTP provided by the user. It's for login.
  Future<Either<DomainError, UserToken>> call(
      String userId, String code) async {
    final result = await authRepository.validateOneTimePassword(
        userId: userId, code: code);

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
