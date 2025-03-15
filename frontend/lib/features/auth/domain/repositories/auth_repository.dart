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

  Future<GeneratedOtpConfig> generateOtpConfig({required String accessToken});

  Future<void> verifyOtp({
    required String accessToken,
    required String code,
  });

  Future<UserToken> validateOtp({
    required String userId,
    required String code,
  });

  Future<void> disableOtp({
    required String accessToken,
  });
}
