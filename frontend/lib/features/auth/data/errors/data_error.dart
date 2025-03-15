import 'package:flutteractixapp/core/messages/errors/data_error.dart';

class UnauthorizedError extends DataError {}

class RefreshTokenExpiredError extends DataError {}

class InvalidUsernameOrCodeOrRecoveryCodeError extends DataError {}

class TwoFactorAuthenticationNotEnabledError extends DataError {}

class InvalidUsernameOrRecoveryCodeError extends DataError {}

class InvalidUsernameOrPasswordOrRecoveryCodeError extends DataError {}

class UserNotFoundError extends DataError {}

class InvalidOneTimePasswordError extends DataError {}

class InvalidUsernameOrPasswordError extends DataError {}

class PasswordMustBeChangedError extends DataError {}

class UserAlreadyExistingError extends DataError {}

class InvalidRefreshTokenError extends DataError {}

class RefreshTokenNotFoundError extends DataError {}
