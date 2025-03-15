import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String username;
  final String locale;
  final String theme;

  const UserModel(
      {required this.username, required this.locale, required this.theme});

  // Factory constructor to create a UserModel from JSON data
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
        username: json['username'] as String,
        locale: json['locale'] as String,
        theme: json['theme'] as String);
  }

  @override
  List<Object?> get props => [username, locale, theme];
}
