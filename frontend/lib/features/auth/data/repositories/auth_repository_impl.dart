// features/auth/data/repositories/auth_repository.dart

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutteractixapp/core/messages/errors/data_error.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
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
  Future<UserToken> signup(
      {required String username,
      required String password,
      required String locale,
      required String theme}) async {
    try {
      final userTokenModel = await remoteDataSource.signup(
          RegisterUserRequestModel(
              username: username,
              password: password,
              locale: locale,
              theme: theme));

      return UserToken(
          accessToken: userTokenModel.accessToken,
          refreshToken: userTokenModel.refreshToken,
          recoveryCodes: userTokenModel.recoveryCodes);
    } on ParsingError {
      logger.e('ParsingError occurred.');
      throw InvalidResponseDomainError();
    } on UserAlreadyExistingError {
      logger.e('UserAlreadyExistingError occured');
      throw UserAlreadyExistingDomainError();
    } on PasswordTooShortError {
      logger.e('PasswordTooShortError occured.');
      throw PasswordTooShortError();
    } on PasswordNotComplexEnoughError {
      logger.e('PasswordNotComplexEnoughError occured.');
      throw PasswordNotComplexEnoughError();
    } on UsernameWrongSizeError {
      logger.e('UsernameWrongSizeError occured.');
      throw UsernameWrongSizeError();
    } on UsernameNotRespectingRulesError {
      logger.e('UsernameNotRespectingRulesError occured.');
      throw UsernameNotRespectingRulesError();
    } on InternalServerError {
      logger.e('InternalServerError occured.');
      throw InternalServerDomainError();
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
              )),
          (string) => Right(string));
    } on ParsingError {
      logger.e('ParsingError occurred.');
      throw InvalidResponseDomainError();
    } on InvalidUsernameOrPasswordError {
      logger.e('InvalidUsernameOrPasswordError occured.');
      throw InvalidUsernameOrPasswordDomainError();
    } on ForbiddenError {
      logger.e('ForbiddenError occured.');
      throw ForbiddenDomainError();
    } on PasswordMustBeChangedError {
      logger.e('PasswordMustBeChangedError occured.');
      throw PasswordMustBeChangedDomainError();
    } on UnauthorizedError {
      logger.e('UnauthorizedError occurred.');
      throw UnauthorizedDomainError();
    } on InternalServerError {
      logger.e('InternalServerError occured.');
      throw InternalServerDomainError();
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      throw UnknownDomainError();
    }
  }

  @override
  Future<GeneratedOtpConfig> generateOtpConfig() async {
    try {
      final generatedOtpConfigModel =
          await remoteDataSource.generateOtpConfig();

      return GeneratedOtpConfig(
          otpBase32: generatedOtpConfigModel.otpBase32,
          otpAuthUrl: generatedOtpConfigModel.otpAuthUrl);
    } on ParsingError {
      logger.e('ParsingError occurred.');
      throw InvalidResponseDomainError();
    } on UnauthorizedError {
      logger.e('UnauthorizedError occurred.');
      throw UnauthorizedDomainError();
    } on InvalidRefreshTokenError {
      logger.e('InvalidRefreshTokenError occured.');
      throw InvalidRefreshTokenDomainError();
    } on RefreshTokenNotFoundError {
      logger.e('RefreshTokenNotFoundError occured.');
      throw RefreshTokenNotFoundDomainError();
    } on RefreshTokenExpiredError {
      logger.e('RefreshTokenExpiredError occured.');
      throw RefreshTokenExpiredDomainError();
    } on InternalServerError {
      logger.e('InternalServerError occured.');
      throw InternalServerDomainError();
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      throw UnknownDomainError();
    }
  }

  @override
  Future<bool> verifyOtp({
    required String code,
  }) async {
    try {
      final result =
          await remoteDataSource.verifyOtp(VerifyOtpRequestModel(code: code));
      return result;
    } on ParsingError {
      logger.e('ParsingError occurred.');
      throw InvalidResponseDomainError();
    } on UnauthorizedError {
      logger.e('UnauthorizedError occurred.');
      throw UnauthorizedDomainError();
    } on InvalidRefreshTokenError {
      logger.e('InvalidRefreshTokenError occured.');
      throw InvalidRefreshTokenDomainError();
    } on RefreshTokenNotFoundError {
      logger.e('RefreshTokenNotFoundError occured.');
      throw RefreshTokenNotFoundDomainError();
    } on RefreshTokenExpiredError {
      logger.e('RefreshTokenExpiredError occured.');
      throw RefreshTokenExpiredDomainError();
    } on InvalidOneTimePasswordError {
      logger.e('InvalidOneTimePasswordError occured.');
      throw InvalidOneTimePasswordDomainError();
    } on InternalServerError {
      logger.e('InternalServerError occured.');
      throw InternalServerDomainError();
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
      );
    } on ParsingError {
      logger.e('ParsingError occurred.');
      throw InvalidResponseDomainError();
    } on UnauthorizedError {
      logger.e('UnauthorizedError occurred.');
      throw UnauthorizedDomainError();
    } on InternalServerError {
      logger.e('InternalServerError occured.');
      throw InternalServerDomainError();
    } on InvalidOneTimePasswordError {
      logger.e('InvalidOneTimePasswordError occured.');
      throw InvalidOneTimePasswordDomainError();
    } on UserNotFoundError {
      logger.e('UserNotFoundError occured.');
      throw UserNotFoundDomainError();
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      throw UnknownDomainError();
    }
  }

  @override
  Future<bool> disableOtp() async {
    try {
      final result = await remoteDataSource.disableOtp();
      return result;
    } on ParsingError {
      logger.e('ParsingError occurred.');
      throw InvalidResponseDomainError();
    } on UnauthorizedError {
      logger.e('UnauthorizedError occurred.');
      throw UnauthorizedDomainError();
    } on InvalidRefreshTokenError {
      logger.e('InvalidRefreshTokenError occured.');
      throw InvalidRefreshTokenDomainError();
    } on RefreshTokenNotFoundError {
      logger.e('RefreshTokenNotFoundError occured.');
      throw RefreshTokenNotFoundDomainError();
    } on RefreshTokenExpiredError {
      logger.e('RefreshTokenExpiredError occured.');
      throw RefreshTokenExpiredDomainError();
    } on InternalServerError {
      logger.e('InternalServerError occured.');
      throw InternalServerDomainError();
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
    } on ParsingError {
      logger.e('ParsingError occurred.');
      throw InvalidResponseDomainError();
    } on InternalServerError {
      logger.e('InternalServerError occured.');
      throw InternalServerDomainError();
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
      );
    } on ParsingError {
      logger.e('ParsingError occurred.');
      throw InvalidResponseDomainError();
    } on UnauthorizedError {
      logger.e('UnauthorizedError occurred.');
      throw UnauthorizedDomainError();
    } on InternalServerError {
      logger.e('InternalServerError occured.');
      throw InternalServerDomainError();
    } on InvalidUsernameOrPasswordOrRecoveryCodeError {
      logger.e('InvalidUsernameOrPasswordOrRecoveryCodeError occured.');
      throw InvalidUsernameOrPasswordOrRecoveryCodeDomainError;
    } on TwoFactorAuthenticationNotEnabledError {
      logger.e('TwoFactorAuthenticationNotEnabledError occured.');
      throw TwoFactorAuthenticationNotEnabledDomainError;
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
      );
    } on ParsingError {
      logger.e('ParsingError occurred.');
      throw InvalidResponseDomainError();
    } on UnauthorizedError {
      logger.e('UnauthorizedError occurred.');
      throw UnauthorizedDomainError();
    } on InternalServerError {
      logger.e('InternalServerError occured.');
      throw InternalServerDomainError();
    } on InvalidUsernameOrCodeOrRecoveryCodeError {
      logger.e('InvalidUsernameOrCodeOrRecoveryCodeError occured.');
      throw InvalidUsernameOrCodeOrRecoveryCodeDomainError;
    } on TwoFactorAuthenticationNotEnabledError {
      logger.e('TwoFactorAuthenticationNotEnabledError occured.');
      throw TwoFactorAuthenticationNotEnabledDomainError;
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
      );
    } on ParsingError {
      logger.e('ParsingError occurred.');
      throw InvalidResponseDomainError();
    } on UnauthorizedError {
      logger.e('UnauthorizedError occurred.');
      throw UnauthorizedDomainError();
    } on InternalServerError {
      logger.e('InternalServerError occured.');
      throw InternalServerDomainError();
    } on InvalidUsernameOrRecoveryCodeError {
      logger.e('InvalidUsernameOrRecoveryCodeError occured.');
      throw InvalidUsernameOrRecoveryCodeDomainError;
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      throw UnknownDomainError();
    }
  }
}
