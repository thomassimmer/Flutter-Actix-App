import 'package:reallystick/features/auth/data/storage/token_storage.dart';
import 'package:reallystick/features/auth/domain/repositories/auth_repository.dart';

class DisableOtpUseCase {
  final AuthRepository authRepository;

  DisableOtpUseCase(this.authRepository);

  /// Disable OTP authentication for the user.
  Future<void> call() async {
    final accessToken = await TokenStorage().getAccessToken();
    await authRepository.disableOtp(accessToken: accessToken!);
  }
}
