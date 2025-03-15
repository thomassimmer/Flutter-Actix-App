import 'package:dartz/dartz.dart';
import 'package:reallystick/core/constants/errors.dart';
import 'package:reallystick/features/auth/data/storage/token_storage.dart';
import 'package:reallystick/features/auth/domain/entities/otp_generation.dart';
import 'package:reallystick/features/auth/domain/errors/failures.dart';
import 'package:reallystick/features/auth/domain/repositories/auth_repository.dart';

class GenerateOtpConfigUseCase {
  final AuthRepository authRepository;

  GenerateOtpConfigUseCase(this.authRepository);

  /// Generates a new OTP's base32 and url for the user.
  Future<Either<GeneratedOtpConfig, Failure>> call() async {
    final accessToken = await TokenStorage().getAccessToken();

    try {
      final otpGenerationModel =
          await authRepository.generateOtpConfig(accessToken: accessToken!);

      return Left(GeneratedOtpConfig(
          otpBase32: otpGenerationModel.otpBase32,
          otpAuthUrl: otpGenerationModel.otpAuthUrl));
    } catch (e) {
      return Right(ServerFailure(message: e.toString()));
    }
  }
}
