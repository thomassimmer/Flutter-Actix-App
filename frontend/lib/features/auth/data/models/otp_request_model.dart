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
