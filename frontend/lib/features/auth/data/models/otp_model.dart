import 'package:equatable/equatable.dart';

class TwoFactorAuthenticationConfigModel extends Equatable {
  final String otpBase32;
  final String otpAuthUrl;

  const TwoFactorAuthenticationConfigModel({
    required this.otpBase32,
    required this.otpAuthUrl,
  });

  // Factory constructor to create a TwoFactorAuthenticationConfigModel from JSON data
  factory TwoFactorAuthenticationConfigModel.fromJson(
      Map<String, dynamic> json) {
    return TwoFactorAuthenticationConfigModel(
      otpBase32: json['otp_base32'] as String,
      otpAuthUrl: json['otp_auth_url'] as String,
    );
  }

  @override
  List<Object?> get props => [
        otpBase32,
        otpAuthUrl,
      ];
}
