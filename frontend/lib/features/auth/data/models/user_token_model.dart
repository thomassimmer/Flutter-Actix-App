import 'package:equatable/equatable.dart';

class UserTokenModel extends Equatable {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final List<String>? recoveryCodes;

  const UserTokenModel(
      {required this.accessToken,
      required this.refreshToken,
      required this.expiresIn,
      this.recoveryCodes});

  // Factory constructor to create a UserModel from JSON data
  factory UserTokenModel.fromJson(Map<String, dynamic> json) {
    return UserTokenModel(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        expiresIn: json['expires_in'] as int,
        recoveryCodes: json.containsKey('recovery_codes')
            ? List<String>.from(json['recovery_codes'] as List)
            : null);
  }

  @override
  List<Object?> get props =>
      [accessToken, refreshToken, expiresIn, recoveryCodes];
}
