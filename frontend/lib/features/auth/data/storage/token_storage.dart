import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  final _storage = FlutterSecureStorage();

  Future<void> saveTokens(
      String accessToken, String refreshToken, int expiresIn) async {
    await _storage.write(key: 'accessToken', value: accessToken);
    await _storage.write(key: 'refreshToken', value: refreshToken);
    await _storage.write(key: 'expiresIn', value: expiresIn.toString());
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'accessToken');
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refreshToken');
  }

  Future<void> deleteTokens() async {
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    await _storage.delete(key: 'expiresIn');
  }
}
