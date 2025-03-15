import 'package:dartz/dartz.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/features/auth/domain/repositories/auth_repository.dart';

class DisableOtpUseCase {
  final AuthRepository authRepository;

  DisableOtpUseCase(this.authRepository);

  /// Disable OTP authentication for the user.
  Future<Either<DomainError, bool>> call() async {
    return await authRepository.disableOtp();
  }
}
