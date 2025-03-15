import 'package:equatable/equatable.dart';
import 'package:reallystick/features/auth/domain/entities/user_entity.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;

  const AuthLoginRequested({
    required this.username,
    required this.password,
  });

  @override
  List<Object> get props => [username, password];
}

class AuthSignupRequested extends AuthEvent {
  final String username;
  final String password;

  const AuthSignupRequested({
    required this.username,
    required this.password,
  });

  @override
  List<Object> get props => [username, password];
}

class AuthOtpRequested extends AuthEvent {
  final UserEntity user;
  final String username;

  const AuthOtpRequested({required this.user, required this.username});

  @override
  List<Object> get props => [user, username];
}

class AuthOtpFirstTimeVerified extends AuthEvent {
  final UserEntity user;
  final String code;

  const AuthOtpFirstTimeVerified({
    required this.user,
    required this.code,
  });

  @override
  List<Object> get props => [user, code];
}

class AuthOTPVerified extends AuthEvent {
  final String userId;
  final String otp;

  const AuthOTPVerified({
    required this.userId,
    required this.otp,
  });

  @override
  List<Object> get props => [userId, otp];
}
