import 'package:dartz/dartz.dart';
import 'package:reallystick/core/constants/errors.dart';
import 'package:reallystick/features/auth/data/storage/token_storage.dart';
import 'package:reallystick/features/auth/domain/errors/failures.dart';
import 'package:reallystick/features/auth/domain/repositories/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository authRepository;

  VerifyOtpUseCase(this.authRepository);

  /// Verifies the OTP provided by the user. It's for enabling 2FA.
  Future<Either<bool, Failure>> verifyOtp(String code) async {
    final accessToken = await TokenStorage().getAccessToken();

    try {
      final otpVerified =
          await authRepository.verifyOtp(accessToken: accessToken!, code: code);

      return Left(otpVerified);
    } catch (e) {
      return Right(ServerFailure(message: e.toString()));
    }
  }
}
