import 'package:dartz/dartz.dart';
import 'package:reallystick/core/constants/errors.dart';
import 'package:reallystick/features/auth/data/repositories/auth_repository.dart';
import 'package:reallystick/features/auth/domain/entities/user_token_entity.dart';
import 'package:reallystick/features/auth/domain/errors/failures.dart';

class SignupUseCase {
  final AuthRepository authRepository;

  SignupUseCase(this.authRepository);

  Future<Either<UserTokenEntity, Failure>> signup(
      String username, String password) async {
    try {
      final userTokenModel =
          await authRepository.register(username: username, password: password);

      return Left(UserTokenEntity(
          accessToken: userTokenModel.accessToken,
          refreshToken: userTokenModel.refreshToken,
          expiresIn: userTokenModel.expiresIn,
          recoveryCodes: userTokenModel.recoveryCodes));
    } catch (e) {
      return Right(ServerFailure(message: e.toString()));
    }
  }
}
