import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

abstract class DomainError implements Exception {
  String display(BuildContext context);
}

class UnknownDomainError extends DomainError {
  String display(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.unknownError;
  }
}

class InternalServerDomainError extends DomainError {
  String display(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.internalServerError;
  }
}

class InvalidRequestDomainError extends DomainError {
  String display(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.invalidRequestError;
  }
}

class InvalidResponseDomainError extends DomainError {
  String display(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.invalidResponseError;
  }
}

class ForbiddenDomainError extends DomainError {
  String display(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return localizations.forbiddenError;
  }
}
