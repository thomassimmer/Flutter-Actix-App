// features/auth/data/repositories/auth_repository.dart

import 'dart:async';
import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:reallystick/core/constants/repositories.dart';
import 'package:reallystick/core/network/auth_interceptor.dart';
import 'package:reallystick/features/auth/data/services/auth_service.dart';
import 'package:reallystick/features/auth/data/storage/token_storage.dart';
import 'package:reallystick/features/profile/data/models/user_model.dart';
import 'package:reallystick/features/profile/domain/entities/user_entity.dart';

class ProfileRepository extends ApiRepository {
  late InterceptedClient client;

  ProfileRepository({required super.baseUrl}) {
    final tokenStorage = TokenStorage();
    final authService =
        AuthService(baseUrl: baseUrl, tokenStorage: tokenStorage);

    client = InterceptedClient.build(
      interceptors: [
        AuthInterceptor(authService: authService, tokenStorage: tokenStorage)
      ],
      requestTimeout: Duration(seconds: 15),
    );
  }

  Future<UserModel> getProfileInformation(String accessToken) async {
    final url = Uri.parse('$baseUrl/users/me');
    final response = await client.get(
      url,
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);

      return UserModel.fromJson(jsonBody['user']);
    }

    throw Exception(response.body);
  }

  Future<UserModel> postProfileInformation(
      String accessToken, UserEntity profile) async {
    final url = Uri.parse('$baseUrl/users/me');
    final response = await client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'username': profile.username,
        'locale': profile.locale,
        'theme': profile.theme
      }),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);

      return UserModel.fromJson(jsonBody['user']);
    }

    throw Exception(response.body);
  }
}
