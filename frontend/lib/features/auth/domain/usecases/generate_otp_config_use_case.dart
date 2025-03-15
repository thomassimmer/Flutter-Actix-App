import 'package:reallystick/features/auth/data/storage/token_storage.dart';
import 'package:reallystick/features/auth/domain/entities/otp_generation.dart';
import 'package:reallystick/features/auth/domain/repositories/auth_repository.dart';

class GenerateOtpConfigUseCase {
  final AuthRepository authRepository;

  GenerateOtpConfigUseCase(this.authRepository);

  /// Generates a new OTP's base32 and url for the user.
  Future<GeneratedOtpConfig> call() async {
    final accessToken = await TokenStorage().getAccessToken();
    final otpGenerationModel =
        await authRepository.generateOtpConfig(accessToken: accessToken!);

    return GeneratedOtpConfig(
        otpBase32: otpGenerationModel.otpBase32,
        otpAuthUrl: otpGenerationModel.otpAuthUrl);
  }
}
