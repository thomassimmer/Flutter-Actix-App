class UpdateUserRequestModel {
  final String username;
  final String locale;
  final String theme;

  const UpdateUserRequestModel(
      {required this.username, required this.locale, required this.theme});

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'locale': locale,
      'theme': theme,
    };
  }
}
