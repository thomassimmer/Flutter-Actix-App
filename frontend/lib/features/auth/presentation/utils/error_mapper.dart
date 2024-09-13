import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/core/errors/domain_error.dart';
import 'package:flutteractixapp/core/presentation/utils/error_mapper.dart';

String getAuthErrorMessage(BuildContext context, DomainError error) {
  final localizations = AppLocalizations.of(context)!;

  switch (error.getErrorKey()) {
    case 'invalidUsernameOrCodeOrRecoveryCodeError':
      return localizations.invalidUsernameOrCodeOrRecoveryCodeError;
    case 'invalidUsernameOrRecoveryCodeError':
      return localizations.invalidUsernameOrRecoveryCodeError;
    case 'invalidUsernameOrPasswordOrRecoveryCodeError':
      return localizations.invalidUsernameOrPasswordOrRecoveryCodeError;
    case 'userNotFoundError':
      return localizations.userNotFoundError;
    case 'invalidOneTimePasswordError':
      return localizations.invalidOneTimePasswordError;
    case 'invalidUsernameOrPasswordError':
      return localizations.invalidUsernameOrPasswordError;
    case 'passwordMustBeChangedError':
      return localizations.passwordMustBeChangedError;
    case 'passwordNotExpiredError':
      return localizations.passwordNotExpiredError;
    case 'passwordTooShortError':
      return localizations.passwordTooShortError;
    case 'passwordNotComplexEnough':
      return localizations.passwordNotComplexEnough;
    case 'refreshTokenExpiredError':
      return localizations.refreshTokenExpiredError;
    case 'twoFactorAuthenticationNotEnabledError':
      return localizations.twoFactorAuthenticationNotEnabledError;
    case 'userAlreadyExistingError':
      return localizations.userAlreadyExistingError;
    case 'usernameNotRespectingRulesError':
      return localizations.usernameNotRespectingRulesError;
    case 'usernameWrongSizeError':
      return localizations.usernameWrongSizeError;
    default:
      return getGlobalErrorMessage(context, error);
  }
}
