import 'package:flutteractixapp/core/messages/errors/domain_error.dart';

class ShouldLogoutError extends DomainError {}

class RefreshTokenExpiredDomainError implements ShouldLogoutError {
  @override
  final String messageKey = 'refreshTokenExpiredError';
}

class InvalidRefreshTokenDomainError implements ShouldLogoutError {
  @override
  final String messageKey = 'refreshTokenExpiredError';
}

class RefreshTokenNotFoundDomainError implements ShouldLogoutError {
  @override
  final String messageKey = 'refreshTokenExpiredError';
}

class InvalidUsernameOrCodeOrRecoveryCodeDomainError implements DomainError {
  @override
  final String messageKey = 'invalidUsernameOrCodeOrRecoveryCodeError';
}

class TwoFactorAuthenticationNotEnabledDomainError implements DomainError {
  @override
  final String messageKey = 'twoFactorAuthenticationNotEnabledError';
}

class InvalidUsernameOrRecoveryCodeDomainError implements DomainError {
  @override
  final String messageKey = 'invalidUsernameOrRecoveryCodeError';
}

class InvalidUsernameOrPasswordOrRecoveryCodeDomainError
    implements DomainError {
  @override
  final String messageKey = 'invalidUsernameOrPasswordOrRecoveryCodeError';
}

class UserNotFoundDomainError implements DomainError {
  @override
  final String messageKey = 'userNotFoundError';
}

class InvalidOneTimePasswordDomainError implements DomainError {
  @override
  final String messageKey = 'invalidOneTimePasswordError';
}

class InvalidUsernameOrPasswordDomainError implements DomainError {
  @override
  final String messageKey = 'invalidUsernameOrPasswordError';
}

class PasswordMustBeChangedDomainError implements DomainError {
  @override
  final String messageKey = 'passwordMustBeChangedError';
}

class UserAlreadyExistingDomainError implements DomainError {
  @override
  final String messageKey = 'userAlreadyExistingError';
}

class PasswordTooShortError implements DomainError {
  @override
  final String messageKey = 'passwordTooShortError';
}

class PasswordNotComplexEnoughError implements DomainError {
  @override
  final String messageKey = 'passwordNotComplexEnough';
}

class UsernameWrongSizeError implements DomainError {
  @override
  final String messageKey = 'usernameNotRespectingRulesError';
}

class UsernameNotRespectingRulesError implements DomainError {
  @override
  final String messageKey = 'usernameWrongSizeError';
}
