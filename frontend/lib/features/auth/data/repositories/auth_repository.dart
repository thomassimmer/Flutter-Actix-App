// features/auth/data/repositories/auth_repository.dart

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:reallystick/features/auth/data/models/otp_model.dart';

import '../models/user_model.dart';

class AuthRepository {
  final String baseUrl;

  AuthRepository({required this.baseUrl});

  Future<UserModel> register({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);

      final Map<String, dynamic> userMap = {
        ...jsonBody['user'],
        'recovery_codes': jsonBody['recovery_codes'],
      };

      return UserModel.fromJson(userMap);
    } else if (response.statusCode == 409) {
      // Handle user already exists scenario
      throw Exception('User already exists');
    } else {
      throw Exception('Failed to register user');
    }
  }

  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return UserModel.fromJson(jsonBody['user']);
    } else {
      throw Exception('Invalid username or password');
    }
  }

  Future<OtpModel> generateOtp({
    required String userId,
    required String username,
  }) async {
    final url = Uri.parse('$baseUrl/auth/otp/generate');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'username': username,
      }),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return OtpModel.fromJson(jsonBody);
    } else {
      throw Exception('Failed to generate OTP');
    }
  }

  Future<UserModel> verifyOtp({
    required String userId,
    required String token,
  }) async {
    final url = Uri.parse('$baseUrl/auth/otp/verify');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'token': token,
      }),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return UserModel.fromJson(jsonBody['user']);
    } else {
      throw Exception('Failed to verify OTP');
    }
  }

  Future<void> disableOtp({
    required String userId,
  }) async {
    final url = Uri.parse('$baseUrl/auth/otp/disable');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to disable OTP');
    }
  }
}
