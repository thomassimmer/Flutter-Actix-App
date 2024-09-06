// features/auth/data/repositories/auth_repository.dart

import 'dart:async';

import 'package:flutteractixapp/core/errors/data_error.dart';
import 'package:flutteractixapp/core/errors/domain_error.dart';
import 'package:flutteractixapp/features/auth/data/errors/data_error.dart';
import 'package:flutteractixapp/features/auth/domain/errors/domain_error.dart';
import 'package:flutteractixapp/features/profile/data/models/user_request_model.dart';
import 'package:flutteractixapp/features/profile/data/sources/remote_data_sources.dart';
import 'package:flutteractixapp/features/profile/domain/entities/user.dart';
import 'package:flutteractixapp/features/profile/domain/errors/domain_error.dart';
import 'package:flutteractixapp/features/profile/domain/repositories/profile_repository.dart';
import 'package:logger/web.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final logger = Logger();

  ProfileRepositoryImpl(this.remoteDataSource);

  @override
  Future<User> getProfileInformation(String accessToken) async {
    try {
      final userModel =
          await remoteDataSource.getProfileInformation(accessToken);

      return User(
          username: userModel.username,
          locale: userModel.locale,
          theme: userModel.theme,
          otpBase32: userModel.otpBase32,
          otpAuthUrl: userModel.otpAuthUrl,
          otpVerified: userModel.otpVerified,
          passwordIsExpired: userModel.passwordIsExpired);
    } on NetworkError catch (e) {
      logger.e('Network error occurred: ${e.message}');
      throw NetworkDomainError(
          'Unable to update profile due to a network error.');
    } on ParsingError catch (e) {
      logger.e('ParsingError error occurred: ${e.message}');
      throw InvalidProfileDomainError();
    } on UnauthorizedError catch (e) {
      logger.e('UnauthorizedError error occurred: ${e.message}');
      throw UnauthorizedDomainError();
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      throw UnknownDomainError();
    }
  }

  @override
  Future<User> postProfileInformation(String accessToken, User profile) async {
    try {
      final userModel = await remoteDataSource.postProfileInformation(
          accessToken,
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
    } on NetworkError catch (e) {
      logger.e('Network error occurred: ${e.message}');
      throw NetworkDomainError(
          'Unable to update profile due to a network error.');
    } on ParsingError catch (e) {
      logger.e('ParsingError error occurred: ${e.message}');
      throw InvalidProfileDomainError();
    } on UnauthorizedError catch (e) {
      logger.e('UnauthorizedError error occurred: ${e.message}');
      throw UnauthorizedDomainError();
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      throw UnknownDomainError();
    }
  }

  @override
  Future<User> setPassword(String accessToken, String newPassword) async {
    try {
      final userModel = await remoteDataSource.setPassword(
          accessToken, SetPasswordRequestModel(newPassword: newPassword));

      return User(
          username: userModel.username,
          locale: userModel.locale,
          theme: userModel.theme,
          otpBase32: userModel.otpBase32,
          otpAuthUrl: userModel.otpAuthUrl,
          otpVerified: userModel.otpVerified,
          passwordIsExpired: userModel.passwordIsExpired);
    } on NetworkError catch (e) {
      logger.e('Network error occurred: ${e.message}');
      throw NetworkDomainError(
          'Unable to update profile due to a network error.');
    } on ParsingError catch (e) {
      logger.e('ParsingError error occurred: ${e.message}');
      throw InvalidProfileDomainError();
    } on UnauthorizedError catch (e) {
      logger.e('UnauthorizedError error occurred: ${e.message}');
      throw UnauthorizedDomainError();
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      throw UnknownDomainError();
    }
  }

  @override
  Future<User> updatePassword(
      String accessToken, String currentPassword, String newPassword) async {
    try {
      final userModel = await remoteDataSource.updatePassword(
          accessToken,
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
    } on NetworkError catch (e) {
      logger.e('Network error occurred: ${e.message}');
      throw NetworkDomainError(
          'Unable to update profile due to a network error.');
    } on ParsingError catch (e) {
      logger.e('ParsingError error occurred: ${e.message}');
      throw InvalidProfileDomainError();
    } on UnauthorizedError catch (e) {
      logger.e('UnauthorizedError error occurred: ${e.message}');
      throw UnauthorizedDomainError();
    } catch (e) {
      logger.e('Data error occurred: ${e.toString()}');
      throw UnknownDomainError();
    }
  }
}
