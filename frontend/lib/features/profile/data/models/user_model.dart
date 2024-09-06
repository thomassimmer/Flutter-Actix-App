import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String username;
  final String locale;
  final String theme;
  final String? otpBase32;
  final String? otpAuthUrl;
  final bool otpVerified;
  final bool passwordIsExpired;

  const UserModel(
      {required this.username,
      required this.locale,
      required this.theme,
      required this.otpBase32,
      required this.otpAuthUrl,
      required this.otpVerified,
      required this.passwordIsExpired});

  // Factory constructor to create a UserModel from JSON data
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
        username: json['username'] as String,
        locale: json['locale'] as String,
        theme: json['theme'] as String,
        otpBase32: json['otp_base32'] as String?,
        otpAuthUrl: json['otp_auth_url'] as String?,
        otpVerified: json['otp_verified'] as bool,
        passwordIsExpired: json['password_is_expired'] as bool);
  }

  @override
  List<Object?> get props => [
        username,
        locale,
        theme,
        otpBase32,
        otpAuthUrl,
        otpVerified,
        passwordIsExpired
      ];
}
