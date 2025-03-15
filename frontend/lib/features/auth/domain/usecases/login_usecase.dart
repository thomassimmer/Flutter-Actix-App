import 'package:dartz/dartz.dart';
import 'package:reallystick/features/auth/data/repositories/auth_repository.dart';
import 'package:reallystick/features/auth/domain/entities/user_entity.dart';
import 'package:reallystick/features/auth/domain/errors/failures.dart';

class LoginUseCase {
  final AuthRepository authRepository;

  LoginUseCase(this.authRepository);

  Future<Either<Failure, Either<String, UserEntity>>> login(
      String username, String password) async {
    try {
      final result =
          await authRepository.login(username: username, password: password);

      return result.fold(
        (userId) => Right(Left(userId)),
        (userModel) => Right(Right(UserEntity(
          id: userModel.id,
          username: userModel.username,
          otpEnabled: userModel.otpEnabled,
          otpVerified: userModel.otpVerified,
          otpBase32: userModel.otpBase32,
          otpAuthUrl: userModel.otpAuthUrl,
          createdAt: userModel.createdAt,
          updatedAt: userModel.updatedAt,
        ))),
      );
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
