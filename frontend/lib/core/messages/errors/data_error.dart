abstract class DataError implements Exception {}

class ParsingError extends DataError {}

class RequestError extends DataError {}

class SerializingError extends DataError {}

class UnknownError extends DataError {}

class InternalServerError extends DataError {}

class ForbiddenError extends DataError {}
