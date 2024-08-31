import 'package:reallystick/features/auth/data/storage/token_storage.dart';
import 'package:reallystick/features/profile/domain/entities/user.dart';
import 'package:reallystick/features/profile/domain/repositories/profile_repository.dart';

class GetProfileUsecase {
  final ProfileRepository profileRepository;

  GetProfileUsecase(this.profileRepository);

  Future<User> call() async {
    final accessToken = await TokenStorage().getAccessToken();
    final result = await profileRepository.getProfileInformation(accessToken!);

    return User(
        username: result.username, locale: result.locale, theme: result.theme);
  }
}
