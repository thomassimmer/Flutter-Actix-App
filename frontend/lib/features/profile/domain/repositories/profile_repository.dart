// features/auth/data/repositories/auth_repository.dart

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/features/profile/domain/entities/profile.dart';

abstract class ProfileRepository {
  Future<Either<DomainError, Profile>> getProfileInformation();
  Future<Either<DomainError, Profile>> postProfileInformation(Profile profile);
  Future<Either<DomainError, Profile>> setPassword(String newPassword);
  Future<Either<DomainError, Profile>> updatePassword(
      String currentPassword, String newPassword);
}
