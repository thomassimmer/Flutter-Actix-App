import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String username;
  final bool otpEnabled;
  final bool otpVerified;
  final String? otpBase32;
  final String? otpAuthUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? recoveryCodes;

  const UserModel({
    required this.id,
    required this.username,
    required this.otpEnabled,
    required this.otpVerified,
    this.otpBase32,
    this.otpAuthUrl,
    required this.createdAt,
    required this.updatedAt,
    this.recoveryCodes,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
        id: json['id'] as String,
        username: json['username'] as String,
        otpEnabled: json['otp_enabled'] as bool,
        otpVerified: json['otp_verified'] as bool,
        otpBase32: json['otp_base32'] as String?,
        otpAuthUrl: json['otp_auth_url'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        recoveryCodes: json.containsKey('recovery_codes')
            ? List<String>.from(json['recovery_codes'] as List)
            : null);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'otp_enabled': otpEnabled,
      'otp_verified': otpVerified,
      'otp_base32': otpBase32,
      'otp_auth_url': otpAuthUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        username,
        otpEnabled,
        otpVerified,
        otpBase32,
        otpAuthUrl,
        createdAt,
        updatedAt,
        recoveryCodes
      ];
}
