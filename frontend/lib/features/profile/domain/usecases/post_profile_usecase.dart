import 'package:dartz/dartz.dart';
import 'package:reallystick/core/constants/errors.dart';
import 'package:reallystick/features/profile/data/repositories/profile_repository.dart';
import 'package:reallystick/features/profile/domain/entities/user_entity.dart';
import 'package:reallystick/features/profile/domain/errors/failures.dart';

class PostProfileUsecase {
  final ProfileRepository profileRepository;

  PostProfileUsecase(this.profileRepository);

  Future<Either<UserEntity, Failure>> postProfile(
      String accessToken, UserEntity profile) async {
    try {
      final result =
          await profileRepository.postProfileInformation(accessToken, profile);

      return Left(UserEntity(username: result.username, locale: result.locale));
    } catch (e) {
      return Right(ProfileFailure(message: e.toString()));
    }
  }
}
