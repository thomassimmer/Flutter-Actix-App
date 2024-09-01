import 'package:dartz/dartz.dart';
import 'package:flutteractixapp/features/auth/domain/entities/user_token.dart';
import 'package:flutteractixapp/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository authRepository;

  LoginUseCase(this.authRepository);

  Future<Either<UserToken, String>> call(
      String username, String password) async {
    return await authRepository.login(username: username, password: password);
  }
}
