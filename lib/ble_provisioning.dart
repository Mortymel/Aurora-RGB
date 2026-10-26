import 'dart:async';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
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
      final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      final needed = sdk >= 31 ? [Permission.bluetoothScan, Permission.bluetoothConnect] : [Permission.locationWhenInUse];
      final permissions = await needed.request();
      if (permissions.values.any((permission) => !permission.isGranted)) {
        throw StateError('Permite el acceso a Bluetooth o ubicación en los ajustes de la aplicación.');
      }
      if (sdk < 31 && !await Permission.locationWhenInUse.serviceStatus.isEnabled) {
        throw StateError('Activa la ubicación del teléfono para buscar Bluetooth en Android 11 o anterior.');
      }
    }
    _check(generation);
    final adapter = await FlutterBluePlus.adapterState.where((s) => s != BluetoothAdapterState.unknown).first.timeout(const Duration(seconds: 5));
    if (adapter != BluetoothAdapterState.on) throw StateError('Activa el Bluetooth. En Android 11 o anterior, activa también la ubicación.');
    _check(generation);
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
    config.encode(requestId);
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
      return await exchangeProvisioning(config: config, requestId: requestId,
        write: (bytes) => write.write(bytes), read: () => status.read(),
        checkCancelled: () => _check(generation));
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
