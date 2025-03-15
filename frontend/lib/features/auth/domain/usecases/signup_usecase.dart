import 'package:reallystick/features/auth/domain/entities/user_token.dart';
import 'package:reallystick/features/auth/domain/repositories/auth_repository.dart';

class SignupUseCase {
  final AuthRepository authRepository;

  SignupUseCase(this.authRepository);

  Future<UserToken> call(
      String username, String password, String locale, String theme) async {
    final userTokenModel = await authRepository.register(
        username: username, password: password, locale: locale, theme: theme);

    return UserToken(
        accessToken: userTokenModel.accessToken,
        refreshToken: userTokenModel.refreshToken,
        expiresIn: userTokenModel.expiresIn,
        recoveryCodes: userTokenModel.recoveryCodes);
  }
}
