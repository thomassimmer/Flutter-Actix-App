// domain/errors/domain_error.dart
import 'package:flutteractixapp/core/errors/domain_error.dart';

class InvalidProfileDomainError extends DomainError {
  InvalidProfileDomainError([String message = 'The profile data is invalid.'])
      : super();

  @override
  List<Object?> get props => [message];
}
