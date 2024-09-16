import 'package:dartz/dartz.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/features/auth/domain/entities/otp_generation.dart';
import 'package:flutteractixapp/features/auth/domain/repositories/auth_repository.dart';

class GenerateTwoFactorAuthenticationConfigUseCase {
  final AuthRepository authRepository;

  GenerateTwoFactorAuthenticationConfigUseCase(this.authRepository);

  /// Generates a new OTP's base32 and url for the user.
  Future<Either<DomainError, TwoFactorAuthenticationConfig>> call() async {
    return await authRepository.generateTwoFactorAuthenticationConfig();
  }
}
