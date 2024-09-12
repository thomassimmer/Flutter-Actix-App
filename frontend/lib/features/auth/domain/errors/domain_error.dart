import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/core/errors/domain_error.dart';

class UnauthorizedDomainError extends DomainError {
  String display(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.unauthorizedError;
  }
}

class RefreshTokenExpiredDomainError extends DomainError {
  String display(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.refreshTokenExpiredError;
  }
}

class InvalidUsernameOrCodeOrRecoveryCodeDomainError extends DomainError {
  String display(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.invalidUsernameOrCodeOrRecoveryCodeError;
  }
}

class TwoFactorAuthenticationNotEnabledDomainError extends DomainError {
  String display(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.twoFactorAuthenticationNotEnabledError;
  }
}

class InvalidUsernameOrRecoveryCodeDomainError extends DomainError {
  String display(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.invalidUsernameOrRecoveryCodeError;
  }
}

class InvalidUsernameOrPasswordOrRecoveryCodeDomainError extends DomainError {
  String display(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.invalidUsernameOrPasswordOrRecoveryCodeError;
  }
}

class UserNotFoundDomainError extends DomainError {
  String display(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.userNotFoundError;
  }
}

class InvalidOneTimePasswordDomainError extends DomainError {
  String display(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.invalidOneTimePasswordError;
  }
}

class InvalidUsernameOrPasswordDomainError extends DomainError {
  String display(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.invalidUsernameOrPasswordError;
  }
}

class PasswordMustBeChangedDomainError extends DomainError {
  String display(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.passwordMustBeChangedError;
  }
}

class UserAlreadyExistingDomainError extends DomainError {
  String display(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.userAlreadyExistingError;
  }
}

class PasswordNotExpiredDomainError extends DomainError {
  String display(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.passwordNotExpiredError;
  }
}

class InvalidRefreshTokenDomainError extends DomainError {
  String display(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.defaultError;
  }
}

class RefreshTokenNotFoundDomainError extends DomainError {
  String display(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.defaultError;
  }
}

class PasswordTooShortError extends DomainError {
  String display(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.passwordTooShortError;
  }
}

class PasswordNotComplexEnoughError extends DomainError {
  String display(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.passwordNotComplexEnough;
  }
}

class UsernameWrongSizeError extends DomainError {
  String display(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.usernameNotRespectingRulesError;
  }
}

class UsernameNotRespectingRulesError extends DomainError {
  String display(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.usernameWrongSizeError;
  }
}
