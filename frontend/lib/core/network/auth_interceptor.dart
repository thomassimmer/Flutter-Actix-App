import 'package:http_interceptor/http_interceptor.dart';
import 'package:reallystick/features/auth/data/services/auth_service.dart';
import 'package:reallystick/features/auth/data/storage/token_storage.dart';

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
    // Unauthorized, token might be expired
    if (response.statusCode == 401) {
      bool refreshed = await authService.refreshToken();

      // Retry the request with new token
      if (refreshed) {
        String? newAccessToken = await tokenStorage.getAccessToken();

        response.request!.headers['Authorization'] = 'Bearer $newAccessToken';

        final retryResponse = await InterceptedClient.build(interceptors: [
          AuthInterceptor(
              baseUrl: baseUrl,
              authService: authService,
              tokenStorage: tokenStorage)
        ]).send(response.request!);

        return retryResponse;
      }

      // Failed, refresh token might be expired
      else {
        await tokenStorage.deleteTokens();
      }
    }
    return response;
  }
}