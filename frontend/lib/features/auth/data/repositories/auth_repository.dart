// features/auth/data/repositories/auth_repository.dart

import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:reallystick/core/constants/repositories.dart';
import 'package:reallystick/core/network/auth_interceptor.dart';
import 'package:reallystick/features/auth/data/models/otp_generation_model.dart';
import 'package:reallystick/features/auth/data/models/user_token_model.dart';
import 'package:reallystick/features/auth/data/services/auth_service.dart';
import 'package:reallystick/features/auth/data/storage/token_storage.dart';

class AuthRepository extends ApiRepository {
  late InterceptedClient client;

  AuthRepository({required super.baseUrl}) {
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

  Future<UserTokenModel> register(
      {required String username,
      required String password,
      required String locale,
      required String theme}) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
        'locale': locale,
        'theme': theme,
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
    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);

      // If otp is not enabled
      if (jsonBody.containsKey('access_token')) {
        return Left(UserTokenModel.fromJson(jsonBody));
      }

      // If otp is enabled
      else if (jsonBody.containsKey('user_id')) {
        return Right(jsonBody['user_id']);
      }
    }

    throw Exception(response.body);
  }

  Future<OtpGenerationModel> generateOtp({required String accessToken}) async {
    final url = Uri.parse('$baseUrl/auth/otp/generate');
    final response = await client.post(
      url,
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
    final response = await client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
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
    final response = await client.post(
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
    final response = await client.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      return jsonBody['otp_enabled'] as bool;
    }

    throw Exception('Failed to disable OTP');
  }
}
