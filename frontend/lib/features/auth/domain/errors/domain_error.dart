import 'package:flutteractixapp/core/errors/domain_error.dart';

class UnauthorizedDomainError extends DomainError {}

class RefreshTokenExpiredDomainError extends DomainError {}

class InvalidUsernameOrCodeOrRecoveryCodeDomainError extends DomainError {}

class TwoFactorAuthenticationNotEnabledDomainError extends DomainError {}

class InvalidUsernameOrRecoveryCodeDomainError extends DomainError {}

class InvalidUsernameOrPasswordOrRecoveryCodeDomainError extends DomainError {}

class UserNotFoundDomainError extends DomainError {}

class InvalidOneTimePasswordDomainError extends DomainError {}

class InvalidUsernameOrPasswordDomainError extends DomainError {}

class PasswordMustBeChangedDomainError extends DomainError {}

class UserAlreadyExistingDomainError extends DomainError {}

class PasswordNotExpiredDomainError extends DomainError {}

class InvalidRefreshTokenDomainError extends DomainError {}

class RefreshTokenNotFoundDomainError extends DomainError {}

class PasswordTooShortError extends DomainError {}

class PasswordNotComplexEnoughError extends DomainError {}

class UsernameWrongSizeError extends DomainError {}

class UsernameNotRespectingRulesError extends DomainError {}
