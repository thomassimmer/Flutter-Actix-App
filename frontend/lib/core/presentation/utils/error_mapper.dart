import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/core/errors/domain_error.dart';

String getGlobalErrorMessage(BuildContext context, DomainError error) {
  final localizations = AppLocalizations.of(context)!;

  switch (error.getErrorKey()) {
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
    default:
      return localizations.defaultError;
  }
}
