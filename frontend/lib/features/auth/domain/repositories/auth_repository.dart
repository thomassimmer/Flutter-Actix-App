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

  Future<Either<DomainError, TwoFactorAuthenticationConfig>>
      generateTwoFactorAuthenticationConfig();

  Future<Either<DomainError, bool>> verifyOneTimePassword({
    required String code,
  });

  Future<Either<DomainError, UserToken>> validateOneTimePassword({
    required String userId,
    required String code,
  });

  Future<Either<DomainError, bool>> disableTwoFactorAuthentication();

  Future<Either<DomainError, bool>>
      checkIfAccountHasTwoFactorAuthenticationEnabled(
          {required String username});

  Future<Either<DomainError, UserToken>>
      recoverAccountWithTwoFactorAuthenticationAndPassword(
          {required String username,
          required String password,
          required String recoveryCode});

  Future<Either<DomainError, UserToken>>
      recoverAccountWithTwoFactorAuthenticationAndOneTimePassword(
          {required String username,
          required String recoveryCode,
          required String code});

  Future<Either<DomainError, UserToken>>
      recoverAccountWithoutTwoFactorAuthenticationEnabled({
    required String username,
    required String recoveryCode,
  });
}
