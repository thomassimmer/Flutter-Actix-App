// features/auth/data/repositories/auth_repository.dart

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/features/profile/domain/entities/user.dart';

abstract class ProfileRepository {
  Future<Either<DomainError, User>> getProfileInformation();
  Future<Either<DomainError, User>> postProfileInformation(User profile);
  Future<Either<DomainError, User>> setPassword(String newPassword);
  Future<Either<DomainError, User>> updatePassword(
      String currentPassword, String newPassword);
}
