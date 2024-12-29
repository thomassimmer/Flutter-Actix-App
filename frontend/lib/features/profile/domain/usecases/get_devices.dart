import 'package:dartz/dartz.dart';
import 'package:flutteractixapp/core/messages/errors/domain_error.dart';
import 'package:flutteractixapp/features/profile/domain/entities/device.dart';
import 'package:flutteractixapp/features/profile/domain/repositories/profile_repository.dart';

class GetDevicesUsecase {
  final ProfileRepository profileRepository;

  GetDevicesUsecase(this.profileRepository);

  Future<Either<DomainError, List<Device>>> call() async {
    return await profileRepository.getDevices();
  }
}
