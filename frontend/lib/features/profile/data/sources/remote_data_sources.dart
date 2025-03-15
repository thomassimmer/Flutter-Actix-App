// features/auth/data/repositories/auth_repository.dart

import 'dart:async';
import 'dart:convert';

import 'package:flutteractixapp/core/messages/errors/data_error.dart';
import 'package:flutteractixapp/features/auth/data/errors/data_error.dart';
import 'package:flutteractixapp/features/auth/domain/errors/domain_error.dart';
import 'package:flutteractixapp/features/profile/data/errors/data_error.dart';
import 'package:flutteractixapp/features/profile/data/models/profile_model.dart';
import 'package:flutteractixapp/features/profile/data/models/profile_request_model.dart';
import 'package:http_interceptor/http_interceptor.dart';

class ProfileRemoteDataSource {
  final InterceptedClient apiClient;
  final String baseUrl;

  ProfileRemoteDataSource({required this.apiClient, required this.baseUrl});

  Future<ProfileModel> getProfileInformation() async {
    final url = Uri.parse('$baseUrl/users/me');
    final response = await apiClient.get(
      url,
    );

    final jsonBody = json.decode(response.body);

    if (response.statusCode == 200) {
      try {
        return ProfileModel.fromJson(jsonBody['user']);
      } catch (e) {
        throw ParsingError();
      }
    }

    if (response.statusCode == 401) {
      throw UnauthorizedError();
    }

    if (response.statusCode == 500) {
      throw InternalServerError();
    }

    throw UnknownError();
  }

  Future<ProfileModel> postProfileInformation(
      UpdateProfileRequestModel profile) async {
    final url = Uri.parse('$baseUrl/users/me');
    final response = await apiClient.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(profile.toJson()),
    );

    final jsonBody = json.decode(response.body);

    if (response.statusCode == 200) {
      try {
        return ProfileModel.fromJson(jsonBody['user']);
      } catch (e) {
        throw ParsingError();
      }
    }

    if (response.statusCode == 401) {
      throw UnauthorizedError();
    }

    if (response.statusCode == 500) {
      throw InternalServerError();
    }

    throw UnknownError();
  }

  Future<ProfileModel> setPassword(
      SetPasswordRequestModel setPasswordRequestModel) async {
    final url = Uri.parse('$baseUrl/users/set-password');
    final response = await apiClient.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(setPasswordRequestModel.toJson()),
    );

    final jsonBody = json.decode(response.body);
    final responseCode = jsonBody['code'] as String;

    if (response.statusCode == 200) {
      try {
        return ProfileModel.fromJson(jsonBody['user']);
      } catch (e) {
        throw ParsingError();
      }
    }

    if (response.statusCode == 401) {
      if (responseCode == 'PASSWORD_TOO_SHORT') {
        throw PasswordTooShortError();
      }
      if (responseCode == 'PASSWORD_TOO_WEAK') {
        throw PasswordNotComplexEnoughError();
      }

      throw UnauthorizedError();
    }

    if (response.statusCode == 403) {
      if (responseCode == 'PASSWORD_NOT_EXPIRED') {
        throw PasswordNotExpiredError();
      }

      throw ForbiddenError();
    }

    if (response.statusCode == 500) {
      throw InternalServerError();
    }

    throw UnknownError();
  }

  Future<ProfileModel> updatePassword(
      UpdatePasswordRequestModel updatePasswordRequestModel) async {
    final url = Uri.parse('$baseUrl/users/update-password');
    final response = await apiClient.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(updatePasswordRequestModel.toJson()),
    );

    final jsonBody = json.decode(response.body);
    final responseCode = jsonBody['code'] as String;

    if (response.statusCode == 200) {
      try {
        return ProfileModel.fromJson(jsonBody['user']);
      } catch (e) {
        throw ParsingError();
      }
    }

    if (response.statusCode == 401) {
      if (responseCode == 'INVALID_USERNAME_OR_PASSWORD') {
        throw InvalidUsernameOrPasswordError();
      }

      if (responseCode == 'PASSWORD_TOO_SHORT') {
        throw PasswordTooShortError();
      }
      if (responseCode == 'PASSWORD_TOO_WEAK') {
        throw PasswordNotComplexEnoughError();
      }

      throw UnauthorizedError();
    }

    if (response.statusCode == 500) {
      throw InternalServerError();
    }

    throw UnknownError();
  }
}
