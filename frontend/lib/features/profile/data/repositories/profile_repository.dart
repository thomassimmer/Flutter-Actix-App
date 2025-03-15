// features/auth/data/repositories/auth_repository.dart

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:reallystick/core/constants/repositories.dart';
import 'package:reallystick/features/profile/data/models/user_model.dart';

class ProfileRepository extends ApiRepository {
  ProfileRepository({required super.baseUrl});

  Future<UserModel> getProfileInformation(String accessToken) async {
    final url = Uri.parse('$baseUrl/users/me');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);

      return UserModel.fromJson(jsonBody['user']);
    }

    throw Exception(response.body);
  }
}
