import 'package:equatable/equatable.dart';

// Base class for handling failures in the app.
abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object?> get props => [message];
}
