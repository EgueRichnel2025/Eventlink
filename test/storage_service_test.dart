import 'package:flutter_test/flutter_test.dart';
import 'package:eventlink/services/storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Mock implementation of FlutterSecureStorage for testing
class MockFlutterSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _storage = {};

  MockFlutterSecureStorage() : super();

  @override
  Future<String?> read({
    String? key,
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> write({
    required String key,
    String? value,
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    if (value == null) {
      _storage.remove(key);
    } else {
      _storage[key] = value;
    }
  }

  @override
  Future<void> deleteAll({
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    _storage.clear();
  }

  @override
  Future<void> delete({
    String? key,
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    _storage.remove(key!);
  }

  @override
  Future<Map<String, String>> readAll({
    AndroidOptions? aOptions,
    IOSOptions? iOptions,
    LinuxOptions? lOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
  }) async {
    return Map.from(_storage);
  }
}

void main() {
  group('StorageService', () {
    late StorageService storageService;
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      storageService = StorageService(storage: mockStorage);
    });

    tearDown(() async {
      // Clear test data
      await mockStorage.deleteAll();
    });

    test('onboarding completion tracking', () async {
      // Initially, onboarding should not be completed
      expect(await storageService.hasCompletedOnboarding(), false);

      // Mark onboarding as completed
      await storageService.markOnboardingCompleted();

      // Verify it's now completed
      expect(await storageService.hasCompletedOnboarding(), true);
    });

    test('theme preference persistence', () async {
      // Initially, no theme preference should be set (returns null)
      expect(await storageService.getThemePreference(), isNull);

      // Save a theme preference
      await storageService.saveThemePreference('dark');

      // Verify it's correctly retrieved
      expect(await storageService.getThemePreference(), 'dark');

      // Change the preference
      await storageService.saveThemePreference('light');
      expect(await storageService.getThemePreference(), 'light');

      // Test system preference
      await storageService.saveThemePreference('system');
      expect(await storageService.getThemePreference(), 'system');
    });

    test('language preference persistence', () async {
      // Initially, no language preference should be set (returns null)
      expect(await storageService.getLanguageCode(), isNull);

      // Save a language preference
      await storageService.saveLanguageCode('en');

      // Verify it's correctly retrieved
      expect(await storageService.getLanguageCode(), 'en');

      // Change the preference
      await storageService.saveLanguageCode('fr');
      expect(await storageService.getLanguageCode(), 'fr');
    });

    test('notifications preference persistence', () async {
      // Initially, no notifications preference should be set (returns null, defaults to true)
      final initialEnabled = await storageService.getNotificationsEnabled();
      expect(initialEnabled, true); // Default value

      // Save notifications as disabled
      await storageService.saveNotificationsEnabled(false);

      // Verify it's correctly retrieved as disabled
      expect(await storageService.getNotificationsEnabled(), false);

      // Change back to enabled
      await storageService.saveNotificationsEnabled(true);
      expect(await storageService.getNotificationsEnabled(), true);
    });
  });
}
