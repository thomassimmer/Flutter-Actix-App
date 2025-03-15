abstract class DomainError implements Exception {}

class UnknownDomainError extends DomainError {}

class InternalServerDomainError extends DomainError {}

class InvalidRequestDomainError extends DomainError {}

class InvalidResponseDomainError extends DomainError {}

class ForbiddenDomainError extends DomainError {}
