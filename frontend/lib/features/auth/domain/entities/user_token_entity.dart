class UserTokenEntity {
  final String accessToken;
  final String refreshToken;
  final String expiresIn;
  final String? recoveryCodes;

  const UserTokenEntity(
      {required this.accessToken,
      required this.refreshToken,
      required this.expiresIn,
      this.recoveryCodes});
}
