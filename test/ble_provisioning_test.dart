import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:esp32_rgb_studio/add_device_wizard.dart';
import 'package:esp32_rgb_studio/device_store.dart';
import 'package:esp32_rgb_studio/provisioning_protocol.dart';

class FakeProvisioning implements ProvisioningTransport {
  int calls = 0, cancellations = 0;
  ProvisioningConfig? received;
  Completer<ProvisioningResult>? pending;
  bool fail = false;
  @override Future<List<BleController>> scan() async => [const BleController('ble-id', 'MortysLED-test')];
  @override Future<void> cancel() async { cancellations++; }
  @override Future<ProvisioningResult> provision(BleController device, ProvisioningConfig config) async {
    calls++; received = config;
    if (fail) throw StateError('No se pudo conectar al WiFi.');
    if (pending != null) return await pending!.future;
    return const ProvisioningResult(id: 'abc', host: '192.168.1.30', name: 'Salón', pixels: 60);
  }
}

void main() {
  test('BLE payload preserves WiFi whitespace and UTF-8, validates byte limits', () {
    const config = ProvisioningConfig(ssid: ' Red ñ ', password: ' secreto ', name: ' Salón ', pixels: 1024);
    final value = jsonDecode(utf8.decode(config.encode('request-1')));
    expect(value['ssid'], ' Red ñ '); expect(value['password'], ' secreto ');
    expect(value['name'], 'Salón'); expect(value['pixels'], 1024); expect(value['version'], 1);
    for (final config in [
      const ProvisioningConfig(ssid: '', password: '', name: 'a', pixels: 1),
      ProvisioningConfig(ssid: List.filled(17, 'ñ').join(), password: '', name: 'a', pixels: 1),
      const ProvisioningConfig(ssid: 'a', password: 'short', name: 'a', pixels: 1),
      const ProvisioningConfig(ssid: 'a', password: '', name: ' ', pixels: 1),
      const ProvisioningConfig(ssid: 'a', password: '', name: 'a', pixels: 0),
      const ProvisioningConfig(ssid: 'a', password: '', name: 'a', pixels: 1025),
      const ProvisioningConfig(ssid: 'a\u0000b', password: '', name: 'a', pixels: 1),
    ]) { expect(() => config.encode('request'), throwsFormatException); }
  });

  test('Only a valid confirmed controller can be saved', () {
    final status = <String, dynamic>{'device_id': 'abc', 'ip': '192.168.1.30', 'name': 'Salón', 'pixels': 60};
    expect(ProvisioningResult.fromStatus(status).toDevice().id, 'esp32-abc');
    for (final ip in ['0.0.0.0', '256.1.1.1', '', 'example.com']) {
      expect(() => ProvisioningResult.fromStatus({...status, 'ip': ip}), throwsFormatException);
    }
    expect(() => ProvisioningResult.fromStatus({...status, 'pixels': 0}), throwsFormatException);
  });

  Future<void> open(WidgetTester tester, FakeProvisioning fake, void Function(StudioDevice) onSaved) async {
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) => Scaffold(body: TextButton(
      onPressed: () async { final result = await Navigator.push<StudioDevice>(context, MaterialPageRoute(builder: (_) => AddDeviceWizard(provisioning: fake))); if (result != null) onSaved(result); },
      child: const Text('Abrir'),
    )))));
    await tester.tap(find.text('Abrir')); await tester.pumpAndSettle();
    await tester.tap(find.text('Buscar por Bluetooth')); await tester.pumpAndSettle();
    await tester.tap(find.text('MortysLED-test')); await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Mi WiFi');
    await tester.enterText(fields.at(1), 'password123');
    await tester.enterText(fields.at(2), 'Salón');
    await tester.enterText(fields.at(3), '60');
    await tester.ensureVisible(find.text('Configurar y añadir tira'));
  }

  testWidgets('Bluetooth setup returns the confirmed device without saving the password', (tester) async {
    final fake = FakeProvisioning(); StudioDevice? saved;
    await open(tester, fake, (d) => saved = d);
    await tester.tap(find.text('Configurar y añadir tira')); await tester.pumpAndSettle();
    expect(fake.calls, 1); expect(fake.received!.ssid, 'Mi WiFi'); expect(fake.received!.pixels, 60);
    expect(saved!.host, '192.168.1.30'); expect(saved!.name, 'Salón');
    expect(saved!.toJson().containsKey('password'), isFalse);
  });

  testWidgets('WiFi failure leaves the wizard open and saves no device', (tester) async {
    final fake = FakeProvisioning()..fail = true; StudioDevice? saved;
    await open(tester, fake, (d) => saved = d);
    await tester.tap(find.text('Configurar y añadir tira')); await tester.pumpAndSettle();
    expect(saved, isNull); expect(find.text('No se pudo conectar al WiFi.'), findsOneWidget);
  });

  testWidgets('Cancel ignores late WiFi confirmation', (tester) async {
    final fake = FakeProvisioning()..pending = Completer<ProvisioningResult>(); StudioDevice? saved;
    await open(tester, fake, (d) => saved = d);
    await tester.tap(find.text('Configurar y añadir tira')); await tester.pump();
    await tester.ensureVisible(find.text('Cancelar operación'));
    await tester.tap(find.text('Cancelar operación')); await tester.pumpAndSettle();
    fake.pending!.complete(const ProvisioningResult(id: 'abc', host: '192.168.1.30', name: 'Salón', pixels: 60));
    await tester.pumpAndSettle(); expect(saved, isNull); expect(fake.cancellations, greaterThan(0));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
