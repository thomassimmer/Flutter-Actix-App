abstract class DomainError implements Exception {
  final String messageKey = 'defaultError';
}

class UnknownDomainError extends DomainError {
  final String messageKey = 'unknownError';
}

class InternalServerDomainError extends DomainError {
  final String messageKey = 'internalServerError';
}

class InvalidRequestDomainError extends DomainError {
  final String messageKey = 'invalidRequestError';
}

class InvalidResponseDomainError extends DomainError {
  final String messageKey = 'invalidResponseError';
}

class ForbiddenDomainError extends DomainError {
  final String messageKey = 'forbiddenError';
}

class UnauthorizedDomainError extends DomainError {
  final String messageKey = 'unauthorizedError';
}
