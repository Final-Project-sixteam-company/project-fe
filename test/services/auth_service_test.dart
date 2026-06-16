import 'dart:convert';

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

  test('init treats secure storage reset sentinel as logged out', () async {
    final secureValues = _setSecureStorageMock(
      initialValues: {
        accessKey: _validJwt(),
        refreshKey: 'Data has been reset',
      },
    );

    await AuthService.instance.init();

    expect(secureValues[accessKey], isNull);
    expect(secureValues[refreshKey], isNull);
    expect(AuthService.instance.bearerToken, isNull);
    expect(AuthService.instance.refreshToken, isNull);
    expect(AuthService.instance.isLoggedIn, isFalse);
  });

  test(
    'init preserves legacy tokens when secure migration write fails',
    () async {
      final access = _validJwt();
      SharedPreferences.setMockInitialValues({
        accessKey: access,
        refreshKey: 'legacy-refresh',
      });
      final secureValues = _setSecureStorageMock(throwOnWriteKey: refreshKey);

      await AuthService.instance.init();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(accessKey), access);
      expect(prefs.getString(refreshKey), 'legacy-refresh');
      expect(secureValues[accessKey], isNull);
      expect(secureValues[refreshKey], isNull);
      expect(AuthService.instance.bearerToken, isNull);
      expect(AuthService.instance.refreshToken, isNull);
      expect(AuthService.instance.isLoggedIn, isFalse);
    },
  );

  test(
    'init preserves legacy tokens when secure migration access write fails',
    () async {
      final access = _validJwt();
      SharedPreferences.setMockInitialValues({
        accessKey: access,
        refreshKey: 'legacy-refresh',
      });
      final secureValues = _setSecureStorageMock(throwOnWriteKey: accessKey);

      await AuthService.instance.init();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(accessKey), access);
      expect(prefs.getString(refreshKey), 'legacy-refresh');
      expect(secureValues[accessKey], isNull);
      expect(secureValues[refreshKey], isNull);
      expect(AuthService.instance.bearerToken, isNull);
      expect(AuthService.instance.refreshToken, isNull);
      expect(AuthService.instance.isLoggedIn, isFalse);
    },
  );

  test('init clears legacy access-only instead of migrating it', () async {
    final access = _validJwt();
    SharedPreferences.setMockInitialValues({accessKey: access});
    final secureValues = _setSecureStorageMock();

    await AuthService.instance.init();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(accessKey), isNull);
    expect(prefs.getString(refreshKey), isNull);
    expect(secureValues[accessKey], isNull);
    expect(secureValues[refreshKey], isNull);
    expect(AuthService.instance.bearerToken, isNull);
    expect(AuthService.instance.refreshToken, isNull);
    expect(AuthService.instance.isLoggedIn, isFalse);
  });

  test('init migrates complete legacy token pair', () async {
    final access = _validJwt();
    SharedPreferences.setMockInitialValues({
      accessKey: access,
      refreshKey: 'legacy-refresh',
    });
    final secureValues = _setSecureStorageMock();

    await AuthService.instance.init();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(accessKey), isNull);
    expect(prefs.getString(refreshKey), isNull);
    expect(secureValues[accessKey], access);
    expect(secureValues[refreshKey], 'legacy-refresh');
    expect(AuthService.instance.bearerToken, access);
    expect(AuthService.instance.refreshToken, 'legacy-refresh');
    expect(AuthService.instance.isLoggedIn, isTrue);
  });

  test(
    'init repairs secure access-only state from matching legacy pair',
    () async {
      final access = _validJwt();
      SharedPreferences.setMockInitialValues({
        accessKey: access,
        refreshKey: 'legacy-refresh',
      });
      final secureValues = _setSecureStorageMock(
        initialValues: {accessKey: access},
      );

      await AuthService.instance.init();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(accessKey), isNull);
      expect(prefs.getString(refreshKey), isNull);
      expect(secureValues[accessKey], access);
      expect(secureValues[refreshKey], 'legacy-refresh');
      expect(AuthService.instance.bearerToken, access);
      expect(AuthService.instance.refreshToken, 'legacy-refresh');
      expect(AuthService.instance.isLoggedIn, isTrue);
    },
  );

  test('init migrates legacy refresh-only and refreshes session', () async {
    final refreshedAccess = _validJwt();
    SharedPreferences.setMockInitialValues({refreshKey: 'legacy-refresh'});
    final secureValues = _setSecureStorageMock();
    var refreshCalls = 0;
    AuthService.instance.setRefreshResponseProviderForTesting((
      refreshToken,
    ) async {
      refreshCalls += 1;
      expect(refreshToken, 'legacy-refresh');
      return {
        'accessToken': refreshedAccess,
        'refreshToken': 'rotated-refresh',
      };
    });

    await AuthService.instance.init();

    final prefs = await SharedPreferences.getInstance();
    expect(refreshCalls, 1);
    expect(prefs.getString(accessKey), isNull);
    expect(prefs.getString(refreshKey), isNull);
    expect(secureValues[accessKey], refreshedAccess);
    expect(secureValues[refreshKey], 'rotated-refresh');
    expect(AuthService.instance.bearerToken, refreshedAccess);
    expect(AuthService.instance.refreshToken, 'rotated-refresh');
    expect(AuthService.instance.isLoggedIn, isTrue);
  });

  test('init keeps secure tokens and clears stale legacy prefs', () async {
    final secureAccess = _validJwt();
    SharedPreferences.setMockInitialValues({
      accessKey: _validJwt(),
      refreshKey: 'legacy-refresh',
    });
    final secureValues = _setSecureStorageMock(
      initialValues: {accessKey: secureAccess, refreshKey: 'secure-refresh'},
    );

    await AuthService.instance.init();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(accessKey), isNull);
    expect(prefs.getString(refreshKey), isNull);
    expect(secureValues[accessKey], secureAccess);
    expect(secureValues[refreshKey], 'secure-refresh');
    expect(AuthService.instance.bearerToken, secureAccess);
    expect(AuthService.instance.refreshToken, 'secure-refresh');
    expect(AuthService.instance.isLoggedIn, isTrue);
  });

  test('init clears secure access-only state', () async {
    final access = _validJwt();
    final secureValues = _setSecureStorageMock(
      initialValues: {accessKey: access},
    );

    await AuthService.instance.init();

    expect(secureValues[accessKey], isNull);
    expect(secureValues[refreshKey], isNull);
    expect(AuthService.instance.bearerToken, isNull);
    expect(AuthService.instance.refreshToken, isNull);
    expect(AuthService.instance.isLoggedIn, isFalse);
  });

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

Map<String, String> _setSecureStorageMock({
  Map<String, String>? initialValues,
  String? throwOnWriteKey,
}) {
  final values = <String, String>{...?initialValues};

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

String _validJwt() {
  final expiresAt = DateTime.now().add(const Duration(hours: 1));
  final payload = {'exp': expiresAt.millisecondsSinceEpoch ~/ 1000};
  return '${_base64UrlJson({'alg': 'none', 'typ': 'JWT'})}.'
      '${_base64UrlJson(payload)}.signature';
}

String _base64UrlJson(Map<String, Object> json) =>
    base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');

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
