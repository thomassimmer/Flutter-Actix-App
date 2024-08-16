class UserEntity {
  final String id;
  final String username;
  final bool otpEnabled;
  final bool otpVerified;
  final String? otpBase32;
  final String? otpAuthUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String>? recoveryCodes;

  UserEntity({
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
}
