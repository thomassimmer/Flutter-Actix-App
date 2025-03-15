import 'package:equatable/equatable.dart';
import 'package:reallystick/features/auth/domain/entities/otp_entity.dart';
import 'package:reallystick/features/auth/domain/entities/user_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthOtpFirstTimeRequired extends AuthState {
  final UserEntity user;
  final OtpEntity? otp;

  const AuthOtpFirstTimeRequired({required this.user, this.otp});

  @override
  List<Object?> get props => [user, otp];
}

class AuthOtpRequired extends AuthState {
  final String userId;
  final OtpEntity? otp;

  const AuthOtpRequired({required this.userId, this.otp});

  @override
  List<Object?> get props => [userId, otp];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object> get props => [message];
}

class AuthOtpFirstTimeFailure extends AuthState {
  final String message;
  final UserEntity user;

  const AuthOtpFirstTimeFailure({required this.message, required this.user});

  @override
  List<Object> get props => [message, user];
}

class AuthOtpFailure extends AuthState {
  final String message;
  final String userId;

  const AuthOtpFailure({required this.message, required this.userId});

  @override
  List<Object> get props => [message, userId];
}
