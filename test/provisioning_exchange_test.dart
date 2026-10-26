import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:esp32_rgb_studio/provisioning_protocol.dart';

void main() {
  const config = ProvisioningConfig(ssid: ' WiFi ñ ', password: ' secret123 ', name: 'Salón', pixels: 60);
  Map<String, dynamic> success(String request) => {'version': 1, 'request_id': request, 'state': 'connected', 'device_id': 'abc', 'ip': '192.168.1.30', 'name': 'Salón', 'pixels': 60};
  test('Real exchange uses reset, <=20-byte chunks, UTF-8 and ignores stale confirmation', () async {
    final writes = <List<int>>[];
    final reads = [{'version': 1, 'state': 'ready'}, success('old-request'), success('new-request')];
    final result = await exchangeProvisioning(config: config, requestId: 'new-request',
      write: (bytes) async => writes.add(bytes), read: () async => utf8.encode(jsonEncode(reads.removeAt(0))),
      checkCancelled: () {}, pause: (_) async {});
    expect(result.host, '192.168.1.30'); expect(writes.first, [33]);
    expect(writes.skip(1).every((bytes) => bytes.length <= 20), isTrue);
    final message = writes.skip(1).expand((bytes) => bytes).toList();
    expect(message.last, 10);
    expect(jsonDecode(utf8.decode(message))['ssid'], ' WiFi ñ ');
    expect(jsonDecode(utf8.decode(message))['password'], ' secret123 ');
  });
  test('WiFi failure and mismatched confirmed counts are rejected', () async {
    for (final response in [
      {'version': 1, 'request_id': 'req', 'state': 'error', 'error': 'wifi_failed'},
      {...success('req'), 'pixels': 99},
    ]) {
      var reads = 0;
      await expectLater(exchangeProvisioning(config: config, requestId: 'req', write: (_) async {},
        read: () async => utf8.encode(jsonEncode(reads++ == 0 ? {'version': 1} : response)),
        checkCancelled: () {}), throwsA(anyOf(isA<StateError>(), isA<FormatException>())));
    }
  });
  test('Cancellation before the first write sends no credentials', () async {
    final writes = <List<int>>[];
    await expectLater(exchangeProvisioning(config: config, requestId: 'req', write: (b) async => writes.add(b),
      read: () async => utf8.encode('{"version":1}'), checkCancelled: () => throw StateError('cancelled')), throwsStateError);
    expect(writes, isEmpty);
  });
  test('Missing confirmation times out without saving a device', () async {
    await expectLater(exchangeProvisioning(config: config, requestId: 'req', write: (_) async {},
      read: () async => utf8.encode('{"version":1}'), checkCancelled: () {}, timeout: Duration.zero), throwsA(isA<TimeoutException>()));
  });
}
