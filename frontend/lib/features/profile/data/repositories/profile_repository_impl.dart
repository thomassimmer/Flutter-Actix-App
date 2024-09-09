// features/auth/data/repositories/auth_repository.dart

import 'dart:async';

import 'package:flutteractixapp/core/errors/data_error.dart';
import 'package:flutteractixapp/core/errors/domain_error.dart';
import 'package:flutteractixapp/features/auth/data/errors/data_error.dart';
import 'package:flutteractixapp/features/auth/domain/errors/domain_error.dart';
import 'package:flutteractixapp/features/profile/data/models/user_request_model.dart';
import 'package:flutteractixapp/features/profile/data/sources/remote_data_sources.dart';
import 'package:flutteractixapp/features/profile/domain/entities/user.dart';
import 'package:flutteractixapp/features/profile/domain/repositories/profile_repository.dart';
import 'package:logger/web.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final logger = Logger();

  ProfileRepositoryImpl(this.remoteDataSource);

  @override
  Future<User> getProfileInformation() async {
    try {
      final userModel = await remoteDataSource.getProfileInformation();

      return User(
          username: userModel.username,
          locale: userModel.locale,
          theme: userModel.theme,
          otpBase32: userModel.otpBase32,
          otpAuthUrl: userModel.otpAuthUrl,
          otpVerified: userModel.otpVerified,
          passwordIsExpired: userModel.passwordIsExpired);
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
  Future<User> postProfileInformation(User profile) async {
    try {
      final userModel = await remoteDataSource.postProfileInformation(
          UpdateUserRequestModel(
              username: profile.username,
              locale: profile.locale,
              theme: profile.theme));

      return User(
          username: userModel.username,
          locale: userModel.locale,
          theme: userModel.theme,
          otpBase32: userModel.otpBase32,
          otpAuthUrl: userModel.otpAuthUrl,
          otpVerified: userModel.otpVerified,
          passwordIsExpired: userModel.passwordIsExpired);
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
  Future<User> setPassword(String newPassword) async {
    try {
      final userModel = await remoteDataSource
          .setPassword(SetPasswordRequestModel(newPassword: newPassword));

      return User(
          username: userModel.username,
          locale: userModel.locale,
          theme: userModel.theme,
          otpBase32: userModel.otpBase32,
          otpAuthUrl: userModel.otpAuthUrl,
          otpVerified: userModel.otpVerified,
          passwordIsExpired: userModel.passwordIsExpired);
    } on ParsingError {
      logger.e('ParsingError occurred.');
      throw InvalidResponseDomainError();
    } on UnauthorizedError {
      logger.e('UnauthorizedError occurred.');
      throw UnauthorizedDomainError();
    } on PasswordNotExpiredError {
      logger.e('PasswordNotExpiredError occured.');
      throw PasswordNotExpiredDomainError();
    } on RefreshTokenNotFoundError {
      logger.e('RefreshTokenNotFoundError occured.');
      throw RefreshTokenNotFoundDomainError();
    } on InvalidRefreshTokenError {
      logger.e('InvalidRefreshTokenError occured.');
      throw InvalidRefreshTokenDomainError();
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
  Future<User> updatePassword(
      String currentPassword, String newPassword) async {
    try {
      final userModel = await remoteDataSource.updatePassword(
          UpdatePasswordRequestModel(
              currentPassword: currentPassword, newPassword: newPassword));

      return User(
          username: userModel.username,
          locale: userModel.locale,
          theme: userModel.theme,
          otpBase32: userModel.otpBase32,
          otpAuthUrl: userModel.otpAuthUrl,
          otpVerified: userModel.otpVerified,
          passwordIsExpired: userModel.passwordIsExpired);
    } on ParsingError {
      logger.e('ParsingError occurred.');
      throw InvalidResponseDomainError();
    } on InvalidUsernameOrPasswordError {
      logger.e('InvalidUsernameOrPasswordError occured.');
      throw InvalidUsernameOrPasswordDomainError();
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
}
