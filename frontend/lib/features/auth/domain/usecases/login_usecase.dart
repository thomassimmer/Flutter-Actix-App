import 'package:dartz/dartz.dart';
import 'package:reallystick/core/constants/errors.dart';
import 'package:reallystick/features/auth/data/repositories/auth_repository.dart';
import 'package:reallystick/features/auth/domain/entities/user_token_entity.dart';
import 'package:reallystick/features/auth/domain/errors/failures.dart';

class LoginUseCase {
  final AuthRepository authRepository;

  LoginUseCase(this.authRepository);

  Future<Either<Either<UserTokenEntity, String>, Failure>> login(
      String username, String password) async {
    try {
      final result =
          await authRepository.login(username: username, password: password);

      return result.fold(
        (userTokenModel) => Left(Left(UserTokenEntity(
            accessToken: userTokenModel.accessToken,
            refreshToken: userTokenModel.refreshToken,
            expiresIn: userTokenModel.expiresIn,
            recoveryCodes: userTokenModel.recoveryCodes))),
        (userId) => Left(Right(userId)),
      );
    } catch (e) {
      return Right(ServerFailure(message: e.toString()));
    }
  }
}
