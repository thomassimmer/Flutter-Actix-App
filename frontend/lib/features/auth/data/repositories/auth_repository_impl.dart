// features/auth/data/repositories/auth_repository.dart

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:reallystick/features/auth/data/models/user_token_request_model.dart';
import 'package:reallystick/features/auth/data/sources/remote_data_sources.dart';
import 'package:reallystick/features/auth/domain/entities/otp_generation.dart';
import 'package:reallystick/features/auth/domain/entities/user_token.dart';
import 'package:reallystick/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserToken> register(
      {required String username,
      required String password,
      required String locale,
      required String theme}) async {
    final userTokenModel = await remoteDataSource.register(
        RegisterUserRequestModel(
            username: username,
            password: password,
            locale: locale,
            theme: theme));

    return UserToken(
        accessToken: userTokenModel.accessToken,
        refreshToken: userTokenModel.refreshToken,
        expiresIn: userTokenModel.expiresIn);
  }

  @override
  Future<Either<UserToken, String>> login({
    required String username,
    required String password,
  }) async {
    final result = await remoteDataSource
        .login(LoginUserRequestModel(username: username, password: password));

    return result.fold(
        (userTokenModel) => Left(UserToken(
            accessToken: userTokenModel.accessToken,
            refreshToken: userTokenModel.refreshToken,
            expiresIn: userTokenModel.expiresIn)),
        (string) => Right(string));
  }

  @override
  Future<GeneratedOtpConfig> generateOtpConfig(
      {required String accessToken}) async {
    final generatedOtpConfigModel =
        await remoteDataSource.generateOtpConfig(accessToken);

    return GeneratedOtpConfig(
        otpBase32: generatedOtpConfigModel.otpBase32,
        otpAuthUrl: generatedOtpConfigModel.otpAuthUrl);
  }

  @override
  Future<bool> verifyOtp({
    required String accessToken,
    required String code,
  }) async {
    final result =
        await remoteDataSource.verifyOtp(VerifyOtpRequestModel(code: code));
    return result;
  }

  @override
  Future<UserToken> validateOtp({
    required String userId,
    required String code,
  }) async {
    final userTokenModel = await remoteDataSource
        .validateOtp(ValidateOtpRequestModel(userId: userId, code: code));

    return UserToken(
        accessToken: userTokenModel.accessToken,
        refreshToken: userTokenModel.refreshToken,
        expiresIn: userTokenModel.expiresIn);
  }

  @override
  Future<bool> disableOtp({
    required String accessToken,
  }) async {
    final result = await remoteDataSource.disableOtp(accessToken: accessToken);
    return result;
  }
}