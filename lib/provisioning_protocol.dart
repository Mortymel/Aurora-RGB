import 'dart:convert';
import 'device_store.dart';

const provisioningServiceUuid = 'd973f2e0-b19e-11ee-a506-0242ac120002';
const provisioningConfigUuid = 'd973f2e1-b19e-11ee-a506-0242ac120002';
const provisioningStatusUuid = 'd973f2e2-b19e-11ee-a506-0242ac120002';

class ProvisioningConfig {
  final String ssid, password, name;
  final int pixels;
  const ProvisioningConfig({required this.ssid, required this.password, required this.name, required this.pixels});
  List<int> encode(String requestId) {
    if (ssid.isEmpty || utf8.encode(ssid).length > 32 || ssid.contains('\u0000')) {
      throw const FormatException('La red WiFi debe tener entre 1 y 32 bytes.');
    }
    final passwordBytes = utf8.encode(password).length;
    if ((passwordBytes != 0 && passwordBytes < 8) || passwordBytes > 63 || password.contains('\u0000')) {
      throw const FormatException('La contraseña debe tener entre 8 y 63 bytes, o estar vacía para una red abierta.');
    }
    if (name.trim().isEmpty || utf8.encode(name.trim()).length > 48 || name.contains('\u0000')) {
      throw const FormatException('El nombre debe tener entre 1 y 48 bytes.');
    }
    if (pixels < 1 || pixels > StudioDevice.maxPixels) throw const FormatException('Introduce entre 1 y 1024 píxeles.');
    if (!RegExp(r'^[a-zA-Z0-9-]{1,32}$').hasMatch(requestId)) throw const FormatException('Solicitud inválida.');
    final bytes = utf8.encode(jsonEncode({'version': 1, 'request_id': requestId,
      'ssid': ssid, 'password': password, 'name': name.trim(), 'pixels': pixels}));
    if (bytes.length > 512) throw const FormatException('Los datos de configuración son demasiado largos.');
    return bytes;
  }
}

class ProvisioningResult {
  final String id, host, name;
  final int pixels;
  const ProvisioningResult({required this.id, required this.host, required this.name, required this.pixels});
  factory ProvisioningResult.fromStatus(Map<String, dynamic> status) {
    final id = status['device_id'], host = status['ip'], name = status['name'], pixels = status['pixels'];
    if (id is! String || id.isEmpty || host is! String ||
        !RegExp(r'^(\d{1,3}\.){3}\d{1,3}$').hasMatch(host) ||
        host.split('.').any((p) => int.parse(p) > 255) || host == '0.0.0.0' ||
        name is! String || name.isEmpty || pixels is! int || pixels < 1 || pixels > StudioDevice.maxPixels) {
      throw const FormatException('La ESP32 devolvió una configuración inválida.');
    }
    return ProvisioningResult(id: id, host: host, name: name, pixels: pixels);
  }
  StudioDevice toDevice() => StudioDevice(id: 'esp32-$id', name: name, host: host, pixels: pixels);
}

class BleController {
  final String id, name;
  const BleController(this.id, this.name);
}

abstract class ProvisioningTransport {
  Future<List<BleController>> scan();
  Future<ProvisioningResult> provision(BleController device, ProvisioningConfig config);
  Future<void> cancel();
}
