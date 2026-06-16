import 'package:clueroom/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const accessKey = 'access_token';
  const refreshKey = 'refresh_token';

  setUp(() {
    AuthService.instance.resetForTesting();
  });

  tearDown(() {
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
}

class _FakeTokenStore implements AuthTokenStore {
  _FakeTokenStore({this.failOnKey, this.falseOnKey, this.throwOnGet = false});

  final String? failOnKey;
  final String? falseOnKey;
  final bool throwOnGet;
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
    values.remove(key);
    return true;
  }
}
