import 'package:flutteractixapp/features/auth/domain/entities/user_token.dart';
import 'package:flutteractixapp/features/auth/domain/repositories/auth_repository.dart';

class ValidateOtpUsecase {
  final AuthRepository authRepository;

  ValidateOtpUsecase(this.authRepository);

  /// Validates the OTP provided by the user. It's for login.
  Future<UserToken> call(String userId, String code) async {
    final userTokenModel =
        await authRepository.validateOtp(userId: userId, code: code);

    return UserToken(
        accessToken: userTokenModel.accessToken,
        refreshToken: userTokenModel.refreshToken,
        expiresIn: userTokenModel.expiresIn,
        recoveryCodes: userTokenModel.recoveryCodes);
  }
}
