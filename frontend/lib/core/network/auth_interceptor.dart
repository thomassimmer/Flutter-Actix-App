import 'dart:convert';

import 'package:flutteractixapp/features/auth/data/services/auth_service.dart';
import 'package:flutteractixapp/features/auth/data/storage/token_storage.dart';
import 'package:http_interceptor/http_interceptor.dart';

class AuthInterceptor extends InterceptorContract {
  final AuthService authService;
  final TokenStorage tokenStorage;
  final String baseUrl;

  AuthInterceptor(
      {required this.authService,
      required this.tokenStorage,
      required this.baseUrl});

  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    String? accessToken = await tokenStorage.getAccessToken();

    if (accessToken != null) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }

    return request;
  }

  @override
  Future<BaseResponse> interceptResponse(
      {required BaseResponse response}) async {
    if (response is Response) {
      final jsonBody = json.decode(response.body) as Map<String, dynamic>;
      final responseCode = jsonBody['code'] as String?;

      if (response.statusCode == 401 &&
          responseCode == 'ACCESS_TOKEN_EXPIRED') {
        await authService.refreshToken();

        // Retry the request with a new token
        String? newAccessToken = await tokenStorage.getAccessToken();

        // Retry logic: Update the header with the new token and retry the request
        response.request!.headers['Authorization'] = 'Bearer $newAccessToken';

        final retryResponse = await InterceptedClient.build(interceptors: [
          AuthInterceptor(
            baseUrl: baseUrl,
            authService: authService,
            tokenStorage: tokenStorage,
          ),
        ]).send(response.request!);

        return retryResponse;
      }
    }

    return response;
  }
}
