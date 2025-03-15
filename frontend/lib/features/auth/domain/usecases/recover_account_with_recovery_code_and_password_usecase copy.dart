import 'package:dartz/dartz.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/features/auth/domain/entities/user_token.dart';
import 'package:flutteractixapp/features/auth/domain/repositories/auth_repository.dart';

class RecoverAccountWithRecoveryCodeAndPasswordUseCase {
  final AuthRepository authRepository;

  RecoverAccountWithRecoveryCodeAndPasswordUseCase(this.authRepository);

  Future<Either<DomainError, UserToken>> call(
      {required String username,
      required String recoveryCode,
      required String password}) async {
    return await authRepository.recoverAccountWithRecoveryCodeAndPassword(
        username: username, recoveryCode: recoveryCode, password: password);
  }
}
