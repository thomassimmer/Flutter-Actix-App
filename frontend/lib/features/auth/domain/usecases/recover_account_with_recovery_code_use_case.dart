import 'package:flutteractixapp/features/auth/domain/entities/user_token.dart';
import 'package:flutteractixapp/features/auth/domain/repositories/auth_repository.dart';

class RecoverAccountWithRecoveryCodeUseCase {
  final AuthRepository authRepository;

  RecoverAccountWithRecoveryCodeUseCase(this.authRepository);

  Future<UserToken> call(
      {required String username, required String recoveryCode}) async {
    return await authRepository.recoverAccountWithRecoveryCode(
      username: username,
      recoveryCode: recoveryCode,
    );
  }
}
