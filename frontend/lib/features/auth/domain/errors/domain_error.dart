import 'package:flutteractixapp/core/messages/errors/domain_error.dart';

class ShouldLogoutError extends DomainError {}

class RefreshTokenExpiredDomainError extends ShouldLogoutError {
  final String messageKey = 'refreshTokenExpiredError';
}

class InvalidRefreshTokenDomainError extends ShouldLogoutError {
  final String messageKey = 'refreshTokenExpiredError';
}

class RefreshTokenNotFoundDomainError extends ShouldLogoutError {
  final String messageKey = 'refreshTokenExpiredError';
}

class InvalidUsernameOrCodeOrRecoveryCodeDomainError extends DomainError {
  final String messageKey = 'invalidUsernameOrCodeOrRecoveryCodeError';
}

class TwoFactorAuthenticationNotEnabledDomainError extends DomainError {
  final String messageKey = 'twoFactorAuthenticationNotEnabledError';
}

class InvalidUsernameOrRecoveryCodeDomainError extends DomainError {
  final String messageKey = 'invalidUsernameOrRecoveryCodeError';
}

class InvalidUsernameOrPasswordOrRecoveryCodeDomainError extends DomainError {
  final String messageKey = 'invalidUsernameOrPasswordOrRecoveryCodeError';
}

class UserNotFoundDomainError extends DomainError {
  final String messageKey = 'userNotFoundError';
}

class InvalidOneTimePasswordDomainError extends DomainError {
  final String messageKey = 'invalidOneTimePasswordError';
}

class InvalidUsernameOrPasswordDomainError extends DomainError {
  final String messageKey = 'invalidUsernameOrPasswordError';
}

class PasswordMustBeChangedDomainError extends DomainError {
  final String messageKey = 'passwordMustBeChangedError';
}

class UserAlreadyExistingDomainError extends DomainError {
  final String messageKey = 'userAlreadyExistingError';
}

class PasswordNotExpiredDomainError extends DomainError {
  final String messageKey = 'passwordNotExpiredError';
}

class PasswordTooShortError extends DomainError {
  final String messageKey = 'passwordTooShortError';
}

class PasswordNotComplexEnoughError extends DomainError {
  final String messageKey = 'passwordNotComplexEnough';
}

class UsernameWrongSizeError extends DomainError {
  final String messageKey = 'usernameNotRespectingRulesError';
}

class UsernameNotRespectingRulesError extends DomainError {
  final String messageKey = 'usernameWrongSizeError';
}
