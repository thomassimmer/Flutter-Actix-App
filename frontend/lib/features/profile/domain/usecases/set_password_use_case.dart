import 'package:dartz/dartz.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/features/profile/domain/entities/user.dart';
import 'package:flutteractixapp/features/profile/domain/repositories/profile_repository.dart';

class SetPasswordUseCase {
  final ProfileRepository profileRepository;

  SetPasswordUseCase(this.profileRepository);

  Future<Either<DomainError, User>> call({required String newPassword}) async {
    return await profileRepository.setPassword(newPassword);
  }
}
