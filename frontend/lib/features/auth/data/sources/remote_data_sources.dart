import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutteractixapp/core/messages/errors/data_error.dart';
import 'package:flutteractixapp/features/auth/data/errors/data_error.dart';
import 'package:flutteractixapp/features/auth/data/models/otp_model.dart';
import 'package:flutteractixapp/features/auth/data/models/otp_request_model.dart';
import 'package:flutteractixapp/features/auth/data/models/user_token_model.dart';
import 'package:flutteractixapp/features/auth/data/models/user_token_request_model.dart';
import 'package:flutteractixapp/features/auth/domain/errors/domain_error.dart';
import 'package:http_interceptor/http_interceptor.dart';

class AuthRemoteDataSource {
  final InterceptedClient apiClient;
  final String baseUrl;

  AuthRemoteDataSource({required this.apiClient, required this.baseUrl});

  Future<UserTokenModel> signup(
      RegisterUserRequestModel registerUserRequestModel) async {
    final url = Uri.parse('$baseUrl/auth/signup');
    final response = await apiClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(registerUserRequestModel.toJson()),
    );

    final jsonBody = json.decode(response.body);
    final responseCode = jsonBody['code'] as String;

    if (response.statusCode == 201) {
      try {
        return UserTokenModel.fromJson(jsonBody);
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
      if (responseCode == 'USERNAME_WRONG_SIZE') {
        throw UsernameWrongSizeError();
      }
      if (responseCode == 'USERNAME_NOT_RESPECTING_RULES') {
        throw UsernameNotRespectingRulesError();
      }
    }

    if (response.statusCode == 409) {
      if (responseCode == 'USER_ALREADY_EXISTS') {
        throw UserAlreadyExistingError();
      }
    }

    if (response.statusCode == 500) {
      throw InternalServerError();
    }

    throw UnknownError();
  }

  Future<Either<UserTokenModel, String>> login(
      LoginUserRequestModel loginUserRequestModel) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final response = await apiClient.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(loginUserRequestModel.toJson()),
    );

    final jsonBody = json.decode(response.body);
    final responseCode = jsonBody['code'] as String;

    if (response.statusCode == 200) {
      try {
        if (responseCode == 'USER_LOGGED_IN_WITHOUT_OTP') {
          return Left(UserTokenModel.fromJson(jsonBody));
        }

        if (responseCode == 'USER_LOGS_IN_WITH_OTP_ENABLED') {
          return Right(jsonBody['user_id']);
        }

        throw ParsingError();
      } catch (e) {
        throw ParsingError();
      }
    }

    if (response.statusCode == 401) {
      if (responseCode == 'INVALID_USERNAME_OR_PASSWORD') {
        throw InvalidUsernameOrPasswordError();
      }

      throw UnauthorizedError();
    }

    if (response.statusCode == 403) {
      if (responseCode == 'PASSWORD_MUST_BE_CHANGED') {
        throw PasswordMustBeChangedError();
      }

      throw ForbiddenError();
    }

    if (response.statusCode == 500) {
      throw InternalServerError();
    }

    throw UnknownError();
  }

  Future<TwoFactorAuthenticationConfigModel>
      generateTwoFactorAuthenticationConfig() async {
    final url = Uri.parse('$baseUrl/auth/otp/generate');
    final response = await apiClient.get(
      url,
    );

    final jsonBody = json.decode(response.body);

    if (response.statusCode == 200) {
      try {
        return TwoFactorAuthenticationConfigModel.fromJson(jsonBody);
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

  Future<bool> verifyOneTimePassword(
      VerifyOneTimePasswordRequestModel verifyOneTimePasswordRequestModel) async {
    final url = Uri.parse('$baseUrl/auth/otp/verify');
    final response = await apiClient.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(verifyOneTimePasswordRequestModel.toJson()),
    );

    final jsonBody = json.decode(response.body);
    final responseCode = jsonBody['code'] as String;

    if (response.statusCode == 200) {
      try {
        return jsonBody['otp_verified'] as bool;
      } catch (e) {
        throw ParsingError();
      }
    }

    if (response.statusCode == 401) {
      if (responseCode == 'INVALID_ONE_TIME_PASSWORD') {
        throw InvalidOneTimePasswordError();
      }

      throw UnauthorizedError();
    }

    if (response.statusCode == 500) {
      throw InternalServerError();
    }

    throw UnknownError();
  }

  Future<UserTokenModel> validateOneTimePassword(
      ValidateOneTimePasswordRequestModel validateOneTimePasswordRequestModel) async {
    final url = Uri.parse('$baseUrl/auth/otp/validate');
    final response = await apiClient.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(validateOneTimePasswordRequestModel.toJson()),
    );

    final jsonBody = json.decode(response.body);
    final responseCode = jsonBody['code'] as String;

    if (response.statusCode == 200) {
      try {
        return UserTokenModel.fromJson(jsonBody);
      } catch (e) {
        throw ParsingError();
      }
    }

    if (response.statusCode == 401) {
      if (responseCode == 'InvalidOneTimePassword') {
        throw InvalidOneTimePasswordError();
      }

      throw UnauthorizedError();
    }

    if (response.statusCode == 404) {
      if (responseCode == 'USER_NOT_FOUND') {
        throw UserNotFoundError();
      }
    }

    if (response.statusCode == 500) {
      throw InternalServerError();
    }

    throw UnknownError();
  }

  Future<bool> disableTwoFactorAuthentication() async {
    final url = Uri.parse('$baseUrl/auth/otp/disable');
    final response = await apiClient.get(url);

    final jsonBody = json.decode(response.body);

    if (response.statusCode == 200) {
      try {
        return jsonBody['two_fa_enabled'] as bool;
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

  Future<bool> checkIfAccountHasTwoFactorAuthenticationEnabled(
    CheckIfAccountHasTwoFactorAuthenticationEnabledRequestModel
        checkIfAccountHasTwoFactorAuthenticationEnabledRequestModel,
  ) async {
    final url = Uri.parse('$baseUrl/users/is-otp-enabled');
    final response = await apiClient.post(url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(checkIfAccountHasTwoFactorAuthenticationEnabledRequestModel.toJson()));

    final jsonBody = json.decode(response.body);

    if (response.statusCode == 200) {
      try {
        return jsonBody['otp_enabled'] as bool;
      } catch (e) {
        throw ParsingError();
      }
    }

    if (response.statusCode == 500) {
      throw InternalServerError();
    }

    throw UnknownError();
  }

  Future<UserTokenModel> recoverAccountWithTwoFactorAuthenticationAndPassword(
      RecoverAccountWithRecoveryCodeAndPasswordRequestModel
          recoverAccountWithRecoveryCodeAndPasswordRequestModel) async {
    final url = Uri.parse('$baseUrl/auth/recover-using-password');
    final response = await apiClient.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(
          recoverAccountWithRecoveryCodeAndPasswordRequestModel.toJson()),
    );

    final jsonBody = json.decode(response.body);
    final responseCode = jsonBody['code'] as String;

    if (response.statusCode == 200) {
      try {
        return UserTokenModel.fromJson(jsonBody);
      } catch (e) {
        throw ParsingError();
      }
    }

    if (response.statusCode == 401) {
      if (responseCode == 'INVALID_USERNAME_OR_PASSWORD_OR_RECOVERY_CODE') {
        throw InvalidUsernameOrPasswordOrRecoveryCodeError();
      }

      throw UnauthorizedError();
    }

    if (response.statusCode == 403) {
      if (responseCode == 'TWO_FACTOR_AUTHENTICATION_NOT_ENABLED') {
        throw TwoFactorAuthenticationNotEnabledError();
      }
    }

    if (response.statusCode == 500) {
      throw InternalServerError();
    }

    throw UnknownError();
  }

  Future<UserTokenModel>
      recoverAccountWithTwoFactorAuthenticationAndOneTimePassword(
          RecoverAccountWithRecoveryCodeAndOneTimePasswordRequestModel
              recoverAccountWithRecoveryCodeAndOneTimePasswordRequestModel) async {
    final url = Uri.parse('$baseUrl/auth/recover-using-2fa');
    final response = await apiClient.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json
          .encode(recoverAccountWithRecoveryCodeAndOneTimePasswordRequestModel.toJson()),
    );

    final jsonBody = json.decode(response.body);
    final responseCode = jsonBody['code'] as String;

    if (response.statusCode == 200) {
      try {
        return UserTokenModel.fromJson(jsonBody);
      } catch (e) {
        throw ParsingError();
      }
    }

    if (response.statusCode == 401) {
      if (responseCode == 'INVALID_USERNAME_OR_CODE_OR_RECOVERY_CODE') {
        throw InvalidUsernameOrCodeOrRecoveryCodeError();
      }

      throw UnauthorizedError();
    }

    if (response.statusCode == 403) {
      if (responseCode == 'TWO_FACTOR_AUTHENTICATION_NOT_ENABLED') {
        throw TwoFactorAuthenticationNotEnabledError();
      }
    }

    if (response.statusCode == 500) {
      throw InternalServerError();
    }

    throw UnknownError();
  }

  Future<UserTokenModel> recoverAccountWithoutTwoFactorAuthenticationEnabled(
      RecoverAccountWithRecoveryCodeRequestModel
          recoverAccountWithRecoveryCodeRequestModel) async {
    final url = Uri.parse('$baseUrl/auth/recover');
    final response = await apiClient.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(recoverAccountWithRecoveryCodeRequestModel.toJson()),
    );

    final jsonBody = json.decode(response.body);
    final responseCode = jsonBody['code'] as String;

    if (response.statusCode == 200) {
      try {
        return UserTokenModel.fromJson(jsonBody);
      } catch (e) {
        throw ParsingError();
      }
    }

    if (response.statusCode == 401) {
      if (responseCode == 'INVALID_USERNAME_OR_RECOVERY_CODE') {
        throw InvalidUsernameOrRecoveryCodeError();
      }

      throw UnauthorizedError();
    }

    if (response.statusCode == 500) {
      throw InternalServerError();
    }

    throw UnknownError();
  }
}
