// features/auth/domain/entities/user_entity.dart

class OtpEntity {
  final String? otpBase32;
  final String? otpAuthUrl;

  OtpEntity({
    this.otpBase32,
    this.otpAuthUrl,
  });
}
