import 'package:flutteractixapp/core/errors/domain_error.dart';

class RefreshTokenExpiredDomainError extends DomainError {
  String getErrorKey() {
    return 'refreshTokenExpiredError';
  }
}

class InvalidUsernameOrCodeOrRecoveryCodeDomainError extends DomainError {
  String getErrorKey() {
    return 'invalidUsernameOrCodeOrRecoveryCodeError';
  }
}

class TwoFactorAuthenticationNotEnabledDomainError extends DomainError {
  String getErrorKey() {
    return 'twoFactorAuthenticationNotEnabledError';
  }
}

class InvalidUsernameOrRecoveryCodeDomainError extends DomainError {
  String getErrorKey() {
    return 'invalidUsernameOrRecoveryCodeError';
  }
}

class InvalidUsernameOrPasswordOrRecoveryCodeDomainError extends DomainError {
  String getErrorKey() {
    return 'invalidUsernameOrPasswordOrRecoveryCodeError';
  }
}

class UserNotFoundDomainError extends DomainError {
  String getErrorKey() {
    return 'userNotFoundError';
  }
}

class InvalidOneTimePasswordDomainError extends DomainError {
  String getErrorKey() {
    return 'invalidOneTimePasswordError';
  }
}

class InvalidUsernameOrPasswordDomainError extends DomainError {
  String getErrorKey() {
    return 'invalidUsernameOrPasswordError';
  }
}

class PasswordMustBeChangedDomainError extends DomainError {
  String getErrorKey() {
    return 'passwordMustBeChangedError';
  }
}

class UserAlreadyExistingDomainError extends DomainError {
  String getErrorKey() {
    return 'userAlreadyExistingError';
  }
}

class PasswordNotExpiredDomainError extends DomainError {
  String getErrorKey() {
    return 'passwordNotExpiredError';
  }
}

class InvalidRefreshTokenDomainError extends DomainError {
  String getErrorKey() {
    return 'defaultError';
  }
}

class RefreshTokenNotFoundDomainError extends DomainError {
  String getErrorKey() {
    return 'defaultError';
  }
}

class PasswordTooShortError extends DomainError {
  String getErrorKey() {
    return 'passwordTooShortError';
  }
}

class PasswordNotComplexEnoughError extends DomainError {
  String getErrorKey() {
    return 'passwordNotComplexEnough';
  }
}

class UsernameWrongSizeError extends DomainError {
  String getErrorKey() {
    return 'usernameNotRespectingRulesError';
  }
}

class UsernameNotRespectingRulesError extends DomainError {
  String getErrorKey() {
    return 'usernameWrongSizeError';
  }
}
