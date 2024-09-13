import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutteractixapp/core/errors/domain_error.dart';
import 'package:flutteractixapp/features/auth/presentation/utils/error_mapper.dart';

String getProfileErrorMessage(BuildContext context, DomainError error) {
  final localizations = AppLocalizations.of(context)!;

  switch (error.getErrorKey()) {
    case 'passwordNotExpiredError':
      return localizations.passwordNotExpiredError;
    default:
      return getAuthErrorMessage(context, error);
  }
}
