import 'package:dartz/dartz.dart';
import 'package:reallystick/features/auth/domain/entities/user_token.dart';
import 'package:reallystick/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository authRepository;

  LoginUseCase(this.authRepository);

  Future<Either<UserToken, String>> call(
      String username, String password) async {
    final result =
        await authRepository.login(username: username, password: password);

    return result.fold(
      (userTokenModel) => Left(UserToken(
          accessToken: userTokenModel.accessToken,
          refreshToken: userTokenModel.refreshToken,
          expiresIn: userTokenModel.expiresIn,
          recoveryCodes: userTokenModel.recoveryCodes)),
      (userId) => Right(userId),
    );
  }
}
