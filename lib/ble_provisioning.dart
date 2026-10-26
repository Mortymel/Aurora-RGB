import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'provisioning_protocol.dart';

class BleProvisioning implements ProvisioningTransport {
  BluetoothDevice? _connected;
  int _generation = 0;
  void _check(int generation) {
    if (generation != _generation) throw StateError('Configuración cancelada.');
  }
  @override
  Future<List<BleController>> scan() async {
    await cancel();
    final generation = _generation;
    if (!await FlutterBluePlus.isSupported) throw StateError('Bluetooth LE no disponible.');
    if (Platform.isAndroid) {
      final permissions = await [Permission.bluetoothScan, Permission.bluetoothConnect, Permission.locationWhenInUse].request();
      if (!(permissions[Permission.bluetoothScan]?.isGranted ?? false) || !(permissions[Permission.bluetoothConnect]?.isGranted ?? false)) {
        throw StateError('Permite el acceso a Bluetooth en los ajustes de la aplicación.');
      }
    }
    _check(generation);
    final adapter = await FlutterBluePlus.adapterState.where((s) => s != BluetoothAdapterState.unknown).first.timeout(const Duration(seconds: 5));
    if (adapter != BluetoothAdapterState.on) throw StateError('Activa el Bluetooth. En Android 11 o anterior, activa también la ubicación.');
    final devices = <String, BleController>{};
    final subscription = FlutterBluePlus.onScanResults.listen((results) {
      for (final result in results) {
        if (result.advertisementData.serviceUuids.contains(Guid(provisioningServiceUuid))) {
          final id = result.device.remoteId.str;
          devices[id] = BleController(id, result.advertisementData.advName.isEmpty ? 'MortysLED' : result.advertisementData.advName);
        }
      }
    });
    try {
      await FlutterBluePlus.startScan(withServices: [Guid(provisioningServiceUuid)], timeout: const Duration(seconds: 8));
      _check(generation);
      await FlutterBluePlus.isScanning.where((scanning) => !scanning).first.timeout(const Duration(seconds: 12));
      _check(generation);
      return devices.values.toList();
    } finally {
      await subscription.cancel();
      await FlutterBluePlus.stopScan();
    }
  }
  @override
  Future<ProvisioningResult> provision(BleController controller, ProvisioningConfig config) async {
    final generation = ++_generation;
    final requestId = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final payload = config.encode(requestId);
    final device = BluetoothDevice.fromId(controller.id);
    _connected = device;
    try {
      await device.connect(timeout: const Duration(seconds: 20), mtu: null);
      _check(generation);
      if (Platform.isAndroid) await device.createBond(timeout: 30);
      _check(generation);
      final services = await device.discoverServices();
      final service = services.where((s) => s.uuid == Guid(provisioningServiceUuid)).firstOrNull;
      final write = service?.characteristics.where((c) => c.uuid == Guid(provisioningConfigUuid)).firstOrNull;
      final status = service?.characteristics.where((c) => c.uuid == Guid(provisioningStatusUuid)).firstOrNull;
      if (write == null || status == null) throw StateError('Firmware incompatible. Flashea el firmware 0.8.0.');
      final initial = jsonDecode(utf8.decode(await status.read())) as Map<String, dynamic>;
      if (initial['version'] != 1) throw StateError('Versión Bluetooth incompatible.');
      _check(generation);
      // JSON line framing works at the minimum BLE MTU, even for split UTF-8.
      await write.write([10]);
      final framed = [...payload, 10];
      for (var offset = 0; offset < framed.length; offset += 20) {
        _check(generation);
        await write.write(framed.sublist(offset, offset + 20 < framed.length ? offset + 20 : framed.length));
      }
      final deadline = DateTime.now().add(const Duration(seconds: 40));
      while (DateTime.now().isBefore(deadline)) {
        _check(generation);
        final result = jsonDecode(utf8.decode(await status.read())) as Map<String, dynamic>;
        _check(generation);
        if (result['request_id'] == requestId) {
          if (result['state'] == 'connected') return ProvisioningResult.fromStatus(result);
          if (result['state'] == 'error') throw StateError(result['error'] == 'wifi_failed'
            ? 'No se pudo conectar al WiFi. Revisa la contraseña y utiliza una red de 2,4 GHz.'
            : 'La ESP32 rechazó la configuración (${result['error']}).');
        }
        await Future<void>.delayed(const Duration(milliseconds: 600));
      }
      throw TimeoutException('Sin confirmación. Si la ESP32 ya guardó los datos, utiliza «Ya está conectada al WiFi».');
    } finally {
      try { await device.disconnect(); } catch (_) { /* Already disconnected. */ }
      if (identical(_connected, device)) _connected = null;
    }
  }
  @override
  Future<void> cancel() async {
    _generation++;
    await FlutterBluePlus.stopScan();
    final device = _connected;
    _connected = null;
    if (device != null) {
      try { await device.disconnect(); } catch (_) { /* Already disconnected. */ }
    }
  }
}
