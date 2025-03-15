class UserToken {
  final String accessToken;
  final String refreshToken;
  final List<String>? recoveryCodes;

  const UserToken(
      {required this.accessToken,
      required this.refreshToken,
      this.recoveryCodes});
}
