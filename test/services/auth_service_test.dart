import 'package:clueroom/services/auth_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const MethodChannel _secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const accessKey = 'access_token';
  const refreshKey = 'refresh_token';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthService.instance.resetForTesting();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, null);
    AuthService.instance.resetForTesting();
  });

  test('saveTokens clears partial state when refresh persist fails', () async {
    final store = _FakeTokenStore(failOnKey: refreshKey)
      ..values[accessKey] = 'old-access'
      ..values[refreshKey] = 'old-refresh';
    AuthService.instance.setTokenStoreProviderForTesting(() async => store);

    await expectLater(
      AuthService.instance.saveTokens(
        access: 'new-access',
        refresh: 'new-refresh',
      ),
      throwsA(isA<StateError>()),
    );

    expect(store.values[accessKey], isNull);
    expect(store.values[refreshKey], isNull);
    expect(AuthService.instance.bearerToken, isNull);
    expect(AuthService.instance.refreshToken, isNull);
  });

  for (final failedKey in [accessKey, refreshKey]) {
    test(
      'saveTokens clears partial state when $failedKey returns false',
      () async {
        final store = _FakeTokenStore(falseOnKey: failedKey)
          ..values[accessKey] = 'old-access'
          ..values[refreshKey] = 'old-refresh';
        AuthService.instance.setTokenStoreProviderForTesting(() async => store);

        await expectLater(
          AuthService.instance.saveTokens(
            access: 'new-access',
            refresh: 'new-refresh',
          ),
          throwsA(isA<StateError>()),
        );

        expect(store.values[accessKey], isNull);
        expect(store.values[refreshKey], isNull);
        expect(AuthService.instance.bearerToken, isNull);
        expect(AuthService.instance.refreshToken, isNull);
      },
    );
  }

  test('init treats token store creation failure as logged out', () async {
    AuthService.instance.setTokenStoreProviderForTesting(
      () async => throw StateError('secure storage unavailable'),
    );

    await AuthService.instance.init();

    expect(AuthService.instance.bearerToken, isNull);
    expect(AuthService.instance.refreshToken, isNull);
    expect(AuthService.instance.isLoggedIn, isFalse);
  });

  test('init treats token store read failure as logged out', () async {
    final store = _FakeTokenStore(throwOnGet: true)
      ..values[accessKey] = 'old-access'
      ..values[refreshKey] = 'old-refresh';
    AuthService.instance.setTokenStoreProviderForTesting(() async => store);

    await AuthService.instance.init();

    expect(AuthService.instance.bearerToken, isNull);
    expect(AuthService.instance.refreshToken, isNull);
    expect(AuthService.instance.isLoggedIn, isFalse);
  });

  test(
    'init preserves legacy tokens when secure migration write fails',
    () async {
      SharedPreferences.setMockInitialValues({
        accessKey: 'legacy-access',
        refreshKey: 'legacy-refresh',
      });
      final secureValues = _setSecureStorageMock(throwOnWriteKey: refreshKey);

      await AuthService.instance.init();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(accessKey), 'legacy-access');
      expect(prefs.getString(refreshKey), 'legacy-refresh');
      expect(secureValues[accessKey], isNull);
      expect(secureValues[refreshKey], isNull);
      expect(AuthService.instance.bearerToken, isNull);
      expect(AuthService.instance.refreshToken, isNull);
      expect(AuthService.instance.isLoggedIn, isFalse);
    },
  );

  test('logout completes when token store creation fails', () async {
    AuthService.instance.setTokenStoreProviderForTesting(
      () async => throw StateError('secure storage unavailable'),
    );

    await AuthService.instance.logout();

    expect(AuthService.instance.bearerToken, isNull);
    expect(AuthService.instance.refreshToken, isNull);
    expect(AuthService.instance.isLoggedIn, isFalse);
  });

  test('logout completes when token store delete fails', () async {
    final store = _FakeTokenStore(throwOnRemove: true)
      ..values[accessKey] = 'old-access'
      ..values[refreshKey] = 'old-refresh';
    AuthService.instance.setTokenStoreProviderForTesting(() async => store);

    await AuthService.instance.logout();

    expect(AuthService.instance.bearerToken, isNull);
    expect(AuthService.instance.refreshToken, isNull);
    expect(AuthService.instance.isLoggedIn, isFalse);
  });
}

Map<String, String> _setSecureStorageMock({String? throwOnWriteKey}) {
  final values = <String, String>{};

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_secureStorageChannel, (call) async {
        final args =
            (call.arguments as Map<Object?, Object?>?) ?? <Object?, Object?>{};
        final key = args['key'] as String?;

        switch (call.method) {
          case 'containsKey':
            return values.containsKey(key);
          case 'delete':
            values.remove(key);
            return null;
          case 'deleteAll':
            values.clear();
            return null;
          case 'read':
            return values[key];
          case 'readAll':
            return Map<String, String>.from(values);
          case 'write':
            if (key == throwOnWriteKey) {
              throw PlatformException(code: 'secure-storage-write-failed');
            }
            values[key!] = args['value'] as String;
            return null;
          default:
            throw PlatformException(code: 'unimplemented');
        }
      });

  return values;
}

class _FakeTokenStore implements AuthTokenStore {
  _FakeTokenStore({
    this.failOnKey,
    this.falseOnKey,
    this.throwOnGet = false,
    this.throwOnRemove = false,
  });

  final String? failOnKey;
  final String? falseOnKey;
  final bool throwOnGet;
  final bool throwOnRemove;
  final Map<String, String> values = {};

  @override
  String? getString(String key) {
    if (throwOnGet) {
      throw StateError('get failed for $key');
    }
    return values[key];
  }

  @override
  Future<bool> setString(String key, String value) async {
    if (key == failOnKey) {
      throw StateError('set failed for $key');
    }
    if (key == falseOnKey) {
      return false;
    }
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    if (throwOnRemove) {
      throw StateError('remove failed for $key');
    }
    values.remove(key);
    return true;
  }
}
