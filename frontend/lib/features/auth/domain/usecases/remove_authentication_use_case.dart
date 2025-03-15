import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reallystick/features/auth/domain/errors/failures.dart';

class RemoveAuthenticationUseCase {
  final FlutterSecureStorage secureStorage;

  RemoveAuthenticationUseCase({FlutterSecureStorage? secureStorage})
      : secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<Either<bool, Failure>> removeAuthentication() async {
    try {
      await secureStorage.delete(key: 'accessToken');
      await secureStorage.delete(key: 'refreshToken');
      await secureStorage.delete(key: 'expiresIn');

      return const Left(true);
    } catch (e) {
      return Right(StorageFailure(message: e.toString()));
    }
  }
}
