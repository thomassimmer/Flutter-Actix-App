// features/auth/data/repositories/auth_repository.dart

import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:reallystick/features/auth/data/models/otp_generation_model.dart';
import 'package:reallystick/features/auth/data/models/user_token_model.dart';

class AuthRepository {
  final String baseUrl;

  AuthRepository({required this.baseUrl});

  Future<UserTokenModel> register({
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

      return UserTokenModel.fromJson(jsonBody);
    }

    throw Exception(response.body);
  }

  Future<Either<UserTokenModel, String>> login({
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

      if (jsonBody.containsKey('access_token')) {
        return Left(UserTokenModel.fromJson(jsonBody));
      } else if (jsonBody.containsKey('user_id')) {
        return Right(jsonBody['user_id']);
      }
    }

    throw Exception(response.body);
  }

  Future<OtpGenerationModel> generateOtp({required String accessToken}) async {
    final url = Uri.parse('$baseUrl/auth/otp/generate');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);

      return OtpGenerationModel.fromJson(jsonBody);
    }

    throw Exception('Failed to generate OTP');
  }

  Future<bool> verifyOtp({
    required String accessToken,
    required String code,
  }) async {
    final url = Uri.parse('$baseUrl/auth/otp/verify');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: json.encode({
        'code': code,
      }),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return jsonBody['otp_verified'] as bool;
    }

    throw Exception('Failed to verify OTP');
  }

  Future<UserTokenModel> validateOtp({
    required String userId,
    required String code,
  }) async {
    final url = Uri.parse('$baseUrl/auth/otp/validate');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'user_id': userId,
        'code': code,
      }),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return UserTokenModel.fromJson(jsonBody);
    }

    throw Exception('Failed to verify OTP');
  }

  Future<bool> disableOtp({
    required String accessToken,
  }) async {
    final url = Uri.parse('$baseUrl/auth/otp/disable');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return jsonBody['otp_enabled'] as bool;
    }

    throw Exception('Failed to disable OTP');
  }
}
