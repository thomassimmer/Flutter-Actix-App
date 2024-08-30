class UserToken {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final List<String>? recoveryCodes;

  const UserToken(
      {required this.accessToken,
      required this.refreshToken,
      required this.expiresIn,
      this.recoveryCodes});
}
