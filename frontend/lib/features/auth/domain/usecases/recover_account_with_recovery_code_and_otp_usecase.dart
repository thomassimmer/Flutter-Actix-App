import 'package:dartz/dartz.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/features/auth/domain/entities/user_token.dart';
import 'package:flutteractixapp/features/auth/domain/repositories/auth_repository.dart';

class RecoverAccountWithRecoveryCodeAndOtpUseCase {
  final AuthRepository authRepository;

  RecoverAccountWithRecoveryCodeAndOtpUseCase(this.authRepository);

  Future<Either<DomainError, UserToken>> call(
      {required String username,
      required String recoveryCode,
      required String code}) async {
    return await authRepository.recoverAccountWithRecoveryCodeAndOtp(
        username: username, recoveryCode: recoveryCode, code: code);
  }
}
