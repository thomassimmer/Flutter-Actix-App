import 'package:reallystick/features/auth/data/storage/token_storage.dart';
import 'package:reallystick/features/profile/domain/entities/user.dart';
import 'package:reallystick/features/profile/domain/repositories/profile_repository.dart';

class PostProfileUsecase {
  final ProfileRepository profileRepository;

  PostProfileUsecase(this.profileRepository);

  Future<User> call(User profile) async {
    final accessToken = await TokenStorage().getAccessToken();
    final result =
        await profileRepository.postProfileInformation(accessToken!, profile);

    return User(
        username: result.username, locale: result.locale, theme: result.theme);
  }
}
