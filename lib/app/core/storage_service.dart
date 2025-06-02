import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:pomodoro/app/core/constants.dart';

class StorageService extends GetxService {
  late GetStorage _storage;

  Future<StorageService> init() async {
    _storage = GetStorage();
    return this;
  }

  // Token methods
  Future<void> saveToken(String token) async {
    _storage.write(AppConstants.storageTokenKey, token);
  }

  Future<String?> getToken() async {
    return _storage.read<String>(AppConstants.storageTokenKey);
  }

  Future<void> deleteToken() async {
    _storage.remove(AppConstants.storageTokenKey);
  }

  // Theme methods
  Future<void> saveThemeMode(String themeMode) async {
    _storage.write(AppConstants.storageThemeKey, themeMode);
  }

  Future<String?> getThemeMode() async {
    return _storage.read<String>(AppConstants.storageThemeKey);
  }

  // Seed color methods
  Future<void> saveSeedColor(int colorValue) async {
    await _storage.write('seed_color', colorValue);
  }

  Future<int?> getSeedColor() async {
    return _storage.read<int>('seed_color');
  }

  // Generic read/write methods
  Future<void> write(String key, String value) async {
    await _storage.write(key, value);
  }

  Future<String?> read(String key) async {
    return _storage.read<String>(key);
  }

  Future<void> remove(String key) async {
    await _storage.remove(key);
  }

  // Clear all data
  Future<void> clearAll() async {
    deleteToken();
  }
}
