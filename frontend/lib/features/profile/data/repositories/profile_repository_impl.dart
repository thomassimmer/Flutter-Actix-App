// features/auth/data/repositories/auth_repository.dart

import 'dart:async';

import 'package:reallystick/features/profile/data/models/user_request_model.dart';
import 'package:reallystick/features/profile/data/sources/remote_data_sources.dart';
import 'package:reallystick/features/profile/domain/entities/user.dart';
import 'package:reallystick/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl(this.remoteDataSource);

  @override
  Future<User> getProfileInformation(String accessToken) async {
    final user = await remoteDataSource.getProfileInformation(accessToken);

    return User(
        username: user.username, locale: user.locale, theme: user.theme);
  }

  @override
  Future<User> postProfileInformation(String accessToken, User profile) async {
    final user = await remoteDataSource.postProfileInformation(
        accessToken,
        UpdateUserRequestModel(
            username: profile.username,
            locale: profile.locale,
            theme: profile.theme));

    return User(
        username: user.username, locale: user.locale, theme: user.theme);
  }
}
