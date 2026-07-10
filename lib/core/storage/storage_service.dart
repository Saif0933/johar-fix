import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final FlutterSecureStorage _storage;

  // Private constructor
  StorageService._internal(this._storage);

  // Singleton instance
  static final StorageService _instance = StorageService._internal(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  );

  static StorageService get instance => _instance;

  // Generic write
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // Generic read
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  // Generic delete
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  // Clear all cached credentials (e.g. on logout/401)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Helper getters/setters for specific credentials
  Future<String?> getUserToken() => read('userToken');
  Future<void> saveUserToken(String token) => write('userToken', token);
  Future<void> deleteUserToken() => delete('userToken');

  Future<String?> getUserDoc() => read('userDoc');
  Future<void> saveUserDoc(String doc) => write('userDoc', doc);
  Future<void> deleteUserDoc() => delete('userDoc');
}
