class User {
  String username;
  String locale;
  String theme;
  String? otpBase32;
  String? otpAuthUrl;
  bool otpVerified;
  bool passwordIsExpired;

  User(
      {required this.username,
      required this.locale,
      required this.theme,
      required this.otpBase32,
      required this.otpAuthUrl,
      required this.otpVerified,
      required this.passwordIsExpired});
}
