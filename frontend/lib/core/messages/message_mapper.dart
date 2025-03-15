import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/core/messages/message.dart';

String getTranslatedMessage(BuildContext context, Message message) {
  final localizations = AppLocalizations.of(context)!;

  if (message is ErrorMessage) {
    switch (message.messageKey) {
      // Generic
      case 'unknown_error':
        return localizations.unknownError;
      case 'internalServerError':
        return localizations.internalServerError;
      case 'invalidRequestError':
        return localizations.invalidRequestError;
      case 'invalidResponseError':
        return localizations.invalidResponseError;
      case 'forbiddenError':
        return localizations.forbiddenError;
      case 'unauthorizedError':
        return localizations.unauthorizedError;

      // Auth
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

      // Profile
      case 'passwordNotExpiredError':
        return localizations.passwordNotExpiredError;

      default:
        return localizations.defaultError;
    }
  } else if (message is SuccessMessage) {
    switch (message.messageKey) {
      // Auth
      case 'loginSuccessful':
        return localizations.loginSuccessful;
      case 'logoutSuccessful':
        return localizations.logoutSuccessful;
      case 'validationCodeCorrect':
        return localizations.validationCodeCorrect;

      // Profile
      case 'passwordUpdateSuccessful':
        return localizations.passwordUpdateSuccessful;
      case 'profileUpdateSuccessful':
        return localizations.profileUpdateSuccessful;

      default:
        return localizations.defaultError;
    }
  } else if (message is InfoMessage) {
    switch (message.messageKey) {
      // Auth
      case 'recoveryCodesCopied':
        return localizations.recoveryCodesCopied;
      case 'qrCodeSecretKeyCopied':
        return localizations.qrCodeSecretKeyCopied;

      default:
        return localizations.defaultError;
    }
  } else {
    return localizations.defaultError;
  }
}
