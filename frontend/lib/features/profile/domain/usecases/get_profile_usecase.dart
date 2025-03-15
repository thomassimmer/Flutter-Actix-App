import 'package:flutteractixapp/features/auth/data/storage/token_storage.dart';
import 'package:flutteractixapp/features/profile/domain/entities/user.dart';
import 'package:flutteractixapp/features/profile/domain/repositories/profile_repository.dart';

class GetProfileUsecase {
  final ProfileRepository profileRepository;

  GetProfileUsecase(this.profileRepository);

  Future<User> call() async {
    final accessToken = await TokenStorage().getAccessToken();
    return await profileRepository.getProfileInformation(accessToken!);
  }
}
