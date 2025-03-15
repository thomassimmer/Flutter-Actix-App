import 'package:http_interceptor/http_interceptor.dart';
import 'package:reallystick/features/auth/data/services/auth_service.dart';
import 'package:reallystick/features/auth/data/storage/token_storage.dart';

class AuthInterceptor extends InterceptorContract {
  final AuthService authService;
  final TokenStorage tokenStorage;

  AuthInterceptor({required this.authService, required this.tokenStorage});

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
    if (response.statusCode == 401) {
      // Unauthorized, token might be expired
      bool refreshed = await authService.refreshToken();
      if (refreshed) {
        // Retry the request with new token
        String? newAccessToken = await tokenStorage.getAccessToken();
        response.request!.headers['Authorization'] = 'Bearer $newAccessToken';

        final retryResponse = await InterceptedClient.build(interceptors: [
          AuthInterceptor(authService: authService, tokenStorage: tokenStorage)
        ]).send(response.request!);
        return retryResponse;
      } else {
        await tokenStorage.deleteTokens();
      }
    }
    return response;
  }
}
