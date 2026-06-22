import 'package:clueroom/core/device/device_id_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('DeviceIdProvider creates and reuses a per-install id', () async {
    SharedPreferences.setMockInitialValues({});

    final first = await DeviceIdProvider.getOrCreate();
    final second = await DeviceIdProvider.getOrCreate();

    expect(first, second);
    expect(first, isNot('android-debug'));
    expect(first.length, lessThanOrEqualTo(100));
  });
}
