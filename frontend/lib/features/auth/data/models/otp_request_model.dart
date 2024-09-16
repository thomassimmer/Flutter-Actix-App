class VerifyOneTimePasswordRequestModel {
  final String code;

  const VerifyOneTimePasswordRequestModel({
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
    };
  }
}

class ValidateOneTimePasswordRequestModel {
  final String userId;
  final String code;

  const ValidateOneTimePasswordRequestModel({
    required this.userId,
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'code': code,
    };
  }
}

class CheckIfAccountHasTwoFactorAuthenticationEnabledRequestModel {
  final String username;

  const CheckIfAccountHasTwoFactorAuthenticationEnabledRequestModel({
    required this.username,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
    };
  }
}

class RecoverAccountWithRecoveryCodeAndPasswordRequestModel {
  final String username;
  final String password;
  final String recoveryCode;

  const RecoverAccountWithRecoveryCodeAndPasswordRequestModel(
      {required this.username,
      required this.password,
      required this.recoveryCode});

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'recovery_code': recoveryCode,
    };
  }
}

class RecoverAccountWithRecoveryCodeAndOneTimePasswordRequestModel {
  final String username;
  final String code;
  final String recoveryCode;

  const RecoverAccountWithRecoveryCodeAndOneTimePasswordRequestModel(
      {required this.username, required this.code, required this.recoveryCode});

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'code': code,
      'recovery_code': recoveryCode,
    };
  }
}

class RecoverAccountWithRecoveryCodeRequestModel {
  final String username;
  final String recoveryCode;

  const RecoverAccountWithRecoveryCodeRequestModel(
      {required this.username, required this.recoveryCode});

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'recovery_code': recoveryCode,
    };
  }
}
