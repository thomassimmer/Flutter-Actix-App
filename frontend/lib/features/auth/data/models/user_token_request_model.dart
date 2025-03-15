class RefreshUserTokenRequestModel {
  final String refreshToken;

  const RefreshUserTokenRequestModel({
    required this.refreshToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'refresh_token': refreshToken,
    };
  }
}

class RegisterUserRequestModel {
  final String username;
  final String password;
  final String locale;
  final String theme;

  const RegisterUserRequestModel(
      {required this.username,
      required this.password,
      required this.locale,
      required this.theme});

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'locale': locale,
      'theme': theme,
    };
  }
}

class LoginUserRequestModel {
  final String username;
  final String password;

  const LoginUserRequestModel({
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }
}
