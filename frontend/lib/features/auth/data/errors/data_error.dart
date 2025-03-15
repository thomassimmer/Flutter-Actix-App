import 'package:reallystick/core/errors/data_error.dart';

class UnauthorizedError extends DataError {
  UnauthorizedError([String message = 'You are not authenticated']) : super();

  @override
  List<Object?> get props => [message];
}
