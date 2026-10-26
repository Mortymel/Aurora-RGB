import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:esp32_rgb_studio/device_api.dart';
import 'package:esp32_rgb_studio/device_store.dart';
import 'package:esp32_rgb_studio/main.dart';

void main() {
  test('Controller address accepts a hostname beginning with http', () {
    expect(const DeviceApi('httpcontroller.local').base.host, 'httpcontroller.local');
    expect(const DeviceApi('192.168.1.5').base.scheme, 'http');
    for (final host in ['', 'ftp://host', 'http://user:pass@host']) {
      expect(() => DeviceApi(host).base, throwsFormatException);
    }
  });
  testWidgets('A timer keeps its original controller when the selected device changes', (tester) async {
    SharedPreferences.setMockInitialValues({});
    const first = StudioDevice(id: 'one', host: '192.168.1.10', name: 'Uno', pixels: 60);
    const second = StudioDevice(id: 'two', host: '192.168.1.11', name: 'Dos', pixels: 60);
    await DeviceStore.save([first, second]);
    await DeviceStore.select(first.id);
    final posted = <String>[];
    await http.runWithClient(() async {
      await tester.pumpWidget(const StudioApp()); await tester.pumpAndSettle();
      final dynamic shell = tester.state(find.byType(StudioShell));
      shell.startNightlight(1);
      await shell.selectDevice(second); await tester.pumpAndSettle();
      await tester.pump(const Duration(minutes: 1)); await tester.pump();
      expect(posted, ['192.168.1.10']);
      await tester.pumpWidget(const SizedBox.shrink()); await tester.pumpAndSettle();
    }, () => MockClient((request) async {
      if (request.method == 'POST') posted.add(request.url.host);
      return http.Response(jsonEncode({'pixels': 60, 'power': request.method != 'POST'}), 200);
    }));
  });
}
