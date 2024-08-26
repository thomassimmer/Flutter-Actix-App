import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String username;
  final String locale;

  const UserModel({required this.username, required this.locale});

  // Factory constructor to create a UserModel from JSON data
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] as String,
      locale: json['locale'] as String,
    );
  }

  @override
  List<Object?> get props => [username, locale];
}
