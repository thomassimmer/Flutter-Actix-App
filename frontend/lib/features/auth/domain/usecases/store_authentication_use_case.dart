import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reallystick/core/constants/errors.dart';
import 'package:reallystick/features/auth/domain/errors/failures.dart';

class StoreAuthenticationUseCase {
  final FlutterSecureStorage secureStorage;

  StoreAuthenticationUseCase({FlutterSecureStorage? secureStorage})
      : secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<Either<bool, Failure>> storeAuthentication(
      String accessToken, String refreshToken, int expiresIn) async {
    try {
      await secureStorage.write(key: 'accessToken', value: accessToken);
      await secureStorage.write(key: 'refreshToken', value: refreshToken);
      await secureStorage.write(key: 'expiresIn', value: expiresIn.toString());

      return const Left(true);
    } catch (e) {
      return Right(StorageFailure(message: e.toString()));
    }
  }
}
