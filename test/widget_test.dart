import 'package:flutter_test/flutter_test.dart';

import 'package:cloud_quest/main.dart';

void main() {
  test('debug builds default to the Android emulator host alias', () {
    expect(emulatorHost, '10.0.2.2');
  });
}
