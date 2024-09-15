import 'package:equatable/equatable.dart';

class OtpGenerationModel extends Equatable {
  final String otpBase32;
  final String otpAuthUrl;

  const OtpGenerationModel({
    required this.otpBase32,
    required this.otpAuthUrl,
  });

  // Factory constructor to create a OtpGenerationModel from JSON data
  factory OtpGenerationModel.fromJson(Map<String, dynamic> json) {
    return OtpGenerationModel(
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
