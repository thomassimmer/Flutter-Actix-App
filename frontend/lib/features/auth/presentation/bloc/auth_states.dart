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

class AuthOTPRequired extends AuthState {
  final String userId;
  final OtpEntity? otp;

  const AuthOTPRequired({required this.userId, this.otp});

  @override
  List<Object?> get props => [userId, otp];
}

class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object> get props => [message];
}
