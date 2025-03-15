import 'package:dartz/dartz.dart';
import 'package:reallystick/core/constants/errors.dart';
import 'package:reallystick/features/auth/data/storage/token_storage.dart';
import 'package:reallystick/features/auth/domain/errors/failures.dart';
import 'package:reallystick/features/auth/domain/repositories/auth_repository.dart';

class DisableOtpUseCase {
  final AuthRepository authRepository;

  DisableOtpUseCase(this.authRepository);

  /// Disable OTP authentication for the user.
  Future<Either<bool, Failure>> disableOtp() async {
    final accessToken = await TokenStorage().getAccessToken();

    try {
      final result = await authRepository.disableOtp(accessToken: accessToken!);

      return Left(result);
    } catch (e) {
      return Right(ServerFailure(message: e.toString()));
    }
  }
}
