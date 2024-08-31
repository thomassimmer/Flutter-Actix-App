import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:reallystick/features/auth/data/errors/data_error.dart';
import 'package:reallystick/features/auth/data/storage/token_storage.dart';

class AuthService {
  final String baseUrl;
  final TokenStorage tokenStorage;

  AuthService({required this.baseUrl, required this.tokenStorage});

  Future<void> refreshToken() async {
    final refreshToken = await tokenStorage.getRefreshToken();

    if (refreshToken == null) {
      throw UnauthorizedError();
    }

    final url = Uri.parse('$baseUrl/auth/refresh');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'refreshToken': refreshToken}),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      final newAccessToken = jsonBody['accessToken'] as String;
      final newRefreshToken = jsonBody['refreshToken'] as String;
      final expiresIn = jsonBody['expiresIn'] as int;

      await tokenStorage.saveTokens(newAccessToken, newRefreshToken, expiresIn);
      return;
    }

    await tokenStorage.deleteTokens();
    throw UnauthorizedError();
  }
}
