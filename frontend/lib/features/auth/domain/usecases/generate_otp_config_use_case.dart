import 'package:flutteractixapp/features/auth/domain/entities/otp_generation.dart';
import 'package:flutteractixapp/features/auth/domain/repositories/auth_repository.dart';

class GenerateOtpConfigUseCase {
  final AuthRepository authRepository;

  GenerateOtpConfigUseCase(this.authRepository);

  /// Generates a new OTP's base32 and url for the user.
  Future<GeneratedOtpConfig> call() async {
    return await authRepository.generateOtpConfig();
  }
}
