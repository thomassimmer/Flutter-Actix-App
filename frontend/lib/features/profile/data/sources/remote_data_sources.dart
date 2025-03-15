// features/auth/data/repositories/auth_repository.dart

import 'dart:async';
import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:reallystick/core/errors/data_error.dart';
import 'package:reallystick/features/profile/data/models/user_model.dart';
import 'package:reallystick/features/profile/data/models/user_request_model.dart';

class ProfileRemoteDataSource {
  final InterceptedClient apiClient;
  final String baseUrl;

  ProfileRemoteDataSource({required this.apiClient, required this.baseUrl});

  Future<UserModel> getProfileInformation(String accessToken) async {
    final url = Uri.parse('$baseUrl/users/me');
    final response = await apiClient.get(
      url,
    );

    if (response.statusCode == 200) {
      try {
        final jsonBody = json.decode(response.body);

        return UserModel.fromJson(jsonBody['user']);
      } catch (e) {
        throw ParsingError('Failed to parse response data: ${e.toString()}');
      }
    } else {
      throw NetworkError('Failed with status code: ${response.statusCode}');
    }
  }

  Future<UserModel> postProfileInformation(
      String accessToken, UpdateUserRequestModel profile) async {
    final url = Uri.parse('$baseUrl/users/me');
    final response = await apiClient.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(profile.toJson()),
    );

    if (response.statusCode == 200) {
      try {
        final jsonBody = json.decode(response.body);

        return UserModel.fromJson(jsonBody['user']);
      } catch (e) {
        throw ParsingError('Failed to parse response data: ${e.toString()}');
      }
    } else {
      throw NetworkError('Failed with status code: ${response.statusCode}');
    }
  }
}
