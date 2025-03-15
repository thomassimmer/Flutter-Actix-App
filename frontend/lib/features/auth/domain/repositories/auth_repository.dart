import 'package:dartz/dartz.dart';
import 'package:flutteractixapp/features/auth/domain/entities/otp_generation.dart';
import 'package:flutteractixapp/features/auth/domain/entities/user_token.dart';

abstract class AuthRepository {
  Future<UserToken> register(
      {required String username,
      required String password,
      required String locale,
      required String theme});

  Future<Either<UserToken, String>> login({
    required String username,
    required String password,
  });

  Future<GeneratedOtpConfig> generateOtpConfig();

  Future<void> verifyOtp({
    required String code,
  });

  Future<UserToken> validateOtp({
    required String userId,
    required String code,
  });

  Future<void> disableOtp();

  Future<bool> checkIfOtpEnabled({required String username});

  Future<UserToken> recoverAccountWithRecoveryCodeAndPassword(
      {required String username,
      required String password,
      required String recoveryCode});

  Future<UserToken> recoverAccountWithRecoveryCodeAndOtp(
      {required String username,
      required String recoveryCode,
      required String code});

  Future<UserToken> recoverAccountWithRecoveryCode({
    required String username,
    required String recoveryCode,
  });
}
