import 'dart:convert';

import 'package:flutteractixapp/features/auth/data/services/auth_service.dart';
import 'package:http_interceptor/http_interceptor.dart';

class ExpiredTokenRetryPolicy extends RetryPolicy {
  final AuthService authService;

  ExpiredTokenRetryPolicy({required this.authService});

  @override
  int maxRetryAttempts = 2;

  @override
  Future<bool> shouldAttemptRetryOnResponse(BaseResponse response) async {
    if (response is Response) {
      final jsonBody = json.decode(response.body) as Map<String, dynamic>;
      final responseCode = jsonBody['code'] as String?;

      if (response.statusCode == 401 &&
          (responseCode == 'ACCESS_TOKEN_EXPIRED' ||
              responseCode == 'INVALID_ACCESS_TOKEN')) {
        await authService.refreshToken();

        return true;
      }
    }

    return false;
  }
}
