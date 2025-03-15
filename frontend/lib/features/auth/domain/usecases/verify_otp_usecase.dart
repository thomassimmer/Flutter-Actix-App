import 'package:flutteractixapp/features/auth/data/storage/token_storage.dart';
import 'package:flutteractixapp/features/auth/domain/repositories/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository authRepository;

  VerifyOtpUseCase(this.authRepository);

  /// Verifies the OTP provided by the user. It's for enabling 2FA.
  Future<void> call(String code) async {
    final accessToken = await TokenStorage().getAccessToken();
    await authRepository.verifyOtp(accessToken: accessToken!, code: code);
  }
}
