import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:reallystick/features/auth/data/models/otp_generation_model.dart';
import 'package:reallystick/features/auth/data/models/user_token_model.dart';
import 'package:reallystick/features/auth/data/models/user_token_request_model.dart';

class AuthRemoteDataSource {
  final InterceptedClient apiClient;
  final String baseUrl;

  AuthRemoteDataSource({required this.apiClient, required this.baseUrl});

  Future<UserTokenModel> register(
      RegisterUserRequestModel registerUserRequestModel) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final response = await apiClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: registerUserRequestModel.toJson(),
    );
    final jsonBody = json.decode(response.body);

    return UserTokenModel.fromJson(jsonBody);
  }

  Future<Either<UserTokenModel, String>> login(
      LoginUserRequestModel loginUserRequestModel) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final response = await apiClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: loginUserRequestModel.toJson(),
    );

    final jsonBody = json.decode(response.body);

    // If otp is not enabled
    if (jsonBody.containsKey('access_token')) {
      return Left(UserTokenModel.fromJson(jsonBody));
    }

    // If otp is enabled
    else {
      return Right(jsonBody['user_id']);
    }
  }

  Future<OtpGenerationModel> generateOtpConfig(String accessToken) async {
    final url = Uri.parse('$baseUrl/auth/otp/generate');
    final response = await apiClient.post(
      url,
    );
    final jsonBody = json.decode(response.body);

    return OtpGenerationModel.fromJson(jsonBody);
  }

  Future<bool> verifyOtp(VerifyOtpRequestModel verifyOtpRequestModel) async {
    final url = Uri.parse('$baseUrl/auth/otp/verify');
    final response = await apiClient.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: verifyOtpRequestModel.toJson(),
    );
    final jsonBody = json.decode(response.body);

    return jsonBody['otp_verified'] as bool;
  }

  Future<UserTokenModel> validateOtp(
      ValidateOtpRequestModel validateOtpRequestModel) async {
    final url = Uri.parse('$baseUrl/auth/otp/validate');
    final response = await apiClient.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: validateOtpRequestModel.toJson(),
    );
    final jsonBody = json.decode(response.body);

    return UserTokenModel.fromJson(jsonBody);
  }

  Future<bool> disableOtp({
    required String accessToken,
  }) async {
    final url = Uri.parse('$baseUrl/auth/otp/disable');
    final response = await apiClient.get(url);
    final jsonBody = json.decode(response.body);

    return jsonBody['otp_enabled'] as bool;
  }
}
