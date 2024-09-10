import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/core/errors/domain_error.dart';
import 'package:flutteractixapp/features/auth/domain/errors/domain_error.dart';

class ErrorMapper {
  final BuildContext context;

  ErrorMapper(this.context);

  String mapFailureToMessage(Exception error) {
    final localizations = AppLocalizations.of(context)!;

    switch (error.runtimeType) {
      case UnknownDomainError:
        return localizations.unknownError;
      case InternalServerDomainError:
        return localizations.internalServerError;
      case UnauthorizedDomainError:
        return localizations.unauthorizedError;
      case RefreshTokenExpiredDomainError:
        return localizations.refreshTokenExpiredError;
      case InvalidRequestDomainError:
        return localizations.invalidRequestError;
      case InvalidResponseDomainError:
        return localizations.invalidResponseError;
      case InvalidUsernameOrCodeOrRecoveryCodeDomainError:
        return localizations.invalidUsernameOrCodeOrRecoveryCodeError;
      case TwoFactorAuthenticationNotEnabledDomainError:
        return localizations.twoFactorAuthenticationNotEnabledError;
      case InvalidUsernameOrRecoveryCodeDomainError:
        return localizations.invalidUsernameOrRecoveryCodeError;
      case InvalidUsernameOrPasswordOrRecoveryCodeDomainError:
        return localizations.invalidUsernameOrPasswordOrRecoveryCodeError;
      case UserNotFoundDomainError:
        return localizations.userNotFoundError;
      case InvalidOneTimePasswordDomainError:
        return localizations.invalidOneTimePasswordError;
      case InvalidUsernameOrPasswordDomainError:
        return localizations.invalidUsernameOrPasswordError;
      case ForbiddenDomainError:
        return localizations.forbiddenError;
      case PasswordMustBeChangedDomainError:
        return localizations.passwordMustBeChangedError;
      case UserAlreadyExistingDomainError:
        return localizations.userAlreadyExistingError;
      case PasswordNotExpiredDomainError:
        return localizations.passwordNotExpiredError;
      case PasswordTooShortError:
        return localizations.passwordTooShortError;
      case PasswordNotComplexEnoughError:
        return localizations.passwordNotComplexEnough;
      default:
        return localizations.defaultError;
    }
  }
}
