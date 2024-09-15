class UpdateProfileRequestModel {
  final String username;
  final String locale;
  final String theme;

  const UpdateProfileRequestModel(
      {required this.username, required this.locale, required this.theme});

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'locale': locale,
      'theme': theme,
    };
  }
}

class SetPasswordRequestModel {
  final String newPassword;

  const SetPasswordRequestModel({required this.newPassword});

  Map<String, dynamic> toJson() {
    return {
      'new_password': newPassword,
    };
  }
}

class UpdatePasswordRequestModel {
  final String currentPassword;
  final String newPassword;

  const UpdatePasswordRequestModel(
      {required this.currentPassword, required this.newPassword});

  Map<String, dynamic> toJson() {
    return {
      'current_password': currentPassword,
      'new_password': newPassword,
    };
  }
}
