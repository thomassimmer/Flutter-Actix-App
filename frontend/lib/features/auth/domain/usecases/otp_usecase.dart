import 'package:dartz/dartz.dart';
import 'package:reallystick/features/auth/domain/entities/otp_generation_entity.dart';
import 'package:reallystick/features/auth/domain/entities/user_token_entity.dart';
import 'package:reallystick/features/auth/domain/errors/failures.dart';

import '../../data/repositories/auth_repository.dart';

class OtpUseCase {
  final AuthRepository authRepository;

  OtpUseCase(this.authRepository);

  /// Verifies the OTP provided by the user. It's for enabling 2FA.
  Future<Either<bool, Failure>> verifyOtp(
      String accessToken, String code) async {
    try {
      final otp_verified =
          await authRepository.verifyOtp(accessToken: accessToken, code: code);

      return Left(otp_verified);
    } catch (e) {
      return Right(ServerFailure(message: e.toString()));
    }
  }

  /// Validates the OTP provided by the user. It's for login.
  Future<Either<UserTokenEntity, Failure>> validateOtp(
      String userId, String code) async {
    try {
      final userTokenModel =
          await authRepository.validateOtp(userId: userId, code: code);

      return Left(UserTokenEntity(
          accessToken: userTokenModel.accessToken,
          refreshToken: userTokenModel.refreshToken,
          expiresIn: userTokenModel.expiresIn,
          recoveryCodes: userTokenModel.recoveryCodes));
    } catch (e) {
      return Right(ServerFailure(message: e.toString()));
    }
  }

  /// Generates a new OTP's base32 and url for the user.
  Future<Either<OtpGenerationEntity, Failure>> generateOtp(
      String accessToken) async {
    try {
      final otpGenerationModel =
          await authRepository.generateOtp(accessToken: accessToken);

      return Left(OtpGenerationEntity(
          otpBase32: otpGenerationModel.otpBase32,
          otpAuthUrl: otpGenerationModel.otpAuthUrl));
    } catch (e) {
      return Right(ServerFailure(message: e.toString()));
    }
  }

  /// Disable OTP authentication for the user.
  Future<Either<bool, Failure>> disableOtp(String accessToken) async {
    try {
      final result = await authRepository.disableOtp(accessToken: accessToken);

      return Left(result);
    } catch (e) {
      return Right(ServerFailure(message: e.toString()));
    }
  }
}
