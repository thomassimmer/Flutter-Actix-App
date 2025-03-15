import 'package:dartz/dartz.dart';
import 'package:reallystick/core/constants/errors.dart';
import 'package:reallystick/features/auth/domain/entities/user_token.dart';
import 'package:reallystick/features/auth/domain/errors/failures.dart';
import 'package:reallystick/features/auth/domain/repositories/auth_repository.dart';

class ValidateOtpUsecase {
  final AuthRepository authRepository;

  ValidateOtpUsecase(this.authRepository);

  /// Validates the OTP provided by the user. It's for login.
  Future<Either<UserToken, Failure>> call(
      String userId, String code) async {
    try {
      final userTokenModel =
          await authRepository.validateOtp(userId: userId, code: code);

      return Left(UserToken(
          accessToken: userTokenModel.accessToken,
          refreshToken: userTokenModel.refreshToken,
          expiresIn: userTokenModel.expiresIn,
          recoveryCodes: userTokenModel.recoveryCodes));
    } catch (e) {
      return Right(ServerFailure(message: e.toString()));
    }
  }
}
