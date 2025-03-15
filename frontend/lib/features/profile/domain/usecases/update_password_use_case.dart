import 'package:flutteractixapp/features/auth/data/storage/token_storage.dart';
import 'package:flutteractixapp/features/profile/domain/entities/user.dart';
import 'package:flutteractixapp/features/profile/domain/repositories/profile_repository.dart';

class UpdatePasswordUseCase {
  final ProfileRepository profileRepository;

  UpdatePasswordUseCase(this.profileRepository);

  Future<User> call(
      {required String currentPassword, required String newPassword}) async {
    final accessToken = await TokenStorage().getAccessToken();
    return await profileRepository.updatePassword(
        accessToken!, currentPassword, newPassword);
  }
}
