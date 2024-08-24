import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String username;

  const UserModel({required this.username});

  // Factory constructor to create a UserModel from JSON data
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] as String,
    );
  }

  @override
  List<Object?> get props => [username];
}
