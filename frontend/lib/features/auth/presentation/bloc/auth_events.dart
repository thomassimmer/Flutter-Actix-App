import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

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

class AuthOTPRequested extends AuthEvent {
  final String userId;
  final String username;

  const AuthOTPRequested({required this.userId, required this.username});

  @override
  List<Object> get props => [userId, username];
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
