import 'package:dartz/dartz.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/features/auth/domain/entities/user_token.dart';
import 'package:flutteractixapp/features/auth/domain/repositories/auth_repository.dart';

class ValidateOtpUsecase {
  final AuthRepository authRepository;

  ValidateOtpUsecase(this.authRepository);

  /// Validates the OTP provided by the user. It's for login.
  Future<Either<DomainError, UserToken>> call(
      String userId, String code) async {
    return await authRepository.validateOtp(userId: userId, code: code);
  }
}
