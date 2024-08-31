// features/auth/data/repositories/auth_repository.dart

import 'dart:async';

import 'package:logger/web.dart';
import 'package:reallystick/core/errors/data_error.dart';
import 'package:reallystick/core/errors/domain_error.dart';
import 'package:reallystick/features/auth/data/errors/data_error.dart';
import 'package:reallystick/features/auth/domain/errors/domain_error.dart';
import 'package:reallystick/features/profile/data/models/user_request_model.dart';
import 'package:reallystick/features/profile/data/sources/remote_data_sources.dart';
import 'package:reallystick/features/profile/domain/entities/user.dart';
import 'package:reallystick/features/profile/domain/errors/domain_error.dart';
import 'package:reallystick/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final logger = Logger();

  ProfileRepositoryImpl(this.remoteDataSource);

  @override
  Future<User> getProfileInformation(String accessToken) async {
    try {
      final user = await remoteDataSource.getProfileInformation(accessToken);

      return User(
          username: user.username, locale: user.locale, theme: user.theme);
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
      final user = await remoteDataSource.postProfileInformation(
          accessToken,
          UpdateUserRequestModel(
              username: profile.username,
              locale: profile.locale,
              theme: profile.theme));

      return User(
          username: user.username, locale: user.locale, theme: user.theme);
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
