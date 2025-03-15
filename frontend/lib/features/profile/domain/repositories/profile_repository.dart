// features/auth/data/repositories/auth_repository.dart

import 'dart:async';

import 'package:flutteractixapp/features/profile/domain/entities/user.dart';

abstract class ProfileRepository {
  Future<User> getProfileInformation(String accessToken);
  Future<User> postProfileInformation(String accessToken, User profile);
  Future<User> setPassword(String accessToken, String newPassword);
  Future<User> updatePassword(
      String accessToken, String currentPassword, String newPassword);
}
