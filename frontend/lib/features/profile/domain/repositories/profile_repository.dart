// features/auth/data/repositories/auth_repository.dart

import 'dart:async';

import 'package:flutteractixapp/features/profile/domain/entities/user.dart';

abstract class ProfileRepository {
  Future<User> getProfileInformation();
  Future<User> postProfileInformation(User profile);
  Future<User> setPassword(String newPassword);
  Future<User> updatePassword(String currentPassword, String newPassword);
}
