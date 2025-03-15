// features/auth/data/repositories/auth_repository.dart

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutteractixapp/core/messages/errors/data_error.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/features/auth/data/errors/data_error.dart';
import 'package:flutteractixapp/features/auth/domain/errors/domain_error.dart';
import 'package:flutteractixapp/features/profile/data/errors/data_error.dart';
import 'package:flutteractixapp/features/profile/data/models/profile_request_model.dart';
import 'package:flutteractixapp/features/profile/data/sources/remote_data_sources.dart';
import 'package:flutteractixapp/features/profile/domain/entities/profile.dart';
import 'package:flutteractixapp/features/profile/domain/errors/domain_error.dart';
import 'package:flutteractixapp/features/profile/domain/repositories/profile_repository.dart';
import 'package:logger/web.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final logger = Logger();

  ProfileRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<DomainError, Profile>> getProfileInformation() async {
    try {
      final profileModel = await remoteDataSource.getProfileInformation();

      return Right(Profile(
          username: profileModel.username,
          locale: profileModel.locale,
          theme: profileModel.theme,
          otpBase32: profileModel.otpBase32,
          otpAuthUrl: profileModel.otpAuthUrl,
          otpVerified: profileModel.otpVerified,
          passwordIsExpired: profileModel.passwordIsExpired));
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
  Future<Either<DomainError, Profile>> postProfileInformation(
      Profile profile) async {
    try {
      final profileModel = await remoteDataSource.postProfileInformation(
          UpdateProfileRequestModel(
              username: profile.username,
              locale: profile.locale,
              theme: profile.theme));

      return Right(Profile(
          username: profileModel.username,
          locale: profileModel.locale,
          theme: profileModel.theme,
          otpBase32: profileModel.otpBase32,
          otpAuthUrl: profileModel.otpAuthUrl,
          otpVerified: profileModel.otpVerified,
          passwordIsExpired: profileModel.passwordIsExpired));
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
  Future<Either<DomainError, Profile>> setPassword(String newPassword) async {
    try {
      final profileModel = await remoteDataSource
          .setPassword(SetPasswordRequestModel(newPassword: newPassword));

      return Right(Profile(
          username: profileModel.username,
          locale: profileModel.locale,
          theme: profileModel.theme,
          otpBase32: profileModel.otpBase32,
          otpAuthUrl: profileModel.otpAuthUrl,
          otpVerified: profileModel.otpVerified,
          passwordIsExpired: profileModel.passwordIsExpired));
    } on ParsingError {
      logger.e('ParsingError occurred.');
      return Left(InvalidResponseDomainError());
    } on UnauthorizedError {
      logger.e('UnauthorizedError occurred.');
      return Left(UnauthorizedDomainError());
    } on PasswordNotExpiredError {
      logger.e('PasswordNotExpiredError occured.');
      return Left(PasswordNotExpiredDomainError());
    } on RefreshTokenNotFoundError {
      logger.e('RefreshTokenNotFoundError occured.');
      return Left(RefreshTokenNotFoundDomainError());
    } on InvalidRefreshTokenError {
      logger.e('InvalidRefreshTokenError occured.');
      return Left(InvalidRefreshTokenDomainError());
    } on RefreshTokenExpiredError {
      logger.e('RefreshTokenExpiredError occured.');
      return Left(RefreshTokenExpiredDomainError());
    } on PasswordTooShortError {
      logger.e('PasswordTooShortError occured.');
      return Left(PasswordTooShortError());
    } on PasswordNotComplexEnoughError {
      logger.e('PasswordNotComplexEnoughError occured.');
      return Left(PasswordNotComplexEnoughError());
    } on InternalServerError {
      logger.e('InternalServerError occured.');
      return Left(InternalServerDomainError());
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      return Left(UnknownDomainError());
    }
  }

  @override
  Future<Either<DomainError, Profile>> updatePassword(
      String currentPassword, String newPassword) async {
    try {
      final profileModel = await remoteDataSource.updatePassword(
          UpdatePasswordRequestModel(
              currentPassword: currentPassword, newPassword: newPassword));

      return Right(Profile(
          username: profileModel.username,
          locale: profileModel.locale,
          theme: profileModel.theme,
          otpBase32: profileModel.otpBase32,
          otpAuthUrl: profileModel.otpAuthUrl,
          otpVerified: profileModel.otpVerified,
          passwordIsExpired: profileModel.passwordIsExpired));
    } on ParsingError {
      logger.e('ParsingError occurred.');
      return Left(InvalidResponseDomainError());
    } on InvalidUsernameOrPasswordError {
      logger.e('InvalidUsernameOrPasswordError occured.');
      return Left(InvalidUsernameOrPasswordDomainError());
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
    } on PasswordTooShortError {
      logger.e('PasswordTooShortError occured.');
      return Left(PasswordTooShortError());
    } on PasswordNotComplexEnoughError {
      logger.e('PasswordNotComplexEnoughError occured.');
      return Left(PasswordNotComplexEnoughError());
    } on InternalServerError {
      logger.e('InternalServerError occured.');
      return Left(InternalServerDomainError());
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      return Left(UnknownDomainError());
    }
  }
}
