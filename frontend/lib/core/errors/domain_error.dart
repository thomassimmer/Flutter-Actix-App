abstract class DomainError implements Exception {
  String getErrorKey();
}

class UnknownDomainError extends DomainError {
  String getErrorKey() {
    return 'unknownError';
  }
}

class InternalServerDomainError extends DomainError {
  String getErrorKey() {
    return 'internalServerError';
  }
}

class InvalidRequestDomainError extends DomainError {
  String getErrorKey() {
    return 'invalidRequestError';
  }
}

class InvalidResponseDomainError extends DomainError {
  String getErrorKey() {
    return 'invalidResponseError';
  }
}

class ForbiddenDomainError extends DomainError {
  String getErrorKey() {
    return 'forbiddenError';
  }
}

class UnauthorizedDomainError extends DomainError {
  String getErrorKey() {
    return 'unauthorizedError';
  }
}
