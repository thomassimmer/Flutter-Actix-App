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
  Future<Either<DomainError, UserToken>> signup(
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

      return Right(UserToken(
          accessToken: userTokenModel.accessToken,
          refreshToken: userTokenModel.refreshToken,
          recoveryCodes: userTokenModel.recoveryCodes));
    } on ParsingError {
      logger.e('ParsingError occurred.');
      return Left(InvalidResponseDomainError());
    } on UserAlreadyExistingError {
      logger.e('UserAlreadyExistingError occured');
      return Left(UserAlreadyExistingDomainError());
    } on PasswordTooShortError {
      logger.e('PasswordTooShortError occured.');
      return Left(PasswordTooShortError());
    } on PasswordNotComplexEnoughError {
      logger.e('PasswordNotComplexEnoughError occured.');
      return Left(PasswordNotComplexEnoughError());
    } on UsernameWrongSizeError {
      logger.e('UsernameWrongSizeError occured.');
      return Left(UsernameWrongSizeError());
    } on UsernameNotRespectingRulesError {
      logger.e('UsernameNotRespectingRulesError occured.');
      return Left(UsernameNotRespectingRulesError());
    } on InternalServerError {
      logger.e('InternalServerError occured.');
      return Left(InternalServerDomainError());
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      return Left(UnknownDomainError());
    }
  }

  @override
  Future<Either<DomainError, Either<UserToken, String>>> login({
    required String username,
    required String password,
  }) async {
    try {
      final result = await remoteDataSource
          .login(LoginUserRequestModel(username: username, password: password));

      return result.fold(
          (userTokenModel) => Right(Left(UserToken(
                accessToken: userTokenModel.accessToken,
                refreshToken: userTokenModel.refreshToken,
              ))),
          (string) => Right(Right(string)));
    } on ParsingError {
      logger.e('ParsingError occurred.');
      return Left(InvalidResponseDomainError());
    } on InvalidUsernameOrPasswordError {
      logger.e('InvalidUsernameOrPasswordError occured.');
      return Left(InvalidUsernameOrPasswordDomainError());
    } on ForbiddenError {
      logger.e('ForbiddenError occured.');
      return Left(ForbiddenDomainError());
    } on PasswordMustBeChangedError {
      logger.e('PasswordMustBeChangedError occured.');
      return Left(PasswordMustBeChangedDomainError());
    } on UnauthorizedError {
      logger.e('UnauthorizedError occurred.');
      return Left(UnauthorizedDomainError());
    } on InternalServerError {
      logger.e('InternalServerError occured.');
      return Left(InternalServerDomainError());
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      return Left(UnknownDomainError());
    }
  }

  @override
  Future<Either<DomainError, GeneratedOtpConfig>> generateOtpConfig() async {
    try {
      final generatedOtpConfigModel =
          await remoteDataSource.generateOtpConfig();

      return Right(GeneratedOtpConfig(
          otpBase32: generatedOtpConfigModel.otpBase32,
          otpAuthUrl: generatedOtpConfigModel.otpAuthUrl));
    } on ParsingError {
      logger.e('ParsingError occurred.');
      return Left(InvalidResponseDomainError());
    } on UnauthorizedError {
      logger.e('UnauthorizedError occurred.');
      return Left(UnauthorizedDomainError());
    } on InvalidRefreshTokenError {
      logger.e('InvalidRefreshTokenError occured.');
      return Left(InvalidRefreshTokenDomainError());
    } on RefreshTokenNotFoundError {
      logger.e('RefreshTokenNotFoundError occured.');
      return Left(RefreshTokenNotFoundDomainError());
    } on RefreshTokenExpiredError {
      logger.e('RefreshTokenExpiredError occured.');
      return Left(RefreshTokenExpiredDomainError());
    } on InternalServerError {
      logger.e('InternalServerError occured.');
      return Left(InternalServerDomainError());
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      return Left(UnknownDomainError());
    }
  }

  @override
  Future<Either<DomainError, bool>> verifyOtp({
    required String code,
  }) async {
    try {
      final result =
          await remoteDataSource.verifyOtp(VerifyOtpRequestModel(code: code));
      return Right(result);
    } on ParsingError {
      logger.e('ParsingError occurred.');
      return Left(InvalidResponseDomainError());
    } on UnauthorizedError {
      logger.e('UnauthorizedError occurred.');
      return Left(UnauthorizedDomainError());
    } on InvalidRefreshTokenError {
      logger.e('InvalidRefreshTokenError occured.');
      return Left(InvalidRefreshTokenDomainError());
    } on RefreshTokenNotFoundError {
      logger.e('RefreshTokenNotFoundError occured.');
      return Left(RefreshTokenNotFoundDomainError());
    } on RefreshTokenExpiredError {
      logger.e('RefreshTokenExpiredError occured.');
      return Left(RefreshTokenExpiredDomainError());
    } on InvalidOneTimePasswordError {
      logger.e('InvalidOneTimePasswordError occured.');
      return Left(InvalidOneTimePasswordDomainError());
    } on InternalServerError {
      logger.e('InternalServerError occured.');
      return Left(InternalServerDomainError());
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      return Left(UnknownDomainError());
    }
  }

  @override
  Future<Either<DomainError, UserToken>> validateOtp({
    required String userId,
    required String code,
  }) async {
    try {
      final userTokenModel = await remoteDataSource
          .validateOtp(ValidateOtpRequestModel(userId: userId, code: code));

      return Right(UserToken(
        accessToken: userTokenModel.accessToken,
        refreshToken: userTokenModel.refreshToken,
      ));
    } on ParsingError {
      logger.e('ParsingError occurred.');
      return Left(InvalidResponseDomainError());
    } on UnauthorizedError {
      logger.e('UnauthorizedError occurred.');
      return Left(UnauthorizedDomainError());
    } on InternalServerError {
      logger.e('InternalServerError occured.');
      return Left(InternalServerDomainError());
    } on InvalidOneTimePasswordError {
      logger.e('InvalidOneTimePasswordError occured.');
      return Left(InvalidOneTimePasswordDomainError());
    } on UserNotFoundError {
      logger.e('UserNotFoundError occured.');
      return Left(UserNotFoundDomainError());
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      return Left(UnknownDomainError());
    }
  }

  @override
  Future<Either<DomainError, bool>> disableOtp() async {
    try {
      final result = await remoteDataSource.disableOtp();
      return Right(result);
    } on ParsingError {
      logger.e('ParsingError occurred.');
      return Left(InvalidResponseDomainError());
    } on UnauthorizedError {
      logger.e('UnauthorizedError occurred.');
      return Left(UnauthorizedDomainError());
    } on InvalidRefreshTokenError {
      logger.e('InvalidRefreshTokenError occured.');
      return Left(InvalidRefreshTokenDomainError());
    } on RefreshTokenNotFoundError {
      logger.e('RefreshTokenNotFoundError occured.');
      return Left(RefreshTokenNotFoundDomainError());
    } on RefreshTokenExpiredError {
      logger.e('RefreshTokenExpiredError occured.');
      return Left(RefreshTokenExpiredDomainError());
    } on InternalServerError {
      logger.e('InternalServerError occured.');
      return Left(InternalServerDomainError());
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      return Left(UnknownDomainError());
    }
  }

  @override
  Future<Either<DomainError, bool>> checkIfOtpEnabled(
      {required String username}) async {
    try {
      final result = await remoteDataSource
          .checkIfOtpEnabled(CheckIfOtpEnabledRequestModel(username: username));
      return Right(result);
    } on ParsingError {
      logger.e('ParsingError occurred.');
      return Left(InvalidResponseDomainError());
    } on InternalServerError {
      logger.e('InternalServerError occured.');
      return Left(InternalServerDomainError());
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      return Left(UnknownDomainError());
    }
  }

  @override
  Future<Either<DomainError, UserToken>>
      recoverAccountWithRecoveryCodeAndPassword({
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

      return Right(UserToken(
        accessToken: userTokenModel.accessToken,
        refreshToken: userTokenModel.refreshToken,
      ));
    } on ParsingError {
      logger.e('ParsingError occurred.');
      return Left(InvalidResponseDomainError());
    } on UnauthorizedError {
      logger.e('UnauthorizedError occurred.');
      return Left(UnauthorizedDomainError());
    } on InternalServerError {
      logger.e('InternalServerError occured.');
      return Left(InternalServerDomainError());
    } on InvalidUsernameOrPasswordOrRecoveryCodeError {
      logger.e('InvalidUsernameOrPasswordOrRecoveryCodeError occured.');
      return Left(InvalidUsernameOrPasswordOrRecoveryCodeDomainError());
    } on TwoFactorAuthenticationNotEnabledError {
      logger.e('TwoFactorAuthenticationNotEnabledError occured.');
      return Left(TwoFactorAuthenticationNotEnabledDomainError());
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      return Left(UnknownDomainError());
    }
  }

  @override
  Future<Either<DomainError, UserToken>> recoverAccountWithRecoveryCodeAndOtp({
    required String username,
    required String code,
    required String recoveryCode,
  }) async {
    try {
      final userTokenModel =
          await remoteDataSource.recoverAccountWithRecoveryCodeAndOtp(
              RecoverAccountWithRecoveryCodeAndOtpRequestModel(
                  code: code, username: username, recoveryCode: recoveryCode));

      return Right(UserToken(
        accessToken: userTokenModel.accessToken,
        refreshToken: userTokenModel.refreshToken,
      ));
    } on ParsingError {
      logger.e('ParsingError occurred.');
      return Left(InvalidResponseDomainError());
    } on UnauthorizedError {
      logger.e('UnauthorizedError occurred.');
      return Left(UnauthorizedDomainError());
    } on InternalServerError {
      logger.e('InternalServerError occured.');
      return Left(InternalServerDomainError());
    } on InvalidUsernameOrCodeOrRecoveryCodeError {
      logger.e('InvalidUsernameOrCodeOrRecoveryCodeError occured.');
      return Left(InvalidUsernameOrCodeOrRecoveryCodeDomainError());
    } on TwoFactorAuthenticationNotEnabledError {
      logger.e('TwoFactorAuthenticationNotEnabledError occured.');
      return Left(TwoFactorAuthenticationNotEnabledDomainError());
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      return Left(UnknownDomainError());
    }
  }

  @override
  Future<Either<DomainError, UserToken>> recoverAccountWithRecoveryCode({
    required String username,
    required String recoveryCode,
  }) async {
    try {
      final userTokenModel =
          await remoteDataSource.recoverAccountWithRecoveryCode(
              RecoverAccountWithRecoveryCodeRequestModel(
                  username: username, recoveryCode: recoveryCode));

      return Right(UserToken(
        accessToken: userTokenModel.accessToken,
        refreshToken: userTokenModel.refreshToken,
      ));
    } on ParsingError {
      logger.e('ParsingError occurred.');
      return Left(InvalidResponseDomainError());
    } on UnauthorizedError {
      logger.e('UnauthorizedError occurred.');
      return Left(UnauthorizedDomainError());
    } on InternalServerError {
      logger.e('InternalServerError occured.');
      return Left(InternalServerDomainError());
    } on InvalidUsernameOrRecoveryCodeError {
      logger.e('InvalidUsernameOrRecoveryCodeError occured.');
      return Left(InvalidUsernameOrRecoveryCodeDomainError());
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      return Left(UnknownDomainError());
    }
  }
}
