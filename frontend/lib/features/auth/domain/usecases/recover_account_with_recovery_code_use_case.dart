import 'package:dartz/dartz.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/features/auth/domain/entities/user_token.dart';
import 'package:flutteractixapp/features/auth/domain/repositories/auth_repository.dart';

class RecoverAccountWithRecoveryCodeUseCase {
  final AuthRepository authRepository;

  RecoverAccountWithRecoveryCodeUseCase(this.authRepository);

  Future<Either<DomainError, UserToken>> call(
      {required String username, required String recoveryCode}) async {
    return await authRepository.recoverAccountWithRecoveryCode(
      username: username,
      recoveryCode: recoveryCode,
    );
  }
}
