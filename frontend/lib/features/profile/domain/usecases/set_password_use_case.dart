import 'package:dartz/dartz.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/features/profile/domain/entities/profile.dart';
import 'package:flutteractixapp/features/profile/domain/repositories/profile_repository.dart';

class SetPasswordUseCase {
  final ProfileRepository profileRepository;

  SetPasswordUseCase(this.profileRepository);

  Future<Either<DomainError, Profile>> call(
      {required String newPassword}) async {
    return await profileRepository.setPassword(newPassword);
  }
}
