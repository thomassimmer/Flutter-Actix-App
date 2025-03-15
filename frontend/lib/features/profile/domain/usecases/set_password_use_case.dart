import 'package:flutteractixapp/features/profile/domain/entities/user.dart';
import 'package:flutteractixapp/features/profile/domain/repositories/profile_repository.dart';

class SetPasswordUseCase {
  final ProfileRepository profileRepository;

  SetPasswordUseCase(this.profileRepository);

  Future<User> call({required String newPassword}) async {
    return await profileRepository.setPassword(newPassword);
  }
}
