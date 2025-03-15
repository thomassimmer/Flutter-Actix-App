class VerifyOtpRequestModel {
  final String code;

  const VerifyOtpRequestModel({
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
    };
  }
}

class ValidateOtpRequestModel {
  final String userId;
  final String code;

  const ValidateOtpRequestModel({
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

class CheckIfOtpEnabledRequestModel {
  final String username;

  const CheckIfOtpEnabledRequestModel({
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

class RecoverAccountWithRecoveryCodeAndOtpRequestModel {
  final String username;
  final String code;
  final String recoveryCode;

  const RecoverAccountWithRecoveryCodeAndOtpRequestModel(
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
