import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'models.dart';

abstract class DeviceApi {
  Future<Json> request(Device device, String route, [Json? body]);
}

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class LanApi implements DeviceApi {
  LanApi({this.timeout = const Duration(seconds: 8)});
  final Duration timeout;
  @override
  Future<Json> request(Device device, String route, [Json? body]) async {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      return await (() async {
        final uri = controllerUri(device.address).replace(path: '/api/$route');
        final request = await client.openUrl(
          body == null ? 'GET' : 'POST',
          uri,
        );
        request.followRedirects =
            false; // Never forward credentials to another host.
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Basic ${base64Encode(utf8.encode('${device.user}:${device.password}'))}',
        );
        request.headers.contentType = ContentType.json;
        if (body != null) request.write(jsonEncode(body));
        final response = await request.close();
        if (response.statusCode == 401) {
          throw const ApiException(
            'Usuario o contraseña incorrectos. Edita el controlador.',
          );
        }
        if (response.statusCode >= 300 && response.statusCode < 400) {
          throw const ApiException(
            'La dirección redirige a otro sitio. Usa la IP directa de la ESP32.',
          );
        }
        final bytes = <int>[];
        await for (final chunk in response) {
          bytes.addAll(chunk);
          if (bytes.length > 65536) {
            throw const ApiException(
              'Respuesta demasiado grande; comprueba la dirección.',
            );
          }
        }
        dynamic decoded;
        try {
          decoded = jsonDecode(utf8.decode(bytes));
        } catch (_) {
          throw const ApiException(
            'No es una respuesta LEDWeb válida. Revisa la IP y el firmware.',
          );
        }
        if (decoded is! Map<String, dynamic>) {
          throw const ApiException('Respuesta inválida del controlador.');
        }
        if (response.statusCode != 200) {
          throw ApiException(
            decoded['error'] is String
                ? decoded['error'] as String
                : 'El controlador rechazó la acción (${response.statusCode}).',
          );
        }
        return decoded;
      })().timeout(timeout);
    } on TimeoutException {
      throw const ApiException(
        'La ESP32 no responde. Comprueba su alimentación y tu Wi-Fi.',
      );
    } on SocketException {
      throw const ApiException(
        'No se pudo conectar. Usa la misma red Wi-Fi que la ESP32.',
      );
    } on HttpException {
      throw const ApiException(
        'La conexión se interrumpió. Comprueba el estado antes de repetir la acción.',
      );
    } finally {
      client.close(force: true);
    }
  }
}

class DemoApi implements DeviceApi {
  Json config = {
    'chip': 'ESP32-C6 (demo)',
    'count': 320,
    'gpio': 4,
    'max_count': 1600,
    'available_pins': [2, 4, 5, 6, 7, 10, 11, 18, 19, 20, 21, 22, 23],
    'grb': true,
    'ssid': 'Mi Wi-Fi',
    'mqtt_host': '',
    'mqtt_port': 1883,
    'mqtt_user': '',
    'utc_offset': -240,
    'wifi_password_set': false,
    'mqtt_password_set': false,
    'schedules': List.generate(
      4,
      (_) => {'enabled': false, 'on': true, 'time': '20:00', 'days': 127},
    ),
  };
  Json state = {
    'state': 'ON',
    'brightness': 100,
    'speed': 45,
    'color': {'r': 185, 'g': 135, 'b': 211},
    'effect': 'Atardecer',
    'effects': effectNames,
    'count': 320,
    'wifi': true,
    'mqtt': false,
    'clock_valid': true,
  };
  DateTime? deadline;
  bool timerOn = false;
  int? lastMinute;
  @override
  Future<Json> request(Device device, String route, [Json? body]) async {
    if (body != null) {
      switch (route) {
        case 'light':
          state.addAll(body);
        case 'config':
          config.addAll(body);
          for (final type in ['wifi', 'mqtt']) {
            if (body['clear_${type}_password'] == true) {
              config['${type}_password_set'] = false;
            }
            if ((body['${type}_password'] as String? ?? '').isNotEmpty) {
              config['${type}_password_set'] = true;
            }
          }
          config.remove('wifi_password');
          config.remove('mqtt_password');
          state['count'] = config['count'];
          state['wifi'] = (config['ssid'] as String).isNotEmpty;
          state['mqtt'] = (config['mqtt_host'] as String).isNotEmpty;
        case 'timer':
          final minutes = body['minutes'] as int;
          deadline = minutes == 0
              ? null
              : DateTime.now().add(Duration(minutes: minutes));
          timerOn = body['on'] == true;
        case 'clock':
          break;
      }
      return {'ok': true};
    }
    if (route == 'config') return cloneJson(config);
    final now = DateTime.now();
    if (deadline != null && !now.isBefore(deadline!)) {
      state['state'] = timerOn ? 'ON' : 'OFF';
      deadline = null;
    }
    final local = now.toUtc().add(
      Duration(minutes: config['utc_offset'] as int),
    );
    final minute = local.millisecondsSinceEpoch ~/ 60000;
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    if (lastMinute != minute) {
      lastMinute = minute;
      for (final rule in config['schedules'] as List) {
        if (rule['enabled'] == true &&
            rule['time'] == time &&
            ((rule['days'] as int) & (1 << (local.weekday - 1))) != 0) {
          state['state'] = rule['on'] == true ? 'ON' : 'OFF';
        }
      }
    }
    return cloneJson({
      ...state,
      'clock': '${local.toIso8601String().substring(0, 10)} $time',
      'timer_remaining': deadline == null
          ? 0
          : deadline!.difference(now).inSeconds.clamp(0, 604800),
    });
  }
}
