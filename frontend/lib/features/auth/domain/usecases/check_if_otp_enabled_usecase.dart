import 'package:flutteractixapp/features/auth/domain/repositories/auth_repository.dart';

class CheckIfOtpEnabledUsecase {
  final AuthRepository authRepository;

  CheckIfOtpEnabledUsecase(this.authRepository);

  /// Verifies the OTP provided by the user. It's for enabling 2FA.
  Future<bool> call(String username) async {
    return await authRepository.checkIfOtpEnabled(username: username);
  }
}
