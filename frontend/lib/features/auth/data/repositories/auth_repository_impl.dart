// features/auth/data/repositories/auth_repository.dart

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutteractixapp/core/errors/data_error.dart';
import 'package:flutteractixapp/core/errors/domain_error.dart';
import 'package:flutteractixapp/features/auth/data/errors/data_error.dart';
import 'package:flutteractixapp/features/auth/data/models/otp_request_model.dart';
import 'package:flutteractixapp/features/auth/data/models/user_token_request_model.dart';
import 'package:flutteractixapp/features/auth/data/sources/remote_data_sources.dart';
import 'package:flutteractixapp/features/auth/domain/entities/otp_generation.dart';
import 'package:flutteractixapp/features/auth/domain/entities/user_token.dart';
import 'package:flutteractixapp/features/auth/domain/errors/domain_error.dart';
import 'package:flutteractixapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:logger/web.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final logger = Logger();

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserToken> register(
      {required String username,
      required String password,
      required String locale,
      required String theme}) async {
    try {
      final userTokenModel = await remoteDataSource.register(
          RegisterUserRequestModel(
              username: username,
              password: password,
              locale: locale,
              theme: theme));

      return UserToken(
          accessToken: userTokenModel.accessToken,
          refreshToken: userTokenModel.refreshToken,
          expiresIn: userTokenModel.expiresIn,
          recoveryCodes: userTokenModel.recoveryCodes);
    } on NetworkError catch (e) {
      logger.e('Network error occurred: ${e.message}');
      throw NetworkDomainError('Unable to register due to a network error.');
    } on ParsingError catch (e) {
      logger.e('ParsingError error occurred: ${e.message}');
      throw InvalidRegisterDomainError();
    } on UnauthorizedError catch (e) {
      logger.e('UnauthorizedError error occurred: ${e.message}');
      throw UnauthorizedDomainError();
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      throw UnknownDomainError();
    }
  }

  @override
  Future<Either<UserToken, String>> login({
    required String username,
    required String password,
  }) async {
    try {
      final result = await remoteDataSource
          .login(LoginUserRequestModel(username: username, password: password));

      return result.fold(
          (userTokenModel) => Left(UserToken(
              accessToken: userTokenModel.accessToken,
              refreshToken: userTokenModel.refreshToken,
              expiresIn: userTokenModel.expiresIn)),
          (string) => Right(string));
    } on NetworkError catch (e) {
      logger.e('Network error occurred: ${e.message}');
      throw NetworkDomainError('Unable to login due to a network error.');
    } on ParsingError catch (e) {
      logger.e('ParsingError error occurred: ${e.message}');
      throw InvalidLoginDomainError();
    } on UnauthorizedError catch (e) {
      logger.e('UnauthorizedError error occurred: ${e.message}');
      throw UnauthorizedDomainError();
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      throw UnknownDomainError();
    }
  }

  @override
  Future<GeneratedOtpConfig> generateOtpConfig(
      {required String accessToken}) async {
    try {
      final generatedOtpConfigModel =
          await remoteDataSource.generateOtpConfig(accessToken);

      return GeneratedOtpConfig(
          otpBase32: generatedOtpConfigModel.otpBase32,
          otpAuthUrl: generatedOtpConfigModel.otpAuthUrl);
    } on NetworkError catch (e) {
      logger.e('Network error occurred: ${e.message}');
      throw NetworkDomainError(
          'Unable to generate otp configuration due to a network error.');
    } on ParsingError catch (e) {
      logger.e('ParsingError error occurred: ${e.message}');
      throw InvalidOtpGenerationDomainError();
    } on UnauthorizedError catch (e) {
      logger.e('UnauthorizedError error occurred: ${e.message}');
      throw UnauthorizedDomainError();
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      throw UnknownDomainError();
    }
  }

  @override
  Future<bool> verifyOtp({
    required String accessToken,
    required String code,
  }) async {
    try {
      final result =
          await remoteDataSource.verifyOtp(VerifyOtpRequestModel(code: code));
      return result;
    } on NetworkError catch (e) {
      logger.e('Network error occurred: ${e.message}');
      throw NetworkDomainError('Unable to verify otp due to a network error.');
    } on ParsingError catch (e) {
      logger.e('ParsingError error occurred: ${e.message}');
      throw InvalidOtpVerificationDomainError();
    } on UnauthorizedError catch (e) {
      logger.e('UnauthorizedError error occurred: ${e.message}');
      throw UnauthorizedDomainError();
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      throw UnknownDomainError();
    }
  }

  @override
  Future<UserToken> validateOtp({
    required String userId,
    required String code,
  }) async {
    try {
      final userTokenModel = await remoteDataSource
          .validateOtp(ValidateOtpRequestModel(userId: userId, code: code));

      return UserToken(
          accessToken: userTokenModel.accessToken,
          refreshToken: userTokenModel.refreshToken,
          expiresIn: userTokenModel.expiresIn);
    } on NetworkError catch (e) {
      logger.e('Network error occurred: ${e.message}');
      throw NetworkDomainError(
          'Unable to validate otp due to a network error.');
    } on ParsingError catch (e) {
      logger.e('ParsingError error occurred: ${e.message}');
      throw InvalidOtpValidationDomainError();
    } on UnauthorizedError catch (e) {
      logger.e('UnauthorizedError error occurred: ${e.message}');
      throw UnauthorizedDomainError();
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      throw UnknownDomainError();
    }
  }

  @override
  Future<bool> disableOtp({
    required String accessToken,
  }) async {
    try {
      final result =
          await remoteDataSource.disableOtp(accessToken: accessToken);
      return result;
    } on NetworkError catch (e) {
      logger.e('Network error occurred: ${e.message}');
      throw NetworkDomainError('Unable to disable otp due to a network error.');
    } on ParsingError catch (e) {
      logger.e('ParsingError error occurred: ${e.message}');
      throw InvalidOtpDisablingDomainError();
    } on UnauthorizedError catch (e) {
      logger.e('UnauthorizedError error occurred: ${e.message}');
      throw UnauthorizedDomainError();
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      throw UnknownDomainError();
    }
  }

  @override
  Future<bool> checkIfOtpEnabled({required String username}) async {
    try {
      final result = await remoteDataSource
          .checkIfOtpEnabled(CheckIfOtpEnabledRequestModel(username: username));
      return result;
    } on NetworkError catch (e) {
      logger.e('Network error occurred: ${e.message}');
      throw NetworkDomainError('Unable to disable otp due to a network error.');
    } on ParsingError catch (e) {
      logger.e('ParsingError error occurred: ${e.message}');
      throw InvalidOtpDisablingDomainError();
    } on UnauthorizedError catch (e) {
      logger.e('UnauthorizedError error occurred: ${e.message}');
      throw UnauthorizedDomainError();
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      throw UnknownDomainError();
    }
  }

  @override
  Future<UserToken> recoverAccountWithRecoveryCodeAndPassword({
    required String username,
    required String password,
    required String recoveryCode,
  }) async {
    try {
      final userTokenModel =
          await remoteDataSource.recoverAccountWithRecoveryCodeAndPassword(
              RecoverAccountWithRecoveryCodeAndPasswordRequestModel(
                  password: password,
                  username: username,
                  recoveryCode: recoveryCode));

      return UserToken(
          accessToken: userTokenModel.accessToken,
          refreshToken: userTokenModel.refreshToken,
          expiresIn: userTokenModel.expiresIn);
    } on NetworkError catch (e) {
      logger.e('Network error occurred: ${e.message}');
      throw NetworkDomainError(
          'Unable to validate otp due to a network error.');
    } on ParsingError catch (e) {
      logger.e('ParsingError error occurred: ${e.message}');
      throw InvalidOtpValidationDomainError();
    } on UnauthorizedError catch (e) {
      logger.e('UnauthorizedError error occurred: ${e.message}');
      throw UnauthorizedDomainError();
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      throw UnknownDomainError();
    }
  }

  @override
  Future<UserToken> recoverAccountWithRecoveryCodeAndOtp({
    required String username,
    required String code,
    required String recoveryCode,
  }) async {
    try {
      final userTokenModel =
          await remoteDataSource.recoverAccountWithRecoveryCodeAndOtp(
              RecoverAccountWithRecoveryCodeAndOtpRequestModel(
                  code: code, username: username, recoveryCode: recoveryCode));

      return UserToken(
          accessToken: userTokenModel.accessToken,
          refreshToken: userTokenModel.refreshToken,
          expiresIn: userTokenModel.expiresIn);
    } on NetworkError catch (e) {
      logger.e('Network error occurred: ${e.message}');
      throw NetworkDomainError(
          'Unable to validate otp due to a network error.');
    } on ParsingError catch (e) {
      logger.e('ParsingError error occurred: ${e.message}');
      throw InvalidOtpValidationDomainError();
    } on UnauthorizedError catch (e) {
      logger.e('UnauthorizedError error occurred: ${e.message}');
      throw UnauthorizedDomainError();
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      throw UnknownDomainError();
    }
  }

  @override
  Future<UserToken> recoverAccountWithRecoveryCode({
    required String username,
    required String recoveryCode,
  }) async {
    try {
      final userTokenModel =
          await remoteDataSource.recoverAccountWithRecoveryCode(
              RecoverAccountWithRecoveryCodeRequestModel(
                  username: username, recoveryCode: recoveryCode));

      return UserToken(
          accessToken: userTokenModel.accessToken,
          refreshToken: userTokenModel.refreshToken,
          expiresIn: userTokenModel.expiresIn);
    } on NetworkError catch (e) {
      logger.e('Network error occurred: ${e.message}');
      throw NetworkDomainError(
          'Unable to validate otp due to a network error.');
    } on ParsingError catch (e) {
      logger.e('ParsingError error occurred: ${e.message}');
      throw InvalidOtpValidationDomainError();
    } on UnauthorizedError catch (e) {
      logger.e('UnauthorizedError error occurred: ${e.message}');
      throw UnauthorizedDomainError();
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      throw UnknownDomainError();
    }
  }
}
