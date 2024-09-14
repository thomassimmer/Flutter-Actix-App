import 'package:dartz/dartz.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/features/auth/domain/entities/otp_generation.dart';
import 'package:flutteractixapp/features/auth/domain/entities/user_token.dart';

abstract class AuthRepository {
  Future<Either<DomainError, UserToken>> signup(
      {required String username,
      required String password,
      required String locale,
      required String theme});

  Future<Either<DomainError, Either<UserToken, String>>> login({
    required String username,
    required String password,
  });

  Future<Either<DomainError, GeneratedOtpConfig>> generateOtpConfig();

  Future<Either<DomainError, bool>> verifyOtp({
    required String code,
  });

  Future<Either<DomainError, UserToken>> validateOtp({
    required String userId,
    required String code,
  });

  Future<Either<DomainError, bool>> disableOtp();

  Future<Either<DomainError, bool>> checkIfOtpEnabled(
      {required String username});

  Future<Either<DomainError, UserToken>>
      recoverAccountWithRecoveryCodeAndPassword(
          {required String username,
          required String password,
          required String recoveryCode});

  Future<Either<DomainError, UserToken>> recoverAccountWithRecoveryCodeAndOtp(
      {required String username,
      required String recoveryCode,
      required String code});

  Future<Either<DomainError, UserToken>> recoverAccountWithRecoveryCode({
    required String username,
    required String recoveryCode,
  });
}
