import 'package:flutteractixapp/features/auth/domain/repositories/auth_repository.dart';

class DisableOtpUseCase {
  final AuthRepository authRepository;

  DisableOtpUseCase(this.authRepository);

  /// Disable OTP authentication for the user.
  Future<void> call() async {
    await authRepository.disableOtp();
  }
}
