import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:aurora_led/device_api.dart';
import 'package:aurora_led/models.dart';

void main() {
  test('Direcciones admitidas y entradas peligrosas', () {
    expect(controllerUri('192.168.4.1').toString(), 'http://192.168.4.1');
    expect(controllerUri('http://ledweb-test.local:8080').port, 8080);
    for (final value in [
      'javascript:alert(1)',
      'http://u:p@led.local',
      '192.168.999.1',
      'led.local/path',
      'led.local?q=1',
      '',
    ]) {
      expect(() => controllerUri(value), throwsFormatException);
    }
  });
  test('Formato incompatible no se acepta como ESP32 LEDWeb', () {
    expect(
      () => Light.fromJson({'power': true, 'effect': 1}),
      throwsFormatException,
    );
  });
  test('HTTP Basic y orden JSON reales sobre servidor local', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final device = Device(
      id: 'one',
      name: 'Luz',
      address: 'http://127.0.0.1:${server.port}',
      user: 'admin',
      password: 'contraseña',
    );
    server.listen((request) async {
      expect(request.uri.path, '/api/light');
      expect(request.method, 'POST');
      expect(
        request.headers.value('authorization'),
        'Basic ${base64Encode(utf8.encode('admin:contraseña'))}',
      );
      expect(jsonDecode(await utf8.decoder.bind(request).join()), {
        'state': 'OFF',
      });
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"ok":true}');
      await request.response.close();
    });
    try {
      expect(await LanApi().request(device, 'light', {'state': 'OFF'}), {
        'ok': true,
      });
    } finally {
      await server.close(force: true);
    }
  });
  test('No seguir redirecciones con credenciales; 401 claro', () async {
    for (final status in [302, 401]) {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var requests = 0;
      server.listen((req) {
        requests++;
        req.response.statusCode = status;
        req.response.headers.set('location', 'http://other.local/');
        req.response.close();
      });
      try {
        await expectLater(
          LanApi().request(
            Device(
              id: 'x',
              name: 'x',
              address: 'http://127.0.0.1:${server.port}',
            ),
            'state',
          ),
          throwsA(isA<ApiException>()),
        );
        expect(requests, 1);
      } finally {
        await server.close(force: true);
      }
    }
  });
  test(
    'ESP32 recibe JSON con longitud UTF-8 explícita en todas las escrituras',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final device = Device(
        id: 'esp32',
        name: 'Tira',
        address: 'http://127.0.0.1:${server.port}',
      );
      final cases = <String, Json>{
        'light': {'state': 'ON', 'brightness': 127, 'effect': 'Color fijo'},
        'config': {'ssid': 'Salón', 'mqtt_user': 'iluminación'},
        'timer': {'minutes': 1, 'on': false},
        'clock': {'epoch': 1793404800},
      };
      final received = <String>[];
      server.listen((request) async {
        final bytes = await request.fold<List<int>>(
          [],
          (all, part) => all..addAll(part),
        );
        final length = request.contentLength;
        request.response.headers.contentType = ContentType.json;
        // Arduino WebServer reads its plain body using Content-Length. A modern
        // Dart HttpServer accepting chunked input would conceal this regression.
        if (length < 0 || request.headers.chunkedTransferEncoding) {
          request.response.statusCode = 400;
          request.response.write('{"error":"JSON invalido"}');
        } else {
          expect(length, bytes.length);
          final route = request.uri.path.split('/').last;
          expect(bytes, utf8.encode(jsonEncode(cases[route])));
          expect(jsonDecode(utf8.decode(bytes)), cases[route]);
          received.add(route);
          request.response.write('{"ok":true}');
        }
        await request.response.close();
      });
      try {
        for (final entry in cases.entries) {
          expect(await LanApi().request(device, entry.key, entry.value), {
            'ok': true,
          });
        }
        expect(received, cases.keys.toList());
      } finally {
        await server.close(force: true);
      }
    },
  );
  test('Timeout cancela la conexión sin repetir la orden', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    var count = 0;
    server.listen((req) {
      count++;
    });
    try {
      await expectLater(
        LanApi(timeout: const Duration(milliseconds: 60)).request(
          Device(
            id: 'x',
            name: 'x',
            address: 'http://127.0.0.1:${server.port}',
          ),
          'light',
          {'state': 'ON'},
        ),
        throwsA(isA<ApiException>()),
      );
      expect(count, 1);
    } finally {
      await server.close(force: true);
    }
  });
}
