import 'package:flutteractixapp/core/utils/user_agent.dart';
import 'package:flutteractixapp/features/auth/data/storage/token_storage.dart';
import 'package:http_interceptor/http_interceptor.dart';

class AuthInterceptor extends InterceptorContract {
  final TokenStorage tokenStorage;
  final String baseUrl;

  AuthInterceptor({required this.tokenStorage, required this.baseUrl});

  @override
  Future<BaseRequest> interceptRequest({required BaseRequest request}) async {
    String? accessToken = await tokenStorage.getAccessToken();

    if (accessToken != null) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }

    final userAgent = await getUserAgent();
    request.headers['X-User-Agent'] = userAgent;

    return request;
  }

  @override
  Future<BaseResponse> interceptResponse(
      {required BaseResponse response}) async {
    return response;
  }
}
