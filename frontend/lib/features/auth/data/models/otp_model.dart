import 'package:equatable/equatable.dart';

class OtpModel extends Equatable {
  final String? otpBase32;
  final String? otpAuthUrl;

  const OtpModel({
    this.otpBase32,
    this.otpAuthUrl,
  });

  // Factory constructor to create a UserModel from JSON data
  factory OtpModel.fromJson(Map<String, dynamic> json) {
    return OtpModel(
      otpBase32: json['otp_base32'] as String?,
      otpAuthUrl: json['otp_auth_url'] as String?,
    );
  }

  // Method to convert UserModel to JSON, useful for requests
  Map<String, dynamic> toJson() {
    return {
      'otp_base32': otpBase32,
      'otp_auth_url': otpAuthUrl,
    };
  }

  @override
  List<Object?> get props => [
        otpBase32,
        otpAuthUrl,
      ];
}
