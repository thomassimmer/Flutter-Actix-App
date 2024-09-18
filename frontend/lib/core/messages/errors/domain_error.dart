abstract class DomainError implements Exception {
  final String messageKey = 'defaultError';
}

class UnknownDomainError implements DomainError {
  @override
  final String messageKey = 'unknownError';
}

class InternalServerDomainError implements DomainError {
  @override
  final String messageKey = 'internalServerError';
}

class InvalidRequestDomainError implements DomainError {
  @override
  final String messageKey = 'invalidRequestError';
}

class InvalidResponseDomainError implements DomainError {
  @override
  final String messageKey = 'invalidResponseError';
}

class ForbiddenDomainError implements DomainError {
  @override
  final String messageKey = 'forbiddenError';
}

class UnauthorizedDomainError implements DomainError {
  @override
  final String messageKey = 'unauthorizedError';
}
