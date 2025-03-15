class TwoFactorAuthenticationConfig {
  final String otpBase32;
  final String otpAuthUrl;

  const TwoFactorAuthenticationConfig({
    required this.otpBase32,
    required this.otpAuthUrl,
  });
}
