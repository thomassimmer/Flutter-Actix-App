import 'package:dartz/dartz.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/features/profile/domain/entities/user.dart';
import 'package:flutteractixapp/features/profile/domain/repositories/profile_repository.dart';

class GetProfileUsecase {
  final ProfileRepository profileRepository;

  GetProfileUsecase(this.profileRepository);

  Future<Either<DomainError, User>> call() async {
    return await profileRepository.getProfileInformation();
  }
}
