import 'package:dartz/dartz.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/features/profile/domain/repositories/profile_repository.dart';

class DeleteDeviceUseCase {
  final ProfileRepository profileRepository;

  DeleteDeviceUseCase(this.profileRepository);

  Future<Either<DomainError, void>> call(String deviceId) async {
    return await profileRepository.deleteDevice(deviceId);
  }
}
