import 'package:flutteractixapp/features/auth/data/storage/token_storage.dart';
import 'package:flutteractixapp/features/profile/domain/entities/user.dart';
import 'package:flutteractixapp/features/profile/domain/repositories/profile_repository.dart';

class PostProfileUsecase {
  final ProfileRepository profileRepository;

  PostProfileUsecase(this.profileRepository);

  Future<User> call(User profile) async {
    final accessToken = await TokenStorage().getAccessToken();
    return await profileRepository.postProfileInformation(accessToken!, profile);
  }
}
