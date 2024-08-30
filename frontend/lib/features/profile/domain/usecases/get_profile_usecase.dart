import 'package:dartz/dartz.dart';
import 'package:reallystick/core/constants/errors.dart';
import 'package:reallystick/features/auth/data/storage/token_storage.dart';
import 'package:reallystick/features/profile/domain/entities/user.dart';
import 'package:reallystick/features/profile/domain/errors/failures.dart';
import 'package:reallystick/features/profile/domain/repositories/profile_repository.dart';

class GetProfileUsecase {
  final ProfileRepository profileRepository;

  GetProfileUsecase(this.profileRepository);

  Future<Either<User, Failure>> getProfile() async {
    final accessToken = await TokenStorage().getAccessToken();

    try {
      final result =
          await profileRepository.getProfileInformation(accessToken!);

      return Left(User(
          username: result.username,
          locale: result.locale,
          theme: result.theme));
    } catch (e) {
      return Right(ProfileFailure(message: e.toString()));
    }
  }
}
