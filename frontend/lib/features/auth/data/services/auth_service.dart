import 'dart:convert';

import 'package:flutteractixapp/core/messages/errors/data_error.dart';
import 'package:flutteractixapp/features/auth/data/errors/data_error.dart';
import 'package:flutteractixapp/features/auth/data/storage/token_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final String baseUrl;
  final TokenStorage tokenStorage;

  AuthService({required this.baseUrl, required this.tokenStorage});

  Future<void> refreshToken() async {
    final refreshToken = await tokenStorage.getRefreshToken();

    if (refreshToken == null) {
      throw RefreshTokenNotFoundError();
    }

    final url = Uri.parse('$baseUrl/auth/refresh-token');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refresh_token': refreshToken}),
    );
    final jsonBody = json.decode(response.body);
    final responseCode = jsonBody['code'] as String;

    if (response.statusCode == 200) {
      final newAccessToken = jsonBody['access_token'] as String;

      await tokenStorage.saveTokens(newAccessToken, refreshToken);
      return;
    }

    await tokenStorage.deleteTokens();

    if (response.statusCode == 401) {
      if (responseCode == 'REFRESH_TOKEN_EXPIRED') {
        throw RefreshTokenExpiredError();
      } else if (responseCode == 'INVALID_REFRESH_TOKEN') {
        throw InvalidRefreshTokenError();
      }

      throw UnauthorizedError();
    }

    if (response.statusCode == 500) {
      throw InternalServerError();
    }

    throw UnknownError();
  }
}
