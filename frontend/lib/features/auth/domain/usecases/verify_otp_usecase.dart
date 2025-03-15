import 'package:dartz/dartz.dart';
import 'package:reallystick/features/auth/domain/entities/otp_entity.dart';
import 'package:reallystick/features/auth/domain/entities/user_entity.dart';
import 'package:reallystick/features/auth/domain/errors/failures.dart';

import '../../data/repositories/auth_repository.dart';

class VerifyOTPUseCase {
  final AuthRepository authRepository;

  VerifyOTPUseCase(this.authRepository);

  /// Verifies the OTP provided by the user.
  Future<Either<Failure, UserEntity>> verifyOTP(
      String userId, String otp) async {
    try {
      final userModel = await authRepository.verifyOtp(userId: userId, token: otp);

      return Right(UserEntity(
        id: userModel.id,
        username: userModel.username,
        otpEnabled: userModel.otpEnabled,
        otpVerified: userModel.otpVerified,
        otpBase32: userModel.otpBase32,
        otpAuthUrl: userModel.otpAuthUrl,
        createdAt: userModel.createdAt,
        updatedAt: userModel.updatedAt,
      ));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Generates a new OTP for the user.
  Future<Either<Failure, OtpEntity>> generateOTP(
      String userId, String username) async {
    try {
      final result =
          await authRepository.generateOtp(userId: userId, username: username);

      return Right(OtpEntity(
          otpAuthUrl: result.otpAuthUrl, otpBase32: result.otpBase32));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
