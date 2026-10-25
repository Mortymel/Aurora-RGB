import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// BLE discovery only. Secure WiFi provisioning requires an updated ESP32 firmware.
class BleProvisioning {
  static Future<List<ScanResult>> scan() async {
    if (!await FlutterBluePlus.isSupported) throw StateError('Bluetooth LE no disponible');
    final permissions = await [Permission.bluetoothScan, Permission.bluetoothConnect].request();
    if (permissions.values.any((p) => !p.isGranted)) {
      throw StateError('Permisos Bluetooth denegados');
    }
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 7));
    await Future<void>.delayed(const Duration(seconds: 8));
    final results = await FlutterBluePlus.scanResults.first;
    await FlutterBluePlus.stopScan();
    return results.where((r) => r.device.platformName.startsWith('RGBStudio')).toList();
  }
  static Future<void> provision({required BluetoothDevice device, required String ssid, required String password}) async {
    throw UnsupportedError('Secure BLE WiFi provisioning is not implemented in firmware v0.1');
  }
}
