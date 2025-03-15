import 'package:dartz/dartz.dart';
import 'package:reallystick/core/constants/errors.dart';
import 'package:reallystick/features/auth/data/storage/token_storage.dart';
import 'package:reallystick/features/profile/data/repositories/profile_repository.dart';
import 'package:reallystick/features/profile/domain/entities/user_entity.dart';
import 'package:reallystick/features/profile/domain/errors/failures.dart';

class GetProfileUsecase {
  final ProfileRepository profileRepository;

  GetProfileUsecase(this.profileRepository);

  Future<Either<UserEntity, Failure>> getProfile() async {
    final accessToken = await TokenStorage().getAccessToken();

    try {
      final result =
          await profileRepository.getProfileInformation(accessToken!);

      return Left(UserEntity(
          username: result.username,
          locale: result.locale,
          theme: result.theme));
    } catch (e) {
      return Right(ProfileFailure(message: e.toString()));
    }
  }
}
