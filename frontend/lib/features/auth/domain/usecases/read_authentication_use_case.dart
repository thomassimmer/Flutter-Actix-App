import 'package:dartz/dartz.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reallystick/features/auth/domain/entities/user_token_entity.dart';
import 'package:reallystick/features/auth/domain/errors/failures.dart';

class ReadAuthenticationUseCase {
  final FlutterSecureStorage secureStorage;

  ReadAuthenticationUseCase({FlutterSecureStorage? secureStorage})
      : secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<Either<Failure, UserTokenEntity>> readAuthentication() async {
    try {
      // Read tokens and expiration from secure storage
      final accessToken = await secureStorage.read(key: 'accessToken');
      final refreshToken = await secureStorage.read(key: 'refreshToken');
      final expiresInString = await secureStorage.read(key: 'expiresIn');

      if (accessToken == null ||
          refreshToken == null ||
          expiresInString == null) {
        return Left(StorageFailure(message: 'Missing authentication data.'));
      }

      final expiresIn = int.tryParse(expiresInString);
      if (expiresIn == null) {
        return Left(StorageFailure(message: 'Invalid expiration time.'));
      }

      return Right(UserTokenEntity(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresIn: expiresIn,
      ));
    } catch (e) {
      return Left(StorageFailure(message: e.toString()));
    }
  }
}
